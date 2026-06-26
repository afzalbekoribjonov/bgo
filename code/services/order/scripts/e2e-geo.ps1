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
function J($o) { $o | ConvertTo-Json -Depth 10 }
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
$cust = Login '+998901111111'

# 1) Seed Beshariq hududi + joylar (public)
$areas = (Invoke-RestMethod "$ord/geo/areas").data
$beshariq = $areas | Where-Object { $_.name -eq 'Beshariq tumani' } | Select-Object -First 1
Check ($null -ne $beshariq) "Beshariq xizmat hududi seed qilingan"
Check ($beshariq.places.Count -ge 8) "Beshariqda >= 8 joy (marker)"

# 2) Hudud tekshiruvi — Beshariq markazi ichkarida
$inside = (Invoke-RestMethod "$ord/geo/check?lat=40.4236&lng=70.6094").data
Check ($inside.inside -eq $true) "Beshariq markazi hudud ichida"
Check ($inside.areaName -eq 'Beshariq tumani') "Tekshiruv hudud nomini qaytaradi"

# 3) Toshkent (uzoq) — tashqarida
$outside = (Invoke-RestMethod "$ord/geo/check?lat=41.31&lng=69.28").data
Check ($outside.inside -eq $false) "Toshkent nuqtasi hudud tashqarisida"

# 4) Admin: yangi tuman qo'shish (kengayish)
# GeoJSON poligon: [[[lng,lat],...]] — bitta tashqi halqa
$ring = @(@(70.45, 40.25), @(70.55, 40.25), @(70.55, 40.35), @(70.45, 40.35), @(70.45, 40.25))
$poly = , $ring
$newArea = (Invoke-RestMethod "$ord/admin/geo/areas" -Method Post -Headers $ah -Body (J @{
  name = "Test tumani $(Get-Random)"; centerLat = 40.30; centerLng = 70.50; boundary = $poly; isActive = $true
}) -ContentType 'application/json').data
$aid = $newArea.id
Check ($null -ne $aid) "Admin yangi tuman yaratdi"

# 5) Yangi tumandagi nuqta endi hudud ichida (kengayish ishladi)
$inNew = (Invoke-RestMethod "$ord/geo/check?lat=40.30&lng=70.50").data
Check ($inNew.inside -eq $true -and $inNew.areaId -eq $aid) "Yangi tuman nuqtasi hudud ichida (kengayish)"

# 6) Admin: yangi tumanga joy (marker) qo'shish
$place = (Invoke-RestMethod "$ord/admin/geo/areas/$aid/places" -Method Post -Headers $ah -Body (J @{
  label = 'Test markaz'; lat = 40.30; lng = 70.50; category = 'landmark'
}) -ContentType 'application/json').data
Check ($null -ne $place.id) "Admin yangi joy (marker) qo'shdi"
$areas2 = (Invoke-RestMethod "$ord/geo/areas").data
$found = $areas2 | Where-Object { $_.id -eq $aid }
Check (($found.places | Where-Object { $_.id -eq $place.id }) -ne $null) "Yangi joy public ro'yxatda"

# 6b) Admin: navigatsiya yo'llari (qo'shish / public+admin ro'yxat / himoya / o'chirish)
$road = (Invoke-RestMethod "$ord/admin/geo/areas/$aid/roads" -Method Post -Headers $ah -Body (J @{
  name = "Test ko'cha $(Get-Random)"; kind = 'main'; points = @(@(40.30, 70.50), @(40.305, 70.505), @(40.31, 70.51))
}) -ContentType 'application/json').data
Check ($null -ne $road.id) "Admin navigatsiya yo'li qo'shdi"
Check (@($road.points).Count -eq 3) "Yo'l 3 nuqta bilan saqlandi"
$pubRoads = (Invoke-RestMethod "$ord/geo/roads").data
Check (($pubRoads | Where-Object { $_.id -eq $road.id }) -ne $null) "Faol hudud yo'li public ro'yxatda"
$admRoads = (Invoke-RestMethod "$ord/admin/geo/roads" -Headers $ah).data
Check (($admRoads | Where-Object { $_.id -eq $road.id }) -ne $null) "Yo'l admin ro'yxatida"
Check (Status 403 { Invoke-RestMethod "$ord/admin/geo/areas/$aid/roads" -Method Post -Headers (Hdr $cust.accessToken) -Body (J @{ name='x'; kind='street'; points=@(@(40.3,70.5),@(40.31,70.51)) }) -ContentType 'application/json' | Out-Null }) "Mijoz yo'l qo'shish -> 403"
Invoke-RestMethod "$ord/admin/geo/roads/$($road.id)" -Method Delete -Headers $ah | Out-Null
$pubRoads2 = (Invoke-RestMethod "$ord/geo/roads").data
Check (($pubRoads2 | Where-Object { $_.id -eq $road.id }) -eq $null) "Yo'l o'chirildi (public ro'yxatdan yo'qoldi)"

# 7) isActive=false -> public ro'yxatdan yo'qoladi (hudud + uning yo'llari)
$road2 = (Invoke-RestMethod "$ord/admin/geo/areas/$aid/roads" -Method Post -Headers $ah -Body (J @{
  name = "Vaqtincha yo'l"; kind = 'street'; points = @(@(40.30, 70.50), @(40.31, 70.51))
}) -ContentType 'application/json').data
Invoke-RestMethod "$ord/admin/geo/areas/$aid" -Method Patch -Headers $ah -Body (J @{ isActive = $false }) -ContentType 'application/json' | Out-Null
$areas3 = (Invoke-RestMethod "$ord/geo/areas").data
Check (($areas3 | Where-Object { $_.id -eq $aid }) -eq $null) "Nofaol tuman public ro'yxatda yo'q"
$pubRoads3 = (Invoke-RestMethod "$ord/geo/roads").data
Check (($pubRoads3 | Where-Object { $_.id -eq $road2.id }) -eq $null) "Nofaol hudud yo'li public ro'yxatda yo'q"
$adminAll = (Invoke-RestMethod "$ord/admin/geo/areas" -Headers $ah).data
Check (($adminAll | Where-Object { $_.id -eq $aid }) -ne $null) "Nofaol tuman admin ro'yxatda bor"

# 8) Himoya: mijoz tuman yarata olmaydi -> 403
Check (Status 403 { Invoke-RestMethod "$ord/admin/geo/areas" -Method Post -Headers (Hdr $cust.accessToken) -Body (J @{ name='x'; centerLat=40; centerLng=70; boundary=$poly }) -ContentType 'application/json' | Out-Null }) "Mijoz tuman yaratish -> 403"

# 9) Tozalash
Invoke-RestMethod "$ord/admin/geo/places/$($place.id)" -Method Delete -Headers $ah | Out-Null
Invoke-RestMethod "$ord/admin/geo/areas/$aid" -Method Delete -Headers $ah | Out-Null
$areas4 = (Invoke-RestMethod "$ord/admin/geo/areas" -Headers $ah).data
Check (($areas4 | Where-Object { $_.id -eq $aid }) -eq $null) "Tuman o'chirildi (tozalash)"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
