$ErrorActionPreference = 'Stop'
$gw = 'http://localhost:4000/api/v1'

function Wait-Up($url, $name) {
  for ($i = 0; $i -lt 90; $i++) {
    try { Invoke-RestMethod $url -TimeoutSec 2 | Out-Null; Write-Host "[up] $name"; return }
    catch { Start-Sleep -Milliseconds 1000 }
  }
  throw "ko'tarilmadi: $name"
}
function J($o) { $o | ConvertTo-Json -Depth 8 }
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

# Gateway o'z health (gateway ko'tarilganini kutamiz)
Wait-Up "$gw/health" 'gateway'

# Gateway orqali to'liq oqim: login -> apply -> mine
$phone = '+99890' + (Get-Random -Minimum 1000000 -Maximum 9999999)
$r = Invoke-RestMethod "$gw/auth/otp/request" -Method Post -Body (J @{ phone = $phone }) -ContentType 'application/json'
$v = Invoke-RestMethod "$gw/auth/otp/verify" -Method Post -Body (J @{ phone = $phone; code = $r.data.devCode }) -ContentType 'application/json'
$tok = $v.data.accessToken
$h = @{ Authorization = "Bearer $tok" }

$app = (Invoke-RestMethod "$gw/partners/apply" -Method Post -Headers $h `
  -Body (J @{ fullName = 'Gateway Test'; type = 'RESTAURANT' }) -ContentType 'application/json').data
Check ($app.status -eq 'PENDING') "Gateway orqali ariza yaratildi (PENDING)"

$mine = (Invoke-RestMethod "$gw/partners/mine" -Headers $h).data
Check (($mine | Where-Object { $_.id -eq $app.id }) -ne $null) "Gateway orqali /partners/mine ishladi"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== GATEWAY SMOKE O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
