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

# Deterministik taksi tarifi: base 5000, perKm 2000, min 8000, komissiya 15%
Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers $ah -Body (J @{
  taxiBaseFare = 5000; taxiPerKm = 2000; taxiMinFare = 8000; taxiCommissionPercent = 15
}) -ContentType 'application/json' | Out-Null
$tar = (Invoke-RestMethod "$ord/admin/tariff" -Headers $ah).data
Check ($tar.taxiPerKm -eq 2000) "Tarif taxiPerKm=2000"

# Haydovchi roli
$drv0 = Login '+998902222222'
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$drv = Login '+998902222222'; $dh = Hdr $drv.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

# Ikki nuqta: pickup (40.4236,70.6094) -> dest (40.5000,70.7000) ~ 11.9 km
$pickup = @{ text = 'Beshariq markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka mahalla';  lat = 40.5000; lng = 70.7000 }

# 1) Narx baholash (haversine)
$est = (Invoke-RestMethod "$ord/taxi/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
Write-Host "Estimate: $(J $est)"
# Narx 500 so'mga yaxlitlanadi (roundFare) — server bilan bir xil.
$raw = 5000 + [math]::Round(2000 * $est.distanceKm)
$expectedFare = [math]::Max(8000, $raw)
$expectedFare = [math]::Round([double]$expectedFare / 500) * 500
Check ($est.distanceKm -gt 10 -and $est.distanceKm -lt 13) "Masofa ~11-12 km (joriy: $($est.distanceKm))"
Check ($est.fare -eq $expectedFare) "Narx (500ga yaxlit) to'g'ri (fare=$($est.fare), kutilgan=$expectedFare)"
Check (($est.fare % 500) -eq 0) "Narx 500ga karrali"
Check ($est.commission -eq [math]::Round($est.fare * 0.15)) "Komissiya 15%"
Check ($est.driverEarning -eq ($est.fare - $est.commission)) "Haydovchi ulushi = fare - komissiya"

# 2) Minimal haq: juda yaqin nuqtalar -> minFare
$near = @{ text = 'Yaqin'; lat = 40.4236; lng = 70.6095 }
$estMin = (Invoke-RestMethod "$ord/taxi/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $near }) -ContentType 'application/json').data
Check ($estMin.fare -eq 8000) "Yaqin masofada minimal haq (8000)"

# 3) Taksi chaqirish
$trip = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
$tid = $trip.id
Check ($trip.status -eq 'PENDING') "Safar PENDING"
Check ($trip.fare -eq $est.fare) "Safar haqi = estimate"

# 4) Haydovchi available da ko'radi
$avail = (Invoke-RestMethod "$ord/taxi/driver/available" -Headers $dh).data
Check (($avail | Where-Object { $_.id -eq $tid }) -ne $null) "Haydovchi available da safarni ko'radi"

# 5) Oqim: accept -> start -> complete
$acc = (Invoke-RestMethod "$ord/taxi/driver/trips/$tid/accept" -Method Post -Headers $dh).data
Check ($acc.status -eq 'ACCEPTED') "accept -> ACCEPTED"
$st = (Invoke-RestMethod "$ord/taxi/driver/trips/$tid/start" -Method Post -Headers $dh).data
Check ($st.status -eq 'IN_PROGRESS') "start -> IN_PROGRESS"
$comp = (Invoke-RestMethod "$ord/taxi/driver/trips/$tid/complete" -Method Post -Headers $dh).data
Check ($comp.status -eq 'COMPLETED') "complete -> COMPLETED"

# 6) Mijoz o'z safarini ko'radi
$mine = (Invoke-RestMethod "$ord/taxi/mine" -Headers $ch).data
Check (($mine | Where-Object { $_.id -eq $tid -and $_.status -eq 'COMPLETED' }) -ne $null) "Mijoz COMPLETED safarni ko'radi"

# 7) Himoya: mijoz haydovchi endpointiga -> 403
Check (Status 403 { Invoke-RestMethod "$ord/taxi/driver/available" -Headers $ch | Out-Null }) "Mijoz taxi/driver -> 403"
# 8) Tokensiz -> 401
Check (Status 401 { Invoke-RestMethod "$ord/taxi/mine" | Out-Null }) "Tokensiz taxi/mine -> 401"

# 9) Bekor qilish (yangi safar, PENDING)
$trip2 = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
$cancelled = (Invoke-RestMethod "$ord/taxi/$($trip2.id)/cancel" -Method Post -Headers $ch).data
Check ($cancelled.status -eq 'CANCELLED') "Mijoz PENDING safarni bekor qildi"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
