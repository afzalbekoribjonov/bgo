$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'
$rest = 'http://localhost:4003/api/v1'
$ord  = 'http://localhost:4004/api/v1'

function Wait-Up($base, $name) {
  for ($i = 0; $i -lt 90; $i++) {
    try { Invoke-RestMethod "$base/health" -TimeoutSec 2 | Out-Null; Write-Host "[up] $name"; return }
    catch { Start-Sleep -Milliseconds 1000 }
  }
  throw "Servis ko'tarilmadi: $name ($base)"
}

function J($obj) { $obj | ConvertTo-Json -Depth 8 }

function Login($phone) {
  $r = Invoke-RestMethod "$auth/auth/otp/request" -Method Post -Body (J @{ phone = $phone }) -ContentType 'application/json'
  $code = $r.data.devCode
  if (-not $code) { throw "devCode yo'q ($phone) — SMS dev rejimi emasmi?" }
  $v = Invoke-RestMethod "$auth/auth/otp/verify" -Method Post -Body (J @{ phone = $phone; code = $code }) -ContentType 'application/json'
  return $v.data
}
function Hdr($tok) { return @{ Authorization = "Bearer $tok" } }

$fail = 0
function Check($cond, $msg) {
  if ($cond) { Write-Host "  PASS: $msg" }
  else { Write-Host "  FAIL: $msg" -ForegroundColor Red; $script:fail++ }
}

Wait-Up $auth 'auth'
Wait-Up $rest 'restaurant'
Wait-Up $ord  'order'

# 1) Admin (bootstrap) — ADMIN_PHONES
$admin = Login '+998900000000'
Check ($admin.user.roles -contains 'admin') "Admin roli bor (bootstrap)"

# 2) Tarifni belgilash (deterministik): deliveryFee=5000, komissiya=12%, kuryer ulushi=80%
$tar = Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers (Hdr $admin.accessToken) `
  -Body (J @{ deliveryFee = 5000; foodCommissionPercent = 12; courierSharePercent = 80 }) -ContentType 'application/json'
Check ($tar.data.courierSharePercent -eq 80) "Tarif courierSharePercent=80"
Check ($tar.data.deliveryFee -eq 5000) "Tarif deliveryFee=5000"

# 3) Haydovchi va oshxona foydalanuvchilariga rol berish
$drv0 = Login '+998902222222'
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers (Hdr $admin.accessToken) `
  -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$restUser0 = Login '+998903333333'
Invoke-RestMethod "$auth/auth/admin/users/$($restUser0.user.id)/roles" -Method Patch -Headers (Hdr $admin.accessToken) `
  -Body (J @{ roles = @('restaurant') }) -ContentType 'application/json' | Out-Null

# Rol berilgandan keyin yangi token (JWT ichida rollar)
$drv  = Login '+998902222222'
$rst  = Login '+998903333333'
Check ($drv.user.roles -contains 'driver') "Haydovchida 'driver' roli"
Check ($rst.user.roles -contains 'restaurant') "Oshxona userida 'restaurant' roli"

# 4) Boshlang'ich admin statistikasi
$statsBefore = (Invoke-RestMethod "$ord/admin/stats" -Headers (Hdr $admin.accessToken)).data

# 5) Mijoz buyurtma yaratadi: r1 / m1 (Osh 30000) x1
$cust = Login '+998901111111'
$orderBody = @{
  type         = 'FOOD'
  restaurantId = 'r1'
  items        = @(@{ menuItemId = 'm1'; qty = 1 })
  address      = @{ text = 'Beshariq, Markaziy ko''cha' }
  paymentType  = 'CASH'
}
$created = (Invoke-RestMethod "$ord/orders" -Method Post -Headers (Hdr $cust.accessToken) `
  -Body (J $orderBody) -ContentType 'application/json').data
