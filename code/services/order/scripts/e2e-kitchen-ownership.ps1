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
function Status403($block) {
  try { & $block; return $false } catch { return ($_.Exception.Response.StatusCode.value__ -eq 403) }
}
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

Wait-Up $auth 'auth'; Wait-Up $rest 'restaurant'; Wait-Up $ord 'order'

$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken

# Ikki oshxona egasi
$ownerA0 = Login '+998905555555'
Invoke-RestMethod "$auth/auth/admin/users/$($ownerA0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('restaurant') }) -ContentType 'application/json' | Out-Null
$ownerB0 = Login '+998906666666'
Invoke-RestMethod "$auth/auth/admin/users/$($ownerB0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('restaurant') }) -ContentType 'application/json' | Out-Null
$ownerA = Login '+998905555555'; $ha = Hdr $ownerA.accessToken
$ownerB = Login '+998906666666'; $hb = Hdr $ownerB.accessToken

# Egalik biriktirish: r1 -> A, r2 -> B
Invoke-RestMethod "$rest/restaurants/r1/owner" -Method Patch -Headers $ah -Body (J @{ ownerUserId = $ownerA.user.id }) -ContentType 'application/json' | Out-Null
Invoke-RestMethod "$rest/restaurants/r2/owner" -Method Patch -Headers $ah -Body (J @{ ownerUserId = $ownerB.user.id }) -ContentType 'application/json' | Out-Null

# A ning oshxonalari = r1
$mineA = (Invoke-RestMethod "$rest/restaurants/mine" -Headers $ha).data
Check (($mineA | Where-Object { $_.id -eq 'r1' }) -ne $null) "A /restaurants/mine -> r1 bor"
Check (($mineA | Where-Object { $_.id -eq 'r2' }) -eq $null) "A /restaurants/mine -> r2 yo'q"

# Mijoz r1 uchun buyurtma yaratadi
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken
$order = (Invoke-RestMethod "$ord/orders" -Method Post -Headers $ch -Body (J @{
  type = 'FOOD'; restaurantId = 'r1'; items = @(@{ menuItemId = 'm1'; qty = 1 });
  address = @{ text = 'Egalik test' }; paymentType = 'CASH' }) -ContentType 'application/json').data
$oid = $order.id

# Egasi (A) r1 buyurtmalarini ko'radi
$listA = (Invoke-RestMethod "$ord/kitchen/restaurants/r1/orders" -Headers $ha).data
Check (($listA | Where-Object { $_.id -eq $oid }) -ne $null) "A r1 buyurtmalarini ko'radi"

# Begona (B) r1 buyurtmalarini ko'ra olmaydi -> 403
Check (Status403 { Invoke-RestMethod "$ord/kitchen/restaurants/r1/orders" -Headers $hb | Out-Null }) "B r1 ro'yxatiga 403"

# Begona (B) r1 buyurtmasini accept qila olmaydi -> 403
Check (Status403 { Invoke-RestMethod "$ord/kitchen/orders/$oid/accept" -Method Post -Headers $hb | Out-Null }) "B r1 buyurtmasini accept -> 403"

# Buyurtma hali ham PENDING (B hech narsa o'zgartirmadi)
$still = (Invoke-RestMethod "$ord/kitchen/restaurants/r1/orders" -Headers $ha).data | Where-Object { $_.id -eq $oid }
Check ($still.status -eq 'PENDING') "B urinishidan keyin buyurtma PENDING (o'zgarmadi)"

# Egasi (A) accept qiladi -> ACCEPTED
$acc = (Invoke-RestMethod "$ord/kitchen/orders/$oid/accept" -Method Post -Headers $ha).data
Check ($acc.status -eq 'ACCEPTED') "A buyurtmani ACCEPTED qildi"

# Admin bypass: r1 ro'yxatini ko'radi
$listAdmin = (Invoke-RestMethod "$ord/kitchen/restaurants/r1/orders" -Headers $ah).data
Check (($listAdmin | Where-Object { $_.id -eq $oid }) -ne $null) "Admin bypass: r1 ro'yxatini ko'radi"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
