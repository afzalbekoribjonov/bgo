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
function Status($code, $block) {
  try { & $block; return $false } catch { return ($_.Exception.Response.StatusCode.value__ -eq $code) }
}
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

Wait-Up $auth 'auth'; Wait-Up $ord 'order'
$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken
Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers $ah -Body (J @{
  taxiBaseFare = 5000; taxiPerKm = 2000; taxiMinFare = 8000; taxiCommissionPercent = 15; taxiWaitPerMin = 500
}) -ContentType 'application/json' | Out-Null
$tar = (Invoke-RestMethod "$ord/admin/tariff" -Headers $ah).data
Check ($tar.taxiWaitPerMin -eq 500) "Tarif taxiWaitPerMin=500"

$dphone = '+99890' + (Get-Random -Minimum 7000000 -Maximum 7999999)
$drv0 = Login $dphone
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$drv = Login $dphone; $dh = Hdr $drv.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

$pickup = @{ text = 'Markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka'; lat = 40.5000; lng = 70.7000 }
$est = (Invoke-RestMethod "$ord/taxi/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
$base = $est.fare  # belgilangan masofa narxi (kutishsiz)
Write-Host "Base fare (route): $base"

# ---- 1) FIXED (manzilli), kutishsiz ----
$t1 = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
Check ($t1.metered -eq $false) "FIXED: metered=false"
Check ($t1.fare -eq $base) "FIXED: yaratishda narx = estimate"
Invoke-RestMethod "$ord/taxi/driver/trips/$($t1.id)/accept" -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($t1.id)/start" -Method Post -Headers $dh | Out-Null
$c1 = (Invoke-RestMethod "$ord/taxi/driver/trips/$($t1.id)/complete" -Method Post -Headers $dh -Body (J @{}) -ContentType 'application/json').data
Check ($c1.fare -eq $base) "FIXED kutishsiz: narx o'zgarmadi"
Check ($c1.commission -eq [math]::Round($base * 0.15)) "FIXED: komissiya 15%"

# ---- 2) FIXED + kutish 10 daqiqa ----
$t2 = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
Invoke-RestMethod "$ord/taxi/driver/trips/$($t2.id)/accept" -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($t2.id)/start" -Method Post -Headers $dh | Out-Null
$c2 = (Invoke-RestMethod "$ord/taxi/driver/trips/$($t2.id)/complete" -Method Post -Headers $dh -Body (J @{ waitMinutes = 10 }) -ContentType 'application/json').data
Check ($c2.waitMinutes -eq 10) "FIXED+kutish: waitMinutes=10"
Check ($c2.fare -eq ($base + 5000)) "FIXED+kutish: narx = base + 10×500 ($($c2.fare))"
Check ($c2.driverEarning -eq ($c2.fare - [math]::Round($c2.fare * 0.15))) "FIXED+kutish: driverEarning qayta hisob"

# ---- 3) METERED (manzilsiz) ----
$t3 = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup }) -ContentType 'application/json').data
Check ($t3.metered -eq $true) "METERED: manzilsiz -> metered=true"
Check ($t3.fare -eq 0) "METERED: yaratishda narx 0 (yakunda hisoblanadi)"
Check ($null -eq $t3.destination) "METERED: manzil bo'sh"
Invoke-RestMethod "$ord/taxi/driver/trips/$($t3.id)/accept" -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($t3.id)/start" -Method Post -Headers $dh | Out-Null
$c3 = (Invoke-RestMethod "$ord/taxi/driver/trips/$($t3.id)/complete" -Method Post -Headers $dh -Body (J @{ distanceKm = $est.distanceKm; waitMinutes = 5 }) -ContentType 'application/json').data
# metered narx = max(min, base+perKm*masofa) + 5×500. Bu masofada base = $base.
Check ($c3.fare -eq ($base + 2500)) "METERED: narx = masofa narxi + 5×500 ($($c3.fare))"
Check ($c3.distanceKm -eq $est.distanceKm) "METERED: masofa yakunda saqlandi"

# ---- 4) Manzilsiz estimate -> 400 ----
Check (Status 400 { Invoke-RestMethod "$ord/taxi/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup }) -ContentType 'application/json' | Out-Null }) "Manzilsiz estimate -> 400"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
