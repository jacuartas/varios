oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/jacuartas/varios/main/cv/clean-tokyo.omp.json' | Invoke-Expression
Import-Module -Name Terminal-Icons
# === TERMINAL SYNC FUNCTIONS ===
function Sync-TerminalSettings {
    param([switch]$Check, [switch]$Force)
    & "C:\Users\Jose Cuartas\scripts\sync-settings-from-github.ps1" @PSBoundParameters
}

Set-Alias -Name "sync-terminal" -Value Sync-TerminalSettings
Set-Alias -Name "st-sync" -Value Sync-TerminalSettings

Write-Host "💡 Comandos disponibles: sync-terminal, st-sync" -ForegroundColor DarkGray
