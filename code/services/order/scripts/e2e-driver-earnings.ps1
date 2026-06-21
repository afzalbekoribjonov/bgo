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

$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken
Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers $ah -Body (J @{
  deliveryFee = 5000; foodCommissionPercent = 12; courierSharePercent = 80;
  taxiBaseFare = 5000; taxiPerKm = 2000; taxiMinFare = 8000; taxiCommissionPercent = 15;
  parcelBaseFare = 4000; parcelPerKm = 1500; parcelMinFare = 6000; parcelCommissionPercent = 15
}) -ContentType 'application/json' | Out-Null

# Yangi (toza) haydovchi — boshqa testlardagi ishlar aralashmasin
$dphone = '+99890' + (Get-Random -Minimum 3000000 -Maximum 3999999)
$drv0 = Login $dphone
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$rst0 = Login '+998903333333'
Invoke-RestMethod "$auth/auth/admin/users/$($rst0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('restaurant') }) -ContentType 'application/json' | Out-Null
$drv = Login $dphone; $dh = Hdr $drv.accessToken
$rst = Login '+998903333333'; $rh = Hdr $rst.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

$pickup = @{ text = 'Markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka'; lat = 40.5000; lng = 70.7000 }

# ----- 1) Ovqat: buyurtma -> oshxona -> kuryer -> delivered -----
$o = (Invoke-RestMethod "$ord/orders" -Method Post -Headers $ch -Body (J @{
  type = 'FOOD'; restaurantId = 'r1'; items = @(@{ menuItemId = 'm1'; qty = 1 });
  address = @{ text = 'Manzil' }; paymentType = 'CASH' }) -ContentType 'application/json').data
$foodEarn = $o.courierEarning
# Kitchen amallari admin token bilan (egalik bypass — r1 egasi boshqa test'da o'rnatilgan)
Invoke-RestMethod "$ord/kitchen/orders/$($o.id)/accept"    -Method Post -Headers $ah | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$($o.id)/preparing" -Method Post -Headers $ah | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$($o.id)/ready"     -Method Post -Headers $ah | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o.id)/accept"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o.id)/pickup"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o.id)/delivered" -Method Post -Headers $dh | Out-Null

# ----- 2) Taksi: chaqirish -> accept -> start -> complete -----
$trip = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
$taxiEarn = $trip.driverEarning
Invoke-RestMethod "$ord/taxi/driver/trips/$($trip.id)/accept"   -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($trip.id)/start"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($trip.id)/complete" -Method Post -Headers $dh | Out-Null

# ----- 3) Dostavka: jo'natish -> accept -> pickup -> delivered -----
$pc = (Invoke-RestMethod "$ord/parcel/request" -Method Post -Headers $ch -Body (J @{
  pickup = $pickup; destination = $dest; size = 'MEDIUM'; recipientName = 'Olim'; recipientPhone = '+998901112233'
}) -ContentType 'application/json').data
$parcelEarn = $pc.driverEarning
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($pc.id)/accept"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($pc.id)/pickup"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($pc.id)/delivered" -Method Post -Headers $dh | Out-Null

Write-Host "Daromadlar: food=$foodEarn taxi=$taxiEarn parcel=$parcelEarn"

# ----- Birlashgan daromad -----
$e = (Invoke-RestMethod "$ord/courier/earnings" -Headers $dh).data
Write-Host "Earnings: $(J $e)"
Check ($e.food.count -eq 1) "food.count=1"
Check ($e.food.earning -eq $foodEarn) "food.earning=$foodEarn"
Check ($e.taxi.count -eq 1) "taxi.count=1"
Check ($e.taxi.earning -eq $taxiEarn) "taxi.earning=$taxiEarn"
Check ($e.parcel.count -eq 1) "parcel.count=1"
Check ($e.parcel.earning -eq $parcelEarn) "parcel.earning=$parcelEarn"
Check ($e.total.count -eq 3) "total.count=3"
$sum = $foodEarn + $taxiEarn + $parcelEarn
Check ($e.total.earning -eq $sum) "total.earning=$sum (jami)"
Check ($e.total.todayEarning -eq $sum) "total.todayEarning=$sum (hammasi bugun)"
Check ($e.total.activeCount -eq 0) "total.activeCount=0 (hammasi yakunlandi)"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
