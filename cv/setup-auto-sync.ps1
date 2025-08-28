# setup-auto-sync.ps1 - Configuración automática de sincronización
# Ejecuta una sola vez para configurar todo

Write-Host "🚀 Configurando sincronización automática de PowerShell..." -ForegroundColor Cyan

# URLs de configuración
$BaseUrl = "https://raw.githubusercontent.com/jacuartas/varios/main/cv"
$SyncScriptUrl = "$BaseUrl/sync-settings-from-github.ps1"
$ProfileUrl = "$BaseUrl/Microsoft.PowerShell_profile.ps1"
$SettingsUrl = "$BaseUrl/settings.json"
$ThemeUrl = "$BaseUrl/clean-tokyo.omp.json"

# Rutas locales
$ScriptsDir = "$env:USERPROFILE\scripts"
$LocalSyncScript = "$ScriptsDir\sync-settings-from-github.ps1"
$ProfilePath = $PROFILE

# 1. Configurar política de ejecución
Write-Host "⚙️ Configurando política de ejecución..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. Crear directorio para scripts
Write-Host "📁 Creando directorio de scripts..." -ForegroundColor Yellow
if (!(Test-Path $ScriptsDir)) {
    New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null
}

# 3. Descargar script de sincronización
Write-Host "📥 Descargando script de sincronización..." -ForegroundColor Yellow
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "PowerShell-AutoSync/1.0")
    $syncScriptContent = $webClient.DownloadString($SyncScriptUrl)
    $syncScriptContent | Out-File -FilePath $LocalSyncScript -Encoding UTF8 -Force
    
    # Desbloquear el script
    Unblock-File -Path $LocalSyncScript
    Write-Host "✅ Script de sincronización descargado" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error descargando script: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. Crear perfil de PowerShell con auto-sync
Write-Host "🔧 Configurando perfil de PowerShell..." -ForegroundColor Yellow

$NewProfileContent = @"
# ===== CONFIGURACIÓN AUTO-SYNC POWERSHELL =====
# Configuración automática - No editar manualmente

# Función de sincronización silenciosa
function Invoke-AutoSync {
    param([switch]`$Verbose)
    
    try {
        `$syncScript = "`$env:USERPROFILE\scripts\sync-settings-from-github.ps1"
        
        if (Test-Path `$syncScript) {
            if (`$Verbose) {
                Write-Host "🔄 Sincronizando configuración..." -ForegroundColor Cyan
                & `$syncScript -MultiFile
            } else {
                # Sincronización silenciosa
                & `$syncScript -MultiFile -Silent 2>`$null | Out-Null
            }
        }
    }
    catch {
        # Fallar silenciosamente para no interrumpir el inicio
        if (`$Verbose) {
            Write-Host "⚠️ Error en auto-sync: `$(`$_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Auto-sync al iniciar (silencioso)
Invoke-AutoSync

# Oh My Posh con tema Clean Tokyo
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/jacuartas/varios/main/cv/clean-tokyo.omp.json' | Invoke-Expression
}

# Terminal Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

# Aliases para gestión de configuración
function Sync-AllConfigs { 
    param([switch]`$Force, [switch]`$Check)
    `$params = @{}
    if (`$Force) { `$params.Force = `$true }
    if (`$Check) { `$params.Check = `$true }
    
    & "`$env:USERPROFILE\scripts\sync-settings-from-github.ps1" -MultiFile @params
}

Set-Alias -Name "sync-all" -Value Sync-AllConfigs
Set-Alias -Name "sync-config" -Value Sync-AllConfigs

# Mostrar estado solo la primera vez después de configurar
if (`$env:POWERSHELL_FIRST_RUN) {
    Write-Host "✅ PowerShell configurado con auto-sync" -ForegroundColor Green
    Write-Host "💡 Comandos: sync-all, sync-all -Check, sync-all -Force" -ForegroundColor DarkGray
    Remove-Item Env:\POWERSHELL_FIRST_RUN -ErrorAction SilentlyContinue
}
"@

# Guardar el nuevo perfil
$NewProfileContent | Out-File -FilePath $ProfilePath -Encoding UTF8 -Force
Write-Host "✅ Perfil de PowerShell configurado" -ForegroundColor Green

# 5. Crear versión mejorada del script de sincronización
Write-Host "🔧 Creando script de sincronización multi-archivo..." -ForegroundColor Yellow

$MultiSyncScript = @"
# sync-settings-from-github.ps1 - Versión multi-archivo mejorada
param(
    [string]`$BaseUrl = "https://raw.githubusercontent.com/jacuartas/varios/main/cv",
    [switch]`$MultiFile = `$false,
    [switch]`$Silent = `$false,
    [switch]`$Force = `$false,
    [switch]`$Check = `$false
)

# Configuración de archivos a sincronizar
`$FilesToSync = @(
    @{
        Name = "Windows Terminal Settings"
        Url = "`$BaseUrl/settings.json"
        LocalPath = "`$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        Backup = `$true
    },
    @{
        Name = "PowerShell Profile"
        Url = "`$BaseUrl/Microsoft.PowerShell_profile.ps1"
        LocalPath = `$PROFILE
        Backup = `$true
        SkipIfAutoSync = `$true  # No sobrescribir si tiene auto-sync
    }
)

function Write-Message {
    param([string]`$Message, [string]`$Color = "White")
    if (-not `$Silent) {
        Write-Host `$Message -ForegroundColor `$Color
    }
}

