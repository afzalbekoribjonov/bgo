$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'
$rest = 'http://localhost:4003/api/v1'

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

Wait-Up $auth 'auth'; Wait-Up $rest 'restaurant'

$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken

# 1) Yangi oshxona yaratish
$name = "Test Oshxona $(Get-Random -Minimum 1000 -Maximum 9999)"
$created = (Invoke-RestMethod "$rest/restaurants" -Method Post -Headers $ah -Body (J @{
  name = $name; address = 'Beshariq, Test ko''cha 1'; phone = '+998901234567'; commissionPercent = 15
}) -ContentType 'application/json').data
$rid = $created.id
Check ($created.name -eq $name) "Oshxona yaratildi (name)"
Check ($created.status -eq 'ACTIVE') "Yangi oshxona ACTIVE"
Check ($created.commissionPercent -eq 15) "commissionPercent=15"
Check ($created.isOpen -eq $true) "isOpen=true (standart)"

# 2) Admin ro'yxatida bor (manage/all — :id bilan to'qnashmaydi)
$all = (Invoke-RestMethod "$rest/restaurants/manage/all" -Headers $ah).data
Check (($all | Where-Object { $_.id -eq $rid }) -ne $null) "manage/all da yangi oshxona bor"
Check (($all | Where-Object { $_.id -eq 'r1' }) -ne $null) "manage/all da seed (r1) ham bor"

# 3) Public ro'yxatda ko'rinadi (ACTIVE)
$public = (Invoke-RestMethod "$rest/restaurants").data
Check (($public | Where-Object { $_.id -eq $rid }) -ne $null) "public ro'yxatda yangi oshxona bor"

# 4) Tahrirlash: yopish + nom
$upd = (Invoke-RestMethod "$rest/restaurants/$rid" -Method Patch -Headers $ah -Body (J @{ isOpen = $false; name = "$name (yangilangan)" }) -ContentType 'application/json').data
Check ($upd.isOpen -eq $false) "tahrir: isOpen=false"
Check ($upd.name -eq "$name (yangilangan)") "tahrir: nom yangilandi"

# 5) BLOCKED qilsak public ro'yxatdan yo'qoladi
Invoke-RestMethod "$rest/restaurants/$rid" -Method Patch -Headers $ah -Body (J @{ status = 'BLOCKED' }) -ContentType 'application/json' | Out-Null
$public2 = (Invoke-RestMethod "$rest/restaurants").data
Check (($public2 | Where-Object { $_.id -eq $rid }) -eq $null) "BLOCKED -> public ro'yxatda yo'q"
# manage/all da hali ko'rinadi
$all2 = (Invoke-RestMethod "$rest/restaurants/manage/all" -Headers $ah).data
Check (($all2 | Where-Object { $_.id -eq $rid }) -ne $null) "BLOCKED -> manage/all da bor"

# 6) Ega biriktirish -> ega /mine da ko'radi
$ownerU = Login '+998907777777'
Invoke-RestMethod "$auth/auth/admin/users/$($ownerU.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('restaurant') }) -ContentType 'application/json' | Out-Null
Invoke-RestMethod "$rest/restaurants/$rid/owner" -Method Patch -Headers $ah -Body (J @{ ownerUserId = $ownerU.user.id }) -ContentType 'application/json' | Out-Null
$owner = Login '+998907777777'
$mine = (Invoke-RestMethod "$rest/restaurants/mine" -Headers (Hdr $owner.accessToken)).data
Check (($mine | Where-Object { $_.id -eq $rid }) -ne $null) "ega /mine da yangi oshxonani ko'radi"

# 7) Himoya: mijoz yarata olmaydi -> 403
$cust = Login '+998901111111'
Check (Status 403 { Invoke-RestMethod "$rest/restaurants" -Method Post -Headers (Hdr $cust.accessToken) -Body (J @{ name = 'X'; address = 'Yyy'; phone = '+998900000001' }) -ContentType 'application/json' | Out-Null }) "mijoz oshxona yaratish -> 403"

# 8) Tokensiz manage/all -> 401
Check (Status 401 { Invoke-RestMethod "$rest/restaurants/manage/all" | Out-Null }) "tokensiz manage/all -> 401"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
