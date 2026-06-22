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

# Haydovchi roli
$dphone = '+99890' + (Get-Random -Minimum 7000000 -Maximum 7999999)
$drv0 = Login $dphone
Invoke-RestMethod "$auth/auth/admin/users/$($drv0.user.id)/roles" -Method Patch -Headers $ah -Body (J @{ roles = @('driver') }) -ContentType 'application/json' | Out-Null
$drv = Login $dphone; $dh = Hdr $drv.accessToken
$cust = Login '+998901111111'; $ch = Hdr $cust.accessToken
$cust2 = Login '+998902222222'; $ch2 = Hdr $cust2.accessToken

$pickup = @{ text = 'Markaz'; lat = 40.4236; lng = 70.6094 }
$dest   = @{ text = 'Chekka'; lat = 40.5000; lng = 70.7000 }

function NewTrip { (Invoke-RestMethod "$ord/taxi/request" -Method Post -Headers $ch -Body (J @{ pickup = $pickup; destination = $dest }) -ContentType 'application/json').data }
function Send($hdr, $id, $text) { (Invoke-RestMethod "$ord/taxi/$id/messages" -Method Post -Headers $hdr -Body (J @{ text = $text }) -ContentType 'application/json').data }
function ListMsg($hdr, $id) { (Invoke-RestMethod "$ord/taxi/$id/messages" -Headers $hdr).data }

# ============ 1) Asosiy suhbat oqimi ============
$t1 = NewTrip

# Haydovchi biriktirilmaguncha yozib bo'lmaydi
Check (Status 400 { Send $ch $t1.id 'salom' | Out-Null }) "Haydovchisiz xabar -> 400"

Invoke-RestMethod "$ord/taxi/driver/trips/$($t1.id)/accept" -Method Post -Headers $dh | Out-Null

# Mijozning BIRINCHI xabari -> majburiy salom qo'shiladi
$m1 = Send $ch $t1.id 'Qayerdasiz?'
Check ($m1.text -eq 'Assalomu alaykum, Qayerdasiz?') "Birinchi xabar oldidan 'Assalomu alaykum, ' qo'shildi"
Check ($m1.senderRole -eq 'customer') "Birinchi xabar roli = customer"

# Ikkinchi xabar (haydovchi) -> salom QO'SHILMAYDI
$m2 = Send $dh $t1.id 'Yetib keldim'
Check ($m2.text -eq 'Yetib keldim') "Ikkinchi xabarga salom qo'shilmadi"
Check ($m2.senderRole -eq 'driver') "Ikkinchi xabar roli = driver"

# Ro'yxat: ikkala tomon ham o'qiy oladi, vaqt bo'yicha
$lm = ListMsg $ch $t1.id
Check ($lm.Count -eq 2) "Mijoz ro'yxati: 2 xabar"
Check ($lm[0].text -eq 'Assalomu alaykum, Qayerdasiz?') "Tartib: 1-xabar mijoznidan"
Check ($lm[1].text -eq 'Yetib keldim') "Tartib: 2-xabar haydovchidan"
$ld = ListMsg $dh $t1.id
Check ($ld.Count -eq 2) "Haydovchi ham suhbatni o'qiydi: 2 xabar"

# Begona foydalanuvchi -> 403
Check (Status 403 { ListMsg $ch2 $t1.id | Out-Null }) "Begona o'qishi -> 403"
Check (Status 403 { Send $ch2 $t1.id 'kim bu' | Out-Null }) "Begona yozishi -> 403"

# Bo'sh matn -> 400 (validatsiya)
Check (Status 400 { Send $ch $t1.id '' | Out-Null }) "Bo'sh matn -> 400"

# Yakunlangach yozib bo'lmaydi
Invoke-RestMethod "$ord/taxi/driver/trips/$($t1.id)/start" -Method Post -Headers $dh | Out-Null
Invoke-RestMethod "$ord/taxi/driver/trips/$($t1.id)/complete" -Method Post -Headers $dh -Body (J @{}) -ContentType 'application/json' | Out-Null
Check (Status 400 { Send $ch $t1.id 'rahmat' | Out-Null }) "Yakunlangan safarda xabar -> 400"

# ============ 2) Haydovchi birinchi yozsa ham salom qo'shiladi ============
$t2 = NewTrip
Invoke-RestMethod "$ord/taxi/driver/trips/$($t2.id)/accept" -Method Post -Headers $dh | Out-Null
$dm = Send $dh $t2.id "Yo'ldaman"
Check ($dm.text -eq "Assalomu alaykum, Yo'ldaman") "Haydovchining birinchi xabariga ham salom qo'shildi"

# ============ 3) Allaqachon salom bilan boshlansa — takrorlanmaydi ============
$t3 = NewTrip
Invoke-RestMethod "$ord/taxi/driver/trips/$($t3.id)/accept" -Method Post -Headers $dh | Out-Null
$gm = Send $ch $t3.id 'Assalomu alaykum, rahmat'
Check ($gm.text -eq 'Assalomu alaykum, rahmat') "Salom takrorlanmadi (allaqachon bor)"

Write-Host ""
if ($fail -eq 0) { Write-Host "==== HAMMA TEST O'TDI ✅ ====" -ForegroundColor Green }
else { Write-Host "==== $fail YIQILDI ❌ ====" -ForegroundColor Red; exit 1 }
