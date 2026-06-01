$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    if ($PSCommandPath) {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/mashan16/scripts/main/Windows/win11_classic_menu.ps1')`""
    }
    return
}

Write-Host "=== Win11 Classic Context Menu ===" -ForegroundColor Cyan

reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /f | Out-Null

Write-Host "Registry key created." -ForegroundColor Green

Write-Host "=== Restarting Explorer ===" -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Wait-Process -Name explorer -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Process explorer

Write-Host "=== Done! ===" -ForegroundColor Green

if ($PSCommandPath) {
    Read-Host "Press Enter to exit"
}