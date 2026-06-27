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

# Deterministik dostavka tarifi: base 4000, perKm 1500, min 6000, komissiya 15%
Invoke-RestMethod "$ord/admin/tariff" -Method Put -Headers $ah -Body (J @{
  parcelBaseFare = 4000; parcelPerKm = 1500; parcelMinFare = 6000; parcelCommissionPercent = 15
}) -ContentType 'application/json' | Out-Null
$tar = (Invoke-RestMethod "$ord/admin/tariff" -Headers $ah).data
Check ($tar.parcelPerKm -eq 1500) "Tarif parcelPerKm=1500"

# Kuryer roli
$drv0 = Login '+998902222222'
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$drv = Login '+998902222222'; $dh = Hdr $drv.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

$pickup = @{ text = 'Beshariq markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka mahalla';  lat = 40.5000; lng = 70.7000 }

# Narx 500 so'mga yaxlitlanadi (roundFare) — server bilan bir xil.
function RoundFare($v) { return [math]::Round([double]$v / 500) * 500 }

# 1) Narx (SMALL) — masofadan
$estS = (Invoke-RestMethod "$ord/parcel/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest; size = 'SMALL' }) -ContentType 'application/json').data
Write-Host "Estimate SMALL: $(J $estS)"
Check ($estS.distanceKm -gt 10 -and $estS.distanceKm -lt 13) "Masofa ~11-12 km"
$base = [math]::Max(6000, 4000 + [math]::Round(1500 * $estS.distanceKm))
Check ($estS.fare -eq (RoundFare ([math]::Round($base * 1.0)))) "SMALL narx 500ga yaxlit (=$($estS.fare))"
Check ($estS.commission -eq [math]::Round($estS.fare * 0.15)) "SMALL komissiya 15%"
Check (($estS.fare % 500) -eq 0) "SMALL narx 500ga karrali"

# 2) O'lcham koeffitsienti: MEDIUM ×1.3, LARGE ×1.6 (keyin 500ga yaxlit)
$estM = (Invoke-RestMethod "$ord/parcel/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest; size = 'MEDIUM' }) -ContentType 'application/json').data
$estL = (Invoke-RestMethod "$ord/parcel/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest; size = 'LARGE' }) -ContentType 'application/json').data
Check ($estM.fare -eq (RoundFare ([math]::Round($base * 1.3)))) "MEDIUM = base ×1.3 yaxlit (M=$($estM.fare))"
Check ($estL.fare -eq (RoundFare ([math]::Round($base * 1.6)))) "LARGE = base ×1.6 yaxlit (L=$($estL.fare))"

# 3) Minimal haq — yaqin nuqta
$near = @{ text = 'Yaqin'; lat = 40.4236; lng = 70.6095 }
$estMin = (Invoke-RestMethod "$ord/parcel/estimate" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $near; size = 'SMALL' }) -ContentType 'application/json').data
Check ($estMin.fare -eq 6000) "Yaqin masofada minimal haq (6000)"

# 4) Dostavka jo'natish (qabul qiluvchi bilan)
$p = (Invoke-RestMethod "$ord/parcel/request" -Method Post -Headers $ch -Body (J @{
  pickup = $pickup; destination = $dest; size = 'MEDIUM';
  recipientName = 'Olim Karimov'; recipientPhone = '+998901112233'; note = 'Hujjatlar'
}) -ContentType 'application/json').data
$pcId = $p.id
Check ($p.status -eq 'PENDING') "Dostavka PENDING"
Check ($p.recipientName -eq 'Olim Karimov') "Qabul qiluvchi saqlandi"
Check ($p.fare -eq $estM.fare) "Dostavka haqi = MEDIUM estimate"

# 5) Kuryer available
$avail = (Invoke-RestMethod "$ord/parcel/driver/available" -Headers $dh).data
Check (($avail | Where-Object { $_.id -eq $pcId }) -ne $null) "Kuryer available da dostavkani ko'radi"

# 6) Oqim: accept -> pickup -> delivered
$acc = (Invoke-RestMethod "$ord/parcel/driver/deliveries/$pcId/accept" -Method Post -Headers $dh).data
Check ($acc.status -eq 'ACCEPTED') "accept -> ACCEPTED"
$pk = (Invoke-RestMethod "$ord/parcel/driver/deliveries/$pcId/pickup" -Method Post -Headers $dh).data
Check ($pk.status -eq 'PICKED_UP') "pickup -> PICKED_UP"
$dl = (Invoke-RestMethod "$ord/parcel/driver/deliveries/$pcId/delivered" -Method Post -Headers $dh).data
Check ($dl.status -eq 'DELIVERED') "delivered -> DELIVERED"

# 7) Mijoz ko'radi
$mine = (Invoke-RestMethod "$ord/parcel/mine" -Headers $ch).data
Check (($mine | Where-Object { $_.id -eq $pcId -and $_.status -eq 'DELIVERED' }) -ne $null) "Mijoz DELIVERED dostavkani ko'radi"

# 8) Himoya
Check (Status 403 { Invoke-RestMethod "$ord/parcel/driver/available" -Headers $ch | Out-Null }) "Mijoz parcel/driver -> 403"
Check (Status 401 { Invoke-RestMethod "$ord/parcel/mine" | Out-Null }) "Tokensiz parcel/mine -> 401"

# 9) Bekor qilish
$p2 = (Invoke-RestMethod "$ord/parcel/request" -Method Post -Headers $ch -Body (J @{
  pickup = $pickup; destination = $dest; size = 'SMALL'; recipientName = 'X'; recipientPhone = '+998900000002'
}) -ContentType 'application/json').data
$cancelled = (Invoke-RestMethod "$ord/parcel/$($p2.id)/cancel" -Method Post -Headers $ch).data
Check ($cancelled.status -eq 'CANCELLED') "Mijoz PENDING dostavkani bekor qildi"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
