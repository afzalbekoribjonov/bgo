$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'
$rest = 'http://localhost:4003/api/v1'
$ord  = 'http://localhost:4004/api/v1'

function Wait-Up($b, $n) {
  for ($i = 0; $i -lt 90; $i++) {
    try { Invoke-RestMethod "$b/health" -TimeoutSec 2 | Out-Null; Write-Host "[up] $n"; return }
    catch { Start-Sleep -Milliseconds 1000 }
  }
  throw "ko'tarilmadi: $n"
}
function J($o) { $o | ConvertTo-Json -Depth 8 }
function Login($p) {
  $r = Invoke-RestMethod "$auth/auth/otp/request" -Method Post -Body (J @{ phone = $p }) -ContentType 'application/json'
  $v = Invoke-RestMethod "$auth/auth/otp/verify" -Method Post -Body (J @{ phone = $p; code = $r.data.devCode }) -ContentType 'application/json'
  return $v.data
}
function Hdr($t) { return @{ Authorization = "Bearer $t" } }
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

Wait-Up $auth 'auth'; Wait-Up $rest 'restaurant'; Wait-Up $ord 'order'

$admin = Login '+998900000000'
$ah = Hdr $admin.accessToken
Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers $ah `
  -Body (J @{ deliveryFee = 5000; foodCommissionPercent = 12; courierSharePercent = 80 }) -ContentType 'application/json' | Out-Null

# Rollar: haydovchi + oshxona
$drv0 = Login '+998902222222'
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$rst0 = Login '+998903333333'
Invoke-RestMethod "$auth/auth/admin/users/$($rst0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('restaurant') }) -ContentType 'application/json' | Out-Null
$drv = Login '+998902222222'; $rst = Login '+998903333333'
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

function New-Order($qty) {
  $body = @{ type = 'FOOD'; restaurantId = 'r1'; items = @(@{ menuItemId = 'm1'; qty = $qty });
    address = @{ text = "Beshariq test $qty" }; paymentType = 'CASH' }
  return (Invoke-RestMethod "$ord/orders" -Method Post -Headers $ch -Body (J $body) -ContentType 'application/json').data
}

# Boshlang'ich hisobot (bugun) — delta uchun
$before = (Invoke-RestMethod "$ord/admin/reports?period=today" -Headers $ah).data

# 1) Yetkaziladigan buyurtma (qty=1 -> total 35000)
$o1 = New-Order 1
Invoke-RestMethod "$ord/kitchen/orders/$($o1.id)/accept"    -Method Post -Headers (Hdr $rst.accessToken) | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$($o1.id)/preparing" -Method Post -Headers (Hdr $rst.accessToken) | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$($o1.id)/ready"     -Method Post -Headers (Hdr $rst.accessToken) | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o1.id)/accept"    -Method Post -Headers (Hdr $drv.accessToken) | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o1.id)/pickup"    -Method Post -Headers (Hdr $drv.accessToken) | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o1.id)/delivered" -Method Post -Headers (Hdr $drv.accessToken) | Out-Null

# 2) Bekor qilinadigan buyurtma (PENDING -> cancel)
$o2 = New-Order 2
Invoke-RestMethod "$ord/orders/$($o2.id)/cancel" -Method Post -Headers $ch | Out-Null

# 3) Ochiq (PENDING) buyurtma
$o3 = New-Order 3

# ----- Hisobot (bugun) -----
$rep = (Invoke-RestMethod "$ord/admin/reports?period=today" -Headers $ah).data
Check ($rep.period -eq 'today') "reports period=today"
Check ($rep.daily.Count -eq 1) "today: 1 kunlik chelak"
Check (($rep.summary.delivered - $before.summary.delivered) -eq 1) "delivered delta=1"
Check (($rep.summary.cancelled - $before.summary.cancelled) -eq 1) "cancelled delta=1"
Check (($rep.summary.revenue - $before.summary.revenue) -eq 35000) "revenue delta=35000"
Check (($rep.summary.profit - $before.summary.profit) -eq 4600) "profit delta=4600"
Check ($rep.summary.avgOrder -ge 35000) "avgOrder >= 35000 (joriy: $($rep.summary.avgOrder))"

# ----- Hisobot (hafta) -----
$wk = (Invoke-RestMethod "$ord/admin/reports?period=week" -Headers $ah).data
Check ($wk.daily.Count -eq 7) "week: 7 kunlik chelak"
$today = (Get-Date).ToString('yyyy-MM-dd')
$lastBucket = $wk.daily[$wk.daily.Count - 1]
Check ($lastBucket.date -eq $today) "week: oxirgi chelak = bugun ($today)"
Check ($lastBucket.orders -ge 3) "week: bugungi chelakda >= 3 buyurtma"

# ----- Hisobot (oy) -----
$mo = (Invoke-RestMethod "$ord/admin/reports?period=month" -Headers $ah).data
Check ($mo.daily.Count -eq 30) "month: 30 kunlik chelak"

# ----- Buyurtmalar: qidiruv (q = publicNo) -----
$found = (Invoke-RestMethod "$ord/admin/orders?q=$($o3.publicNo)" -Headers $ah).data
Check (($found | Where-Object { $_.id -eq $o3.id }) -ne $null) "qidiruv: q=publicNo topdi"
Check ($found.Count -ge 1) "qidiruv natija qaytdi"

# ----- Buyurtmalar: saralash total asc -----
$sorted = (Invoke-RestMethod "$ord/admin/orders?sort=total&order=asc" -Headers $ah).data
$asc = $true
for ($i = 1; $i -lt $sorted.Count; $i++) { if ($sorted[$i].total -lt $sorted[$i-1].total) { $asc = $false; break } }
Check $asc "saralash: total bo'yicha o'sish tartibida"

# ----- Buyurtmalar: sana oralig'i (bugun) -----
$todayList = (Invoke-RestMethod "$ord/admin/orders?from=$today&to=$today" -Headers $ah).data
Check (($todayList | Where-Object { $_.id -eq $o1.id }) -ne $null) "sana filtri: bugungi buyurtma bor"

# ----- Buyurtmalar: kelajak sana -> bo'sh -----
$future = (Get-Date).AddDays(2).ToString('yyyy-MM-dd')
$futureList = (Invoke-RestMethod "$ord/admin/orders?from=$future" -Headers $ah).data
Check ($futureList.Count -eq 0) "sana filtri: kelajak sanada buyurtma yo'q"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
