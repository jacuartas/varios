# setup-powershell-environment.ps1
# Configuración automática del entorno PowerShell

Write-Host "🔧 Configurando entorno PowerShell para scripts personalizados..." -ForegroundColor Cyan

# Verificar política actual
$currentPolicy = Get-ExecutionPolicy
Write-Host "📋 Política actual: $currentPolicy" -ForegroundColor Yellow

if ($currentPolicy -eq 'Restricted') {
    Write-Host "⚙️  Cambiando política de ejecución a RemoteSigned..." -ForegroundColor Yellow
    
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✅ Política cambiada exitosamente" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error al cambiar política: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Ejecuta PowerShell como Administrador si el problema persiste" -ForegroundColor Cyan
        exit 1
    }
} else {
    Write-Host "✅ Política de ejecución ya configurada correctamente" -ForegroundColor Green
}

# Desbloquear scripts en directorio del usuario
$scriptsPath = "$env:USERPROFILE\scripts"
if (Test-Path $scriptsPath) {
    Write-Host "🔓 Desbloqueando scripts en: $scriptsPath" -ForegroundColor Yellow
    
    $scriptFiles = Get-ChildItem -Path $scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
    
    if ($scriptFiles) {
        foreach ($file in $scriptFiles) {
            try {
                Unblock-File -Path $file.FullName
                Write-Host "  ✅ $($file.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "  ⚠️  No se pudo desbloquear: $($file.Name)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "ℹ️  No se encontraron archivos .ps1 en $scriptsPath" -ForegroundColor Blue
    }
} else {
    Write-Host "📁 Creando directorio de scripts: $scriptsPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
    Write-Host "✅ Directorio creado" -ForegroundColor Green
}

# Mostrar estado final
Write-Host "`n📊 Estado final:" -ForegroundColor Cyan
Get-ExecutionPolicy -List | Format-Table

Write-Host "🎉 ¡Configuración completada!" -ForegroundColor Green
Write-Host "`n💡 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   Get-ExecutionPolicy -List    # Ver políticas" -ForegroundColor White
Write-Host "   Unblock-File script.ps1      # Desbloquear script específico" -ForegroundColor White

# Verificar si existe el script de sync
$syncScript = "$scriptsPath\sync-settings-from-github.ps1"
if (Test-Path $syncScript) {
    Write-Host "`n🚀 Probando script de sincronización..." -ForegroundColor Yellow
    try {
        & $syncScript -WhatIf 2>$null
        Write-Host "✅ Script ejecutable correctamente" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Script requiere ajustes adicionales" -ForegroundColor Yellow
    }
}