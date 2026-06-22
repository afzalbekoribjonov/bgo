$ErrorActionPreference = 'Stop'
$auth = 'http://localhost:4001/api/v1'
$ord  = 'http://localhost:4004/api/v1'
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
$fail = 0
function Check($c, $m) { if ($c) { Write-Host "  PASS: $m" } else { Write-Host "  FAIL: $m" -ForegroundColor Red; $script:fail++ } }

# Auth internal: foydalanuvchiga yuborilgan push xabarlar (dev introspeksiya)
function Recent($uid) {
  return (Invoke-RestMethod "$auth/internal/notifications/recent?userId=$uid" -Headers @{ 'x-internal-key' = $internalKey }).data
}
function HasTitle($uid, $needle) {
  return @(Recent $uid | Where-Object { $_.title -like "*$needle*" }).Count -ge 1
}
function HasBody($uid, $needle) {
  return @(Recent $uid | Where-Object { $_.body -like "*$needle*" }).Count -ge 1
}

Wait-Up $auth 'auth'; Wait-Up $ord 'order'
$admin = Login '+998900000000'; $ah = Hdr $admin.accessToken

# Haydovchi + mijoz
$dphone = '+99890' + (Get-Random -Minimum 7000000 -Maximum 7999999)
$d0 = Login $dphone
Invoke-RestMethod "$auth/auth/admin/users/$($d0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$drv = Login $dphone; $dh = Hdr $drv.accessToken
$cphone = '+99890' + (Get-Random -Minimum 1000000 -Maximum 1999999)
$cust = Login $cphone; $ch = Hdr $cust.accessToken
$cid = $cust.user.id; $did = $drv.user.id

# Qurilma tokenlari (delivered > 0 bo'lishi uchun)
Invoke-RestMethod "$auth/profile/device-token" -Method Post -Headers $ch -Body (J @{ token = 'cust-' + (Get-Random) }) -ContentType 'application/json' | Out-Null
Invoke-RestMethod "$auth/profile/device-token" -Method Post -Headers $dh -Body (J @{ token = 'drv-' + (Get-Random) }) -ContentType 'application/json' | Out-Null

$pickup = @{ text = 'Markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka'; lat = 40.5000; lng = 70.7000 }

# ============ TAKSI ============
$t = (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data
Invoke-RestMethod "$ord/taxi/driver/trips/$($t.id)/accept" -Method Post -Headers $dh | Out-Null
Check (HasBody $cid 'Haydovchi qabul') "Taksi qabul -> mijozga push"
$last = (Recent $cid | Select-Object -Last 1)
Check ($last.delivered -ge 1) "Push qurilmaga yetkazildi (delivered>=1)"

Invoke-RestMethod "$ord/taxi/driver/trips/$($t.id)/start" -Method Post -Headers $dh | Out-Null
Check (HasBody $cid 'Safar boshlandi') "Taksi start -> mijozga push"

# Chat: mijoz yozadi -> haydovchiga; haydovchi yozadi -> mijozga
Check (-not (HasTitle $did 'Yangi xabar')) "Boshida haydovchida 'Yangi xabar' yo'q"
Invoke-RestMethod "$ord/taxi/$($t.id)/messages" -Method Post -Headers $ch -Body (J @{ text = 'qayerdasiz' }) -ContentType 'application/json' | Out-Null
Check (HasTitle $did 'Yangi xabar') "Mijoz xabari -> haydovchiga push"
Invoke-RestMethod "$ord/taxi/$($t.id)/messages" -Method Post -Headers $dh -Body (J @{ text = 'yetib keldim' }) -ContentType 'application/json' | Out-Null
Check (HasTitle $cid 'Yangi xabar') "Haydovchi xabari -> mijozga push"

Invoke-RestMethod "$ord/taxi/driver/trips/$($t.id)/complete" -Method Post -Headers $dh -Body (J @{}) -ContentType 'application/json' | Out-Null
Check (HasBody $cid 'Safar yakunlandi') "Taksi yakun -> mijozga push"

# ============ DOSTAVKA ============
$p = (Invoke-RestMethod "$ord/parcel/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest; size = 'SMALL'; recipientName = 'Vali'; recipientPhone = '+998901112233' }) -ContentType 'application/json').data
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($p.id)/accept" -Method Post -Headers $dh | Out-Null
Check (HasBody $cid 'Kuryer dostavkani qabul') "Dostavka qabul -> mijozga push"
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($p.id)/pickup" -Method Post -Headers $dh | Out-Null
Check (HasBody $cid 'posilkani oldi') "Dostavka olindi -> mijozga push"
Invoke-RestMethod "$ord/parcel/driver/deliveries/$($p.id)/delivered" -Method Post -Headers $dh | Out-Null
Check (HasBody $cid 'Posilka yetkazildi') "Dostavka yetkazildi -> mijozga push"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
