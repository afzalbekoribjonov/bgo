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
function MakeDriver($phone, $ah) {
  $d0 = Login $phone
  Invoke-RestMethod "$auth/auth/admin/users/$($d0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
  return Login $phone
}
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

Wait-Up $auth 'auth'; Wait-Up $ord 'order'

$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken
$drv  = MakeDriver '+998902222222' $ah; $dh = Hdr $drv.accessToken
$drv2 = MakeDriver '+998903333333' $ah; $dh2 = Hdr $drv2.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken

$pickup = @{ text = 'Beshariq markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka mahalla';  lat = 40.5000; lng = 70.7000 }

# 1) Haydovchi joylashuv yuboradi (pickup yonida)
$loc = (Invoke-RestMethod "$ord/driver/location" -Method Post -Headers $dh -Body (J @{ lat = 40.4240; lng = 70.6100; heading = 90 }) -ContentType 'application/json').data
Check ($loc.lat -eq 40.4240 -and $loc.lng -eq 70.6100) "Haydovchi joylashuv yubordi (upsert)"

# 2) Ikkinchi haydovchi — uzoqda (Toshkent), yaqin ro'yxatga tushmasligi kerak
Invoke-RestMethod "$ord/driver/location" -Method Post -Headers $dh2 -Body (J @{ lat = 41.3100; lng = 69.2800 }) -ContentType 'application/json' | Out-Null

# 3) Mijoz "yaqin mashinalar" so'raydi -> pickup yonidagi 1 ta haydovchi
$nearby = @((Invoke-RestMethod "$ord/taxi/nearby-drivers?lat=40.4236&lng=70.6094" -Headers $ch).data)
Check ($nearby.Count -ge 1) "Yaqin mashinalar ro'yxatida online haydovchi bor"
$closest = $nearby | Sort-Object distanceKm | Select-Object -First 1
Check ($closest.distanceKm -lt 1) "Eng yaqin mashina < 1 km (joriy: $($closest.distanceKm))"
Check (-not ($nearby | Where-Object { $_.distanceKm -gt 6 })) "Uzoq (Toshkent) haydovchi yaqin ro'yxatda yo'q"
Check ($null -eq ($nearby | Where-Object { $_.driverId })) "Yaqin mashinalar anonim (driverId yo'q)"

# 4) Safar yaratiladi, haydovchi qabul qiladi -> mijoz haydovchi joylashuvini ko'radi
$trip = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
$tid = $trip.id

# Biriktirilmagan safarda haydovchi joylashuvi -> null
$pre = (Invoke-RestMethod "$ord/taxi/$tid/driver" -Headers $ch).data
Check ($null -eq $pre) "Haydovchi biriktirilmaguncha joylashuv null"

Invoke-RestMethod "$ord/taxi/driver/trips/$tid/accept" -Method Post -Headers $dh | Out-Null
$dl = (Invoke-RestMethod "$ord/taxi/$tid/driver" -Headers $ch).data
Check ($null -ne $dl -and $dl.lat -eq 40.4240) "Mijoz biriktirilgan haydovchi joylashuvini ko'radi"

# 5) Haydovchi siljiydi -> mijoz yangilangan joylashuvni ko'radi
Invoke-RestMethod "$ord/driver/location" -Method Post -Headers $dh -Body (J @{ lat = 40.4255; lng = 70.6120 }) -ContentType 'application/json' | Out-Null
$dl2 = (Invoke-RestMethod "$ord/taxi/$tid/driver" -Headers $ch).data
Check ($dl2.lat -eq 40.4255 -and $dl2.lng -eq 70.6120) "Haydovchi joylashuvi yangilandi (jonli)"

# 6) Himoya: mijoz joylashuv yubora olmaydi (faqat driver) -> 403
Check (Status 403 { Invoke-RestMethod "$ord/driver/location" -Method Post -Headers $ch -Body (J @{ lat = 40.4; lng = 70.6 }) -ContentType 'application/json' | Out-Null }) "Mijoz joylashuv yuborishi -> 403"

# 7) Himoya: begona mijoz boshqa safar haydovchisini ko'ra olmaydi -> 403
$other = Login '+998904444444'; $oh = Hdr $other.accessToken
Check (Status 403 { Invoke-RestMethod "$ord/taxi/$tid/driver" -Headers $oh | Out-Null }) "Begona mijoz safar haydovchisi -> 403"

# 8) Tokensiz -> 401
Check (Status 401 { Invoke-RestMethod "$ord/taxi/nearby-drivers?lat=40.4&lng=70.6" | Out-Null }) "Tokensiz yaqin mashinalar -> 401"

# 9) Haydovchi offline -> yaqin ro'yxatdan yo'qoladi
Invoke-RestMethod "$ord/driver/location" -Method Delete -Headers $dh | Out-Null
$nearby2 = @((Invoke-RestMethod "$ord/taxi/nearby-drivers?lat=40.4236&lng=70.6094" -Headers $ch).data)
Check ($closest.distanceKm -lt 1 -and ($nearby2 | Where-Object { $_.distanceKm -lt 1 }).Count -eq 0) "Offline haydovchi yaqin ro'yxatda yo'q"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
