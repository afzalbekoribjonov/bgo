$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'
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

Wait-Up $auth 'auth'; Wait-Up $ord 'order'

$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken
Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers $ah -Body (J @{
  deliveryFee = 5000; foodCommissionPercent = 12; courierSharePercent = 80;
  taxiBaseFare = 5000; taxiPerKm = 2000; taxiMinFare = 8000; taxiCommissionPercent = 15;
  parcelBaseFare = 4000; parcelPerKm = 1500; parcelMinFare = 6000; parcelCommissionPercent = 15
}) -ContentType 'application/json' | Out-Null

$dphone = '+99890' + (Get-Random -Minimum 4000000 -Maximum 4999999)
$drv0 = Login $dphone
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$drv = Login $dphone; $dh = Hdr $drv.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

$pickup = @{ text = 'Markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka'; lat = 40.5000; lng = 70.7000 }

# Boshlang'ich admin statistikasi
$before = (Invoke-RestMethod "$ord/admin/stats" -Headers $ah).data

# --- Ovqat: buyurtma -> delivered ---
$o = (Invoke-RestMethod "$ord/orders" -Method Post -Headers $ch -Body (J @{
  type = 'FOOD'; restaurantId = 'r1'; items = @(@{ menuItemId = 'm1'; qty = 1 });
  address = @{ text = 'Manzil' }; paymentType = 'CASH' }) -ContentType 'application/json').data
$foodRev = $o.total
$foodProfit = $o.commission + ($o.deliveryFee - $o.courierEarning) - $o.discount
Invoke-RestMethod "$ord/kitchen/orders/$($o.id)/accept"    -Method Post -Headers $ah | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$($o.id)/preparing" -Method Post -Headers $ah | Out-Null
Invoke-RestMethod "$ord/kitchen/orders/$($o.id)/ready"     -Method Post -Headers $ah | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o.id)/accept"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o.id)/pickup"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/courier/orders/$($o.id)/delivered" -Method Post -Headers $dh | Out-Null

# --- Taksi -> completed ---
$trip = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
$taxiRev = $trip.fare; $taxiProfit = $trip.commission
Invoke-RestMethod "$ord/taxi/driver/trips/$($trip.id)/accept"   -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($trip.id)/start"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($trip.id)/complete" -Method Post -Headers $dh | Out-Null

# --- Dostavka -> delivered ---
$pc = (Invoke-RestMethod "$ord/parcel/request" -Method Post -Headers $ch -Body (J @{
  pickup = $pickup; destination = $dest; size = 'MEDIUM'; recipientName = 'Olim'; recipientPhone = '+998901112233'
}) -ContentType 'application/json').data
$parcelRev = $pc.fare; $parcelProfit = $pc.commission
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($pc.id)/accept"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($pc.id)/pickup"    -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($pc.id)/delivered" -Method Post -Headers $dh | Out-Null

Write-Host "Aylanma: food=$foodRev taxi=$taxiRev parcel=$parcelRev"
Write-Host "Foyda:   food=$foodProfit taxi=$taxiProfit parcel=$parcelProfit"

# --- Birlashgan admin statistikasi ---
$after = (Invoke-RestMethod "$ord/admin/stats" -Headers $ah).data
Check (($after.revenue - $before.revenue) -eq ($foodRev + $taxiRev + $parcelRev)) "Jami aylanma delta = food+taxi+parcel"
Check (($after.profit - $before.profit) -eq ($foodProfit + $taxiProfit + $parcelProfit)) "Jami foyda delta = food+taxi+parcel"
Check (($after.byVertical.food.revenue - $before.byVertical.food.revenue) -eq $foodRev) "byVertical.food.revenue delta"
Check (($after.byVertical.taxi.revenue - $before.byVertical.taxi.revenue) -eq $taxiRev) "byVertical.taxi.revenue delta"
Check (($after.byVertical.taxi.profit - $before.byVertical.taxi.profit) -eq $taxiProfit) "byVertical.taxi.profit delta"
Check (($after.byVertical.parcel.revenue - $before.byVertical.parcel.revenue) -eq $parcelRev) "byVertical.parcel.revenue delta"
Check (($after.byVertical.parcel.profit - $before.byVertical.parcel.profit) -eq $parcelProfit) "byVertical.parcel.profit delta"

# --- Davr hisoboti (bugun) ---
$rep = (Invoke-RestMethod "$ord/admin/reports?period=today" -Headers $ah).data
Check ($rep.byVertical -ne $null) "report.byVertical mavjud"
Check ($rep.summary.revenue -ge ($foodRev + $taxiRev + $parcelRev)) "report bugungi aylanma >= 3 vertikal"
$lastDay = $rep.daily[$rep.daily.Count - 1]
Check ($lastDay.revenue -ge ($foodRev + $taxiRev + $parcelRev)) "bugungi kunlik chelak 3 vertikalni o'z ichiga oladi"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
