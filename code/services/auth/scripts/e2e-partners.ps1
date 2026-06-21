$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'

function Wait-Up($base, $name) {
  for ($i = 0; $i -lt 90; $i++) {
    try { Invoke-RestMethod "$base/health" -TimeoutSec 2 | Out-Null; Write-Host "[up] $name"; return }
    catch { Start-Sleep -Milliseconds 1000 }
  }
  throw "Servis ko'tarilmadi: $name"
}
function J($o) { $o | ConvertTo-Json -Depth 8 }
function Login($phone) {
  $r = Invoke-RestMethod "$auth/auth/otp/request" -Method Post -Body (J @{ phone = $phone }) -ContentType 'application/json'
  $v = Invoke-RestMethod "$auth/auth/otp/verify" -Method Post -Body (J @{ phone = $phone; code = $r.data.devCode }) -ContentType 'application/json'
  return $v.data
}
function Hdr($t) { return @{ Authorization = "Bearer $t" } }
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

Wait-Up $auth 'auth'

# Yangi (toza) raqam — har ishga tushirishda unikal
$phone = '+99890' + (Get-Random -Minimum 1000000 -Maximum 9999999)
$cust = Login $phone
Check ($cust.user.roles -notcontains 'driver') "Boshda 'driver' roli yo'q"

# 1) Ariza yuborish
$app = (Invoke-RestMethod "$auth/partners/apply" -Method Post -Headers (Hdr $cust.accessToken) `
  -Body (J @{ fullName = 'Ali Valiyev'; type = 'DRIVER'; note = 'Mashinam bor' }) -ContentType 'application/json').data
Check ($app.status -eq 'PENDING') "Ariza PENDING holatda"
Check ($app.type -eq 'DRIVER') "Ariza turi DRIVER"
$aid = $app.id

# 2) Takroriy ariza -> 400
$dup = $false
try { Invoke-RestMethod "$auth/partners/apply" -Method Post -Headers (Hdr $cust.accessToken) `
  -Body (J @{ fullName = 'Ali Valiyev'; type = 'DRIVER' }) -ContentType 'application/json' | Out-Null }
catch { if ($_.Exception.Response.StatusCode.value__ -eq 400) { $dup = $true } }
Check $dup "Takroriy PENDING ariza rad etildi (400)"

# 3) Mening arizalarim
$mine = (Invoke-RestMethod "$auth/partners/mine" -Headers (Hdr $cust.accessToken)).data
Check (($mine | Where-Object { $_.id -eq $aid }) -ne $null) "Ariza /partners/mine da bor"

# 4) Admin ro'yxati (PENDING)
$admin = Login '+998900000000'
Check ($admin.user.roles -contains 'admin') "Admin roli bor"
$pend = (Invoke-RestMethod "$auth/auth/admin/partners?status=PENDING" -Headers (Hdr $admin.accessToken)).data
Check (($pend | Where-Object { $_.id -eq $aid }) -ne $null) "Admin PENDING ro'yxatida ariza bor"

# 5) Begona (mijoz) admin ro'yxatga kira olmasligi -> 403
$forbidden = $false
try { Invoke-RestMethod "$auth/auth/admin/partners" -Headers (Hdr $cust.accessToken) | Out-Null }
catch { if ($_.Exception.Response.StatusCode.value__ -eq 403) { $forbidden = $true } }
Check $forbidden "Mijoz admin ro'yxatiga 403"

# 6) Tasdiqlash -> rol beriladi
$appr = (Invoke-RestMethod "$auth/auth/admin/partners/$aid" -Method Patch -Headers (Hdr $admin.accessToken) `
  -Body (J @{ status = 'APPROVED' }) -ContentType 'application/json').data
Check ($appr.status -eq 'APPROVED') "Ariza APPROVED"

# 7) Mijoz qayta login -> 'driver' roli paydo bo'ldi
$cust2 = Login $phone
Check ($cust2.user.roles -contains 'driver') "Tasdiqdan keyin 'driver' roli berildi"

# 8) Ko'rib chiqilgan arizani qayta o'zgartirish -> 400
$again = $false
try { Invoke-RestMethod "$auth/auth/admin/partners/$aid" -Method Patch -Headers (Hdr $admin.accessToken) `
  -Body (J @{ status = 'REJECTED' }) -ContentType 'application/json' | Out-Null }
catch { if ($_.Exception.Response.StatusCode.value__ -eq 400) { $again = $true } }
Check $again "Ko'rib chiqilgan arizani qayta o'zgartirib bo'lmaydi (400)"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail ta TEST YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
