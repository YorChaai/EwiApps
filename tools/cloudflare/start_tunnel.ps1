param(
    [string]$Url = "http://localhost:5000"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $scriptDir "cloudflared.exe"

if (-not (Test-Path $exe)) {
    Write-Host "[ERROR] cloudflared.exe tidak ditemukan di $scriptDir" -ForegroundColor Red
    exit 1
}

Write-Host "[*] Menjalankan Cloudflare Tunnel..." -ForegroundColor Cyan
Write-Host "[i] Target lokal : $Url" -ForegroundColor Yellow
Write-Host "[i] Copy URL https://....trycloudflare.com lalu tambahkan /api di aplikasi Android." -ForegroundColor Yellow
Write-Host "[!] Jangan tutup jendela ini selama tunnel dipakai." -ForegroundColor Red
Write-Host ""

& $exe tunnel --url $Url
