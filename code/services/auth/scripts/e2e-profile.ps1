$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'

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

Wait-Up $auth 'auth'

# Toza foydalanuvchi
$phone = '+99890' + (Get-Random -Minimum 1000000 -Maximum 9999999)
$u = Login $phone; $h = Hdr $u.accessToken

# 1) Profil: ism o'rnatish
$prof = (Invoke-RestMethod "$auth/profile" -Method Patch -Headers $h -Body (J @{ fullName = 'Ali Valiyev' }) -ContentType 'application/json').data
Check ($prof.fullName -eq 'Ali Valiyev') "Profil: fullName saqlandi"

# 2) Boshlang'ich manzillar bo'sh
$empty = (Invoke-RestMethod "$auth/profile/addresses" -Headers $h).data
Check ($empty.Count -eq 0) "Boshlang'ich manzillar bo'sh"

# 3) Birinchi manzil -> avtomatik standart
$a1 = (Invoke-RestMethod "$auth/profile/addresses" -Method Post -Headers $h -Body (J @{ label = 'Uy'; text = 'Beshariq, Markaziy 1' }) -ContentType 'application/json').data
Check ($a1.isDefault -eq $true) "Birinchi manzil avtomatik standart"

# 4) Ikkinchi manzil (standart emas)
$a2 = (Invoke-RestMethod "$auth/profile/addresses" -Method Post -Headers $h -Body (J @{ label = 'Ish'; text = 'Beshariq, Sanoat 5' }) -ContentType 'application/json').data
Check ($a2.isDefault -eq $false) "Ikkinchi manzil standart emas"

# 5) Ikkinchini standart qilamiz -> birinchi standart bo'lmaydi
Invoke-RestMethod "$auth/profile/addresses/$($a2.id)" -Method Patch -Headers $h -Body (J @{ isDefault = $true }) -ContentType 'application/json' | Out-Null
$list = (Invoke-RestMethod "$auth/profile/addresses" -Headers $h).data
# @(...) — bitta natija ham massiv bo'lsin (PowerShell skalyar .Count muammosi)
$def = @($list | Where-Object { $_.isDefault -eq $true })
Check ($def.Count -eq 1) "Faqat bitta standart manzil"
Check ($def[0].id -eq $a2.id) "Standart = ikkinchi manzil"

# 6) Begona foydalanuvchi boshqaning manzilini o'chira olmaydi -> 403
$other = Login ('+99890' + (Get-Random -Minimum 1000000 -Maximum 9999999))
Check (Status 403 { Invoke-RestMethod "$auth/profile/addresses/$($a1.id)" -Method Delete -Headers (Hdr $other.accessToken) | Out-Null }) "Begona manzilni o'chirish -> 403"

# 7) Egasi o'chiradi
Invoke-RestMethod "$auth/profile/addresses/$($a1.id)" -Method Delete -Headers $h | Out-Null
$after = (Invoke-RestMethod "$auth/profile/addresses" -Headers $h).data
Check ($after.Count -eq 1) "O'chirgandan keyin 1 manzil qoldi"
Check (($after | Where-Object { $_.id -eq $a1.id }) -eq $null) "O'chirilgan manzil yo'q"

# 8) Avtorizatsiyasiz -> 401
Check (Status 401 { Invoke-RestMethod "$auth/profile/addresses" | Out-Null }) "Tokensiz -> 401"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
