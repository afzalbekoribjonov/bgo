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
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

Wait-Up $auth 'auth'

# Toza raqam + unga mos Telegram chatId
$digits = '99890' + (Get-Random -Minimum 5000000 -Maximum 5999999)
$phone = '+' + $digits
$chatId = Get-Random -Minimum 100000 -Maximum 999999

# 1) /start webhook — xato bermasligi kerak
$start = Invoke-RestMethod "$auth/auth/telegram/webhook" -Method Post -ContentType 'application/json' -Body (J @{
  message = @{ chat = @{ id = $chatId }; from = @{ id = $chatId; username = 'testuser' }; text = '/start' }
})
Check ($start.ok -eq $true) "/start webhook ok"

# 2) Raqamni ulash (contact share) — link saqlanadi
Invoke-RestMethod "$auth/auth/telegram/webhook" -Method Post -ContentType 'application/json' -Body (J @{
  message = @{
    chat = @{ id = $chatId }; from = @{ id = $chatId; username = 'testuser' }
    contact = @{ phone_number = $digits; user_id = $chatId }
  }
}) | Out-Null

# 3) OTP so'rash — endi Telegram kanali ishlatilishi kerak
$req = (Invoke-RestMethod "$auth/auth/otp/request" -Method Post -ContentType 'application/json' -Body (J @{ phone = $phone })).data
Write-Host "request (linked): $(J $req)"
Check ($req.channel -eq 'telegram') "Ulangan raqam -> kanal=telegram"
Check ($null -ne $req.devCode) "devCode mavjud (dev rejim)"

# 4) Tasdiqlash ishlaydi
$ver = (Invoke-RestMethod "$auth/auth/otp/verify" -Method Post -ContentType 'application/json' -Body (J @{ phone = $phone; code = $req.devCode })).data
Check ($null -ne $ver.accessToken) "Telegram kanali kodi bilan tasdiqlash ishladi"

# 5) Ulanmagan raqam -> SMS zaxira + bot havolasi
$phone2 = '+99890' + (Get-Random -Minimum 6000000 -Maximum 6999999)
$req2 = (Invoke-RestMethod "$auth/auth/otp/request" -Method Post -ContentType 'application/json' -Body (J @{ phone = $phone2 })).data
Write-Host "request (unlinked): $(J $req2)"
Check ($req2.channel -eq 'sms') "Ulanmagan raqam -> kanal=sms (zaxira)"
Check ($req2.telegramBotUrl -like 'https://t.me/*') "SMS javobida bot havolasi (bepul kanal taklifi)"

# 6) Begona raqam ulashi rad etiladi (contact.user_id != from.id)
$chatId3 = Get-Random -Minimum 100000 -Maximum 999999
Invoke-RestMethod "$auth/auth/telegram/webhook" -Method Post -ContentType 'application/json' -Body (J @{
  message = @{
    chat = @{ id = $chatId3 }; from = @{ id = $chatId3 }
    contact = @{ phone_number = '998901234999'; user_id = 111111 }
  }
}) | Out-Null
$req3 = (Invoke-RestMethod "$auth/auth/otp/request" -Method Post -ContentType 'application/json' -Body (J @{ phone = '+998901234999' })).data
Check ($req3.channel -eq 'sms') "Begona raqam ulanmadi -> sms"

# 7) Bo'sh/yaroqsiz webhook -> xatosiz ok
$empty = Invoke-RestMethod "$auth/auth/telegram/webhook" -Method Post -ContentType 'application/json' -Body (J @{ foo = 'bar' })
Check ($empty.ok -eq $true) "Yaroqsiz update -> xatosiz ok"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
