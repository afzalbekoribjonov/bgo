# Beshariq DB ni zaxiradan tiklash
# Ishlatish:  .\restore.ps1 -BackupDir backups\2026-07-03_14-00
# DIQQAT: bu mavjud ma'lumotni TOZALAB qayta yozadi!

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupDir,
    [string]$Host     = "localhost",
    [string]$Port     = "5432",
    [string]$User     = "beshariq",
    [string]$Password = "beshariq_dev_password"
)

$env:PGPASSWORD = $Password
$databases = @("auth_db", "restaurant_db", "order_db")

Write-Host "DIQQAT: Mavjud ma'lumotlar o'chiriladi va '$BackupDir' dan tiklanadi."
$confirm = Read-Host "Davom etishni xohlaysizmi? (ha/yo'q)"
if ($confirm -ne "ha") { Write-Host "Bekor qilindi."; exit 0 }

foreach ($db in $databases) {
    $file = Join-Path $BackupDir "$db.sql"
    if (-not (Test-Path $file)) {
        Write-Warning "Fayl topilmadi: $file — o'tkazildi."
        continue
    }
    Write-Host "Tiklash: $file -> $db"
    & psql -h $Host -p $Port -U $User -d $db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" 2>$null
    & psql -h $Host -p $Port -U $User -d $db -f $file
    if ($LASTEXITCODE -ne 0) {
        Write-Error "XATO: $db tiklanmadi!"
        exit 1
    }
}

Write-Host ""
Write-Host "Tiklash muvaffaqiyatli yakunlandi."
