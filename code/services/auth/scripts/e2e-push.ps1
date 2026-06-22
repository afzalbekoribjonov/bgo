$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'
$internalKey = 'dev_internal_key'

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
$cust = Login '+998901234567'; $ch = Hdr $cust.accessToken
$uid = $cust.user.id
$tokA = 'fcm-token-A-' + (Get-Random)
$tokB = 'fcm-token-B-' + (Get-Random)

# Boshlanishi: bu foydalanuvchining oldingi tokenlarini tozalaymiz (idempotent test)
foreach ($t in (Invoke-RestMethod "$auth/profile/device-tokens" -Headers $ch).data) {
  Invoke-RestMethod "$auth/profile/device-token/remove" -Method Post -Headers $ch -Body (J @{ token = $t.token }) -ContentType 'application/json' | Out-Null
}
$start = (Invoke-RestMethod "$auth/profile/device-tokens" -Headers $ch).data
Check ($start.Count -eq 0) "Boshlanishida token yo'q"

# ---- Ro'yxatga olish ----
$rA = (Invoke-RestMethod "$auth/profile/device-token" -Method Post -Headers $ch -Body (J @{ token = $tokA; platform = 'android' }) -ContentType 'application/json').data
Check ($rA.token -eq $tokA) "Token A ro'yxatga olindi"
Check ($rA.platform -eq 'android') "Platforma = android"
Check ($rA.userId -eq $uid) "Token egasi = foydalanuvchi"

Invoke-RestMethod "$auth/profile/device-token" -Method Post -Headers $ch -Body (J @{ token = $tokB; platform = 'ios' }) -ContentType 'application/json' | Out-Null
$list2 = (Invoke-RestMethod "$auth/profile/device-tokens" -Headers $ch).data
Check ($list2.Count -eq 2) "Ikki qurilma ro'yxatda"

# Qayta ro'yxat (upsert) — dublikat bo'lmaydi
Invoke-RestMethod "$auth/profile/device-token" -Method Post -Headers $ch -Body (J @{ token = $tokA; platform = 'android' }) -ContentType 'application/json' | Out-Null
$list2b = (Invoke-RestMethod "$auth/profile/device-tokens" -Headers $ch).data
Check ($list2b.Count -eq 2) "Qayta ro'yxat dublikat yaratmadi"

# ---- Internal send himoyasi ----
$noKey = $false
try { Invoke-RestMethod "$auth/internal/notifications/send" -Method Post -Body (J @{ userId = $uid; title = 'x'; body = 'y' }) -ContentType 'application/json' | Out-Null }
catch { $code = $_.Exception.Response.StatusCode.value__; $noKey = ($code -eq 401 -or $code -eq 503) }
Check $noKey "Internal: kalit yo'q -> rad (401/503)"

$badKey = $false
try {
  Invoke-RestMethod "$auth/internal/notifications/send" -Method Post -Headers @{ 'x-internal-key' = 'wrong' } -Body (J @{ userId = $uid; title = 'x'; body = 'y' }) -ContentType 'application/json' | Out-Null
} catch { $badKey = ($_.Exception.Response.StatusCode.value__ -eq 401) }
Check $badKey "Internal: noto'g'ri kalit -> 401"

# ---- Internal send (dev rejim) ----
$ihdr = @{ 'x-internal-key' = $internalKey }
$send = (Invoke-RestMethod "$auth/internal/notifications/send" -Method Post -Headers $ihdr -Body (J @{ userId = $uid; title = 'Buyurtma qabul qilindi'; body = 'Haydovchi yo''lda'; data = @{ type = 'order'; id = '123' } }) -ContentType 'application/json').data
Check ($send.delivered -eq 2) "Push 2 qurilmaga yetkazildi (dev)"
Check ($send.channel -eq 'dev') "Kanal = dev (FCM_DEV_MODE)"

# ---- Tokenni o'chirish ----
Invoke-RestMethod "$auth/profile/device-token/remove" -Method Post -Headers $ch -Body (J @{ token = $tokA }) -ContentType 'application/json' | Out-Null
$list1 = (Invoke-RestMethod "$auth/profile/device-tokens" -Headers $ch).data
Check ($list1.Count -eq 1) "Token o'chirildi -> 1 qoldi"
$send1 = (Invoke-RestMethod "$auth/internal/notifications/send" -Method Post -Headers $ihdr -Body (J @{ userId = $uid; title = 't'; body = 'b' }) -ContentType 'application/json').data
Check ($send1.delivered -eq 1) "O'chirgandan keyin 1 qurilmaga"

# ---- Tokensiz foydalanuvchi ----
$send0 = (Invoke-RestMethod "$auth/internal/notifications/send" -Method Post -Headers $ihdr -Body (J @{ userId = ('no-such-' + (Get-Random)); title = 't'; body = 'b' }) -ContentType 'application/json').data
Check ($send0.delivered -eq 0 -and $send0.channel -eq 'none') "Tokensiz foydalanuvchi -> delivered=0, none"

# ---- Auth himoyasi ----
Check (Status 401 { Invoke-RestMethod "$auth/profile/device-tokens" | Out-Null }) "Tokensiz /profile/device-tokens -> 401"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