function Test-HasAutoSync {
    param([string]`$FilePath)
    
    if (Test-Path `$FilePath) {
        `$content = Get-Content `$FilePath -Raw -ErrorAction SilentlyContinue
        return (`$content -match "AUTO-SYNC POWERSHELL" -or `$content -match "Invoke-AutoSync")
    }
    return `$false
}

function Sync-ConfigFile {
    param([hashtable]`$FileConfig)
    
    try {
        Write-Message "🔄 Sincronizando: `$(`$FileConfig.Name)..." "Cyan"
        
        # Verificar si debe saltar archivo con auto-sync
        if (`$FileConfig.SkipIfAutoSync -and (Test-HasAutoSync `$FileConfig.LocalPath)) {
            Write-Message "⏭️ Saltando `$(`$FileConfig.Name) (tiene auto-sync configurado)" "Yellow"
            return `$true
        }
        
        # Descargar contenido
        `$webClient = New-Object System.Net.WebClient
        `$webClient.Headers.Add("User-Agent", "PowerShell-MultiSync/1.0")
        `$content = `$webClient.DownloadString(`$FileConfig.Url)
        
        # Validar contenido según tipo de archivo
        if (`$FileConfig.LocalPath -like "*.json") {
            try {
                `$content | ConvertFrom-Json | Out-Null
            }
            catch {
                throw "Contenido JSON inválido"
            }
        }
        
        # Verificar cambios
        if ((Test-Path `$FileConfig.LocalPath) -and -not `$Force) {
            `$currentContent = Get-Content `$FileConfig.LocalPath -Raw -ErrorAction SilentlyContinue
            if (`$currentContent -eq `$content) {
                Write-Message "ℹ️ `$(`$FileConfig.Name) ya está actualizado" "Blue"
                return `$true
            }
        }
        
        # Crear backup si está habilitado
        if (`$FileConfig.Backup -and (Test-Path `$FileConfig.LocalPath)) {
            `$backupPath = "`$(`$FileConfig.LocalPath).backup"
            Copy-Item `$FileConfig.LocalPath `$backupPath -Force -ErrorAction SilentlyContinue
        }
        
        # Crear directorio si no existe
        `$directory = Split-Path `$FileConfig.LocalPath -Parent
        if (-not (Test-Path `$directory)) {
            New-Item -ItemType Directory -Path `$directory -Force | Out-Null
        }
        
        # Guardar archivo
        `$content | Out-File -FilePath `$FileConfig.LocalPath -Encoding UTF8 -Force
        Write-Message "✅ `$(`$FileConfig.Name) actualizado" "Green"
        
        return `$true
    }
    catch {
        Write-Message "❌ Error en `$(`$FileConfig.Name): `$(`$_.Exception.Message)" "Red"
        
        # Restaurar backup si existe
        if (`$FileConfig.Backup) {
            `$backupPath = "`$(`$FileConfig.LocalPath).backup"
            if (Test-Path `$backupPath) {
                Copy-Item `$backupPath `$FileConfig.LocalPath -Force -ErrorAction SilentlyContinue
                Write-Message "🔄 Backup restaurado para `$(`$FileConfig.Name)" "Yellow"
            }
        }
        return `$false
    }
    finally {
        if (`$webClient) { `$webClient.Dispose() }
    }
}

# Modo Check: solo verificar actualizaciones
if (`$Check) {
    Write-Message "🔍 Verificando actualizaciones..." "Cyan"
    `$updatesAvailable = `$false
    
    foreach (`$file in `$FilesToSync) {
        try {
            if (`$file.SkipIfAutoSync -and (Test-HasAutoSync `$file.LocalPath)) { continue }
            
            `$webClient = New-Object System.Net.WebClient
            `$remoteContent = `$webClient.DownloadString(`$file.Url)
            
            if (Test-Path `$file.LocalPath) {
                `$localContent = Get-Content `$file.LocalPath -Raw
                if (`$localContent -ne `$remoteContent) {
                    Write-Message "🆕 `$(`$file.Name) tiene actualizaciones" "Yellow"
                    `$updatesAvailable = `$true
                }
            } else {
                Write-Message "📄 `$(`$file.Name) no existe localmente" "Yellow"
                `$updatesAvailable = `$true
            }
        }
        catch {
            Write-Message "⚠️ Error verificando `$(`$file.Name)" "Red"
        }
        finally {
            if (`$webClient) { `$webClient.Dispose() }
        }
    }
    
    if (-not `$updatesAvailable) {
        Write-Message "✅ Todos los archivos están actualizados" "Green"
    } else {
        Write-Message "💡 Ejecuta 'sync-all' para actualizar" "Cyan"
    }
    return
}

# Sincronización principal
if (`$MultiFile) {
    Write-Message "🚀 Iniciando sincronización multi-archivo..." "Cyan"
    `$successCount = 0
    `$totalCount = `$FilesToSync.Count
    
    foreach (`$file in `$FilesToSync) {
        if (Sync-ConfigFile `$file) {
            `$successCount++
        }
    }
    
    Write-Message "`n📊 Resultado: `$successCount/`$totalCount archivos sincronizados" "Magenta"
    
    if (`$successCount -eq `$totalCount) {
        Write-Message "🎉 ¡Sincronización completada exitosamente!" "Green"
        if (-not `$Silent) {
            Write-Message "💡 Reinicia Windows Terminal para aplicar cambios de settings.json" "Cyan"
        }
    } else {
        Write-Message "⚠️ Algunos archivos no se pudieron sincronizar" "Yellow"
    }
} else {
    # Modo legacy: solo settings.json
    `$settingsFile = `$FilesToSync | Where-Object { `$_.Name -eq "Windows Terminal Settings" }
    if (`$settingsFile) {
        Sync-ConfigFile `$settingsFile
    }
}
"@

# Guardar el script mejorado
$MultiSyncScript | Out-File -FilePath $LocalSyncScript -Encoding UTF8 -Force
Unblock-File -Path $LocalSyncScript

Write-Host "✅ Script multi-archivo creado" -ForegroundColor Green

# 6. Ejecutar sincronización inicial
Write-Host "🔄 Ejecutando sincronización inicial..." -ForegroundColor Yellow
try {
    & $LocalSyncScript -MultiFile -Force
    Write-Host "✅ Sincronización inicial completada" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Error en sincronización inicial: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 7. Configurar variable de entorno para mostrar mensaje la primera vez
$env:POWERSHELL_FIRST_RUN = $true

Write-Host "`n🎉 ¡Configuración completada!" -ForegroundColor Green
Write-Host "`n📋 ¿Qué se configuró?" -ForegroundColor Cyan
Write-Host "   ✅ Auto-sync al iniciar PowerShell" -ForegroundColor White
Write-Host "   ✅ Script multi-archivo mejorado" -ForegroundColor White
Write-Host "   ✅ Comandos: sync-all, sync-all -Check, sync-all -Force" -ForegroundColor White
Write-Host "   ✅ Configuración solo para tu usuario" -ForegroundColor White

Write-Host "`n🔄 Próximos pasos:" -ForegroundColor Cyan
Write-Host "   1. Reinicia PowerShell para activar auto-sync" -ForegroundColor White
Write-Host "   2. Reinicia Windows Terminal para aplicar settings.json" -ForegroundColor White
Write-Host "   3. Tu configuración se sincronizará automáticamente al iniciar" -ForegroundColor White

Write-Host "`n💡 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   sync-all          # Sincronizar todo manualmente" -ForegroundColor White
Write-Host "   sync-all -Check   # Solo verificar actualizaciones" -ForegroundColor White
Write-Host "   sync-all -Force   # Forzar descarga completa" -ForegroundColor White