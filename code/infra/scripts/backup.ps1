# Beshariq DB zaxirasi — uchala baza bir vaqtda
# Ishlatish:  .\backup.ps1
# Yoki avtomatik: Task Scheduler yoki Windows'da rejalashtirilgan vazifa

param(
    [string]$Host     = "localhost",
    [string]$Port     = "5432",
    [string]$User     = "beshariq",
    [string]$Password = "beshariq_dev_password",
    [string]$OutDir   = "$PSScriptRoot\..\..\backups"
)

$env:PGPASSWORD = $Password
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$dir   = Join-Path $OutDir $stamp

New-Item -ItemType Directory -Force -Path $dir | Out-Null

$databases = @("auth_db", "restaurant_db", "order_db")

foreach ($db in $databases) {
    $file = Join-Path $dir "$db.sql"
    Write-Host "Zaxiralash: $db -> $file"
    & pg_dump -h $Host -p $Port -U $User -F plain -f $file $db
    if ($LASTEXITCODE -ne 0) {
        Write-Error "XATO: $db zaxiralanmadi!"
        exit 1
    }
}

# Eski zaxiralarni tozalash: 30 kundan eski papkalar o'chiriladi
Get-ChildItem $OutDir -Directory |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Recurse -Force

Write-Host ""
Write-Host "Zaxira muvaffaqiyatli: $dir"
Write-Host "Fayllar: $($databases | ForEach-Object { "$_.sql" })"