$oid = $created.id
Write-Host "Buyurtma: #$($created.publicNo) id=$oid"
Check ($created.itemsTotal -eq 30000) "itemsTotal=30000 (joriy: $($created.itemsTotal))"
Check ($created.deliveryFee -eq 5000) "deliveryFee=5000 (joriy: $($created.deliveryFee))"
Check ($created.commission -eq 3600) "commission=3600 (joriy: $($created.commission))"
Check ($created.courierEarning -eq 4000) "courierEarning=4000 = round(5000*80%) (joriy: $($created.courierEarning))"
Check ($created.total -eq 35000) "total=35000 (joriy: $($created.total))"

# 6) Oshxona oqimi: accept -> preparing -> ready
Invoke-RestMethod "$ord/kitchen/orders/$oid/accept"    -Method Post -Headers (Hdr $rst.accessToken) | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$oid/preparing" -Method Post -Headers (Hdr $rst.accessToken) | Out-Null
$ready = (Invoke-RestMethod "$ord/kitchen/orders/$oid/ready" -Method Post -Headers (Hdr $rst.accessToken)).data
Check ($ready.status -eq 'READY') "Oshxona: READY holat"

# 7) Kuryer oqimi: available -> accept -> pickup -> delivered
$avail = (Invoke-RestMethod "$ord/courier/available" -Headers (Hdr $drv.accessToken)).data
Check (($avail | Where-Object { $_.id -eq $oid }) -ne $null) "Kuryer: buyurtma 'available' ro'yxatida"
Invoke-RestMethod "$ord/courier/orders/$oid/accept" -Method Post -Headers (Hdr $drv.accessToken) | Out-Null
Invoke-RestMethod "$ord/courier/orders/$oid/pickup" -Method Post -Headers (Hdr $drv.accessToken) | Out-Null
$delivered = (Invoke-RestMethod "$ord/courier/orders/$oid/delivered" -Method Post -Headers (Hdr $drv.accessToken)).data
Check ($delivered.status -eq 'DELIVERED') "Kuryer: DELIVERED holat"

# 8) Kuryer daromadi
$earn = (Invoke-RestMethod "$ord/courier/earnings" -Headers (Hdr $drv.accessToken)).data
Write-Host "Daromad: $(J $earn)"
Check ($earn.deliveredCount -ge 1) "earnings.deliveredCount >= 1"
Check ($earn.totalEarning -ge 4000) "earnings.totalEarning >= 4000 (joriy: $($earn.totalEarning))"
Check ($earn.todayEarning -ge 4000) "earnings.todayEarning >= 4000 (joriy: $($earn.todayEarning))"

# 9) Admin foydasi formulasi: delta = komissiya + (deliveryFee - kuryer) - chegirma = 3600 + 1000 = 4600
$statsAfter = (Invoke-RestMethod "$ord/admin/stats" -Headers (Hdr $admin.accessToken)).data
$profitDelta = $statsAfter.profit - $statsBefore.profit
$revenueDelta = $statsAfter.revenue - $statsBefore.revenue
Write-Host "profit: $($statsBefore.profit) -> $($statsAfter.profit) (delta $profitDelta)"
Write-Host "revenue: $($statsBefore.revenue) -> $($statsAfter.revenue) (delta $revenueDelta)"
Check ($profitDelta -eq 4600) "Admin foyda delta=4600 (komissiya 3600 + yetkazish foyda 1000)"
Check ($revenueDelta -eq 35000) "Admin aylanma delta=35000"

# 10) Begona rol himoyasi: mijoz /courier/earnings ga kira olmasligi (403)
$forbidden = $false
try { Invoke-RestMethod "$ord/courier/earnings" -Headers (Hdr $cust.accessToken) | Out-Null }
catch { if ($_.Exception.Response.StatusCode.value__ -eq 403) { $forbidden = $true } }
Check $forbidden "Mijoz /courier/earnings ga 403 (driver roli kerak)"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail ta TEST YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
