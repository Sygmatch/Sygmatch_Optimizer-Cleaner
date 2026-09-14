<#
.SYNOPSIS
    Sygmatch Optimizer Pro - Consola Integral Versión Universal
.DESCRIPTION
    Herramienta de hardening, optimización y mantenimiento con notificaciones de estado por texto para máxima fluidez.
#>

# Forzar inicialización segura para evitar consola fantasma al compilar con -noConsole
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "SilentlyContinue"

# 1. VERIFICACION DE PRIVILEGIOS DE ADMINISTRADOR
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$osInfo = Get-CimInstance Win32_OperatingSystem
$osCaption = $osInfo.Caption
$global:isWin11 = $osCaption -match "Windows 11"

# =========================================================================================
# 2. GESTION INTELIGENTE DEL PUNTO DE RESTAURACION (< 24h)
# =========================================================================================
function Inicializar-PuntoRestauracion {
    try {
        $puntos = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        $crearNuevo = $true
        
        if ($puntos) {
            $ultimo = $puntos | Select-Object -Last 1
            $fechaCreacion = [System.Management.ManagementDateTimeConverter]::ToDateTime($ultimo.CreationTime)
            $horasTranscurridas = (Get-Date) - $fechaCreacion
            
            if ($horasTranscurridas.TotalHours -lt 24) {
                $mensaje = "Se encontro un punto de restauracion reciente:`n`nFecha: $($fechaCreacion)`nDescripcion: $($ultimo.Description)`n`n¿Desea crear un nuevo punto de todas formas o usar el existente?"
                $resultado = [System.Windows.Forms.MessageBox]::Show($mensaje, "Verificacion de Seguridad - Sygmatch", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                
                if ($resultado -eq 'No') {
                    $crearNuevo = $false
                }
            }
        }
        
        if ($crearNuevo) {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue | Out-Null
            Checkpoint-Computer -Description "Sygmatch-Optimizer Backup GUI" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
        }
    } catch {}
}

Inicializar-PuntoRestauracion

# Funciones Base de Registro
function Set-RegKey {
    param ($Path, $Name, $Value, $PropertyType = "DWord")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $PropertyType -Force | Out-Null
    } catch {}
}

function Remove-RegValue {
    param ($Path, $Name)
    try {
        if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -Force | Out-Null }
    } catch {}
}

# =========================================================================================
# 3. VERIFICADOR DE ESTADO EN VIVO (15 TWEAKS)
# =========================================================================================
function Obtener-EstadoTweak {
    param($TweakId)
    $aplicado = $false
    try {
        switch ($TweakId) {
            1 {
                $val = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -ErrorAction SilentlyContinue
                if ($val -eq 1) { $aplicado = $true }
            }
            2 {
                $val = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue
                if ($val -eq 0) { $aplicado = $true }
            }
            3 {
                $val = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
                if ($val -eq 2) { $aplicado = $true }
            }
            4 {
                $val = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -ErrorAction SilentlyContinue
                if ($val -eq 0) { $aplicado = $true }
            }
            5 {
                if ($global:isWin11) {
                    $val = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue
                    if ($val -eq 0) { $aplicado = $true }
                } else {
                    $val = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -ErrorAction SilentlyContinue
                    if ($val -ne $null) { $aplicado = $true }
                }
            }
            6 {
                $val = Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue
                if ($val -eq 0) { $aplicado = $true }
            }
            7 {
                $val = Get-ItemPropertyValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue
                if ($val -eq 0) { $aplicado = $true }
            }
            8 {
                $val = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\common\clienttelemetry" -Name "disabletelemetry" -ErrorAction SilentlyContinue
                if ($val -eq 1) { $aplicado = $true }
            }
            9 {
                $val = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -ErrorAction SilentlyContinue
                if ($val -eq 1) { $aplicado = $true }
            }
            10 {
                if ($global:isWin11) {
                    $val = Get-ItemPropertyValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue
                    if ($val -eq 1) { $aplicado = $true }
                } else {
                    $val = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
                    if ($val -eq 0) { $aplicado = $true }
                }
            }
            11 {
                $val = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue
                if ($val -eq 1) { $aplicado = $true }
            }
            12 {
                $s1 = (Get-Service -Name "SysMain" -ErrorAction SilentlyContinue).StartType
                if ($s1 -eq 'Disabled') { $aplicado = $true }
            }
            13 {
                $t1 = Get-ScheduledTask -TaskName "Consolidator" -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -ErrorAction SilentlyContinue
                if ($t1 -and $t1.State -eq 'Disabled') { $aplicado = $true }
            }
            14 {
                $valQos = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -ErrorAction SilentlyContinue
                if ($valQos -eq 0) { $aplicado = $true }
            }
            15 {
                $valTask = Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -ErrorAction SilentlyContinue
                if ($valTask -eq 1 -or $valTask -eq "1") { $aplicado = $true }
            }
        }
    } catch {}
    return $aplicado
}

# =========================================================================================
# 4. TAREAS DE APLICACION Y REVERSION (15 TWEAKS - INTEGROS)
# =========================================================================================
function Tarea-1 {
    try {
        $apps = @("CandyCrush", "Disney", "Spotify", "BingWeather", "BingNews", "WindowsMaps", "SkypeApp", "Microsoft.GetHelp", "Microsoft.FeedbackHub", "Microsoft.QuickAssist", "MicrosoftSolitaireCollection")
        foreach ($app in $apps) { 
            Get-AppxPackage "*$app*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
        Write-Log "Bloatware UWP y Telemetria de Consumo aplicados." "SUCCESS"
    } catch { Write-Log "Error en Bloatware UWP: $_" "ERROR" }
}
function Revertir-1 { try { Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures"; Write-Log "Bloatware UWP revertido." "INFO" } catch {} }

function Tarea-2 {
    try {
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
        Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
        Write-Log "Privacidad y Telemetria Segura aplicadas." "SUCCESS"
    } catch { Write-Log "Error en Privacidad: $_" "ERROR" }
}
function Revertir-2 {
    try {
        Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"
        Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 1
        Write-Log "Privacidad revertida." "INFO"
    } catch {}
}

function Tarea-3 {
    try {
        Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "MinAnimate" -Value 0 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value 0 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value 2 -PropertyType String
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log "Efectos Visuales Balanceados aplicados." "SUCCESS"
    } catch { Write-Log "Error en Efectos Visuales: $_" "ERROR" }
}
function Revertir-3 {
    try {
        Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 1
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log "Efectos Visuales revertidos." "INFO"
    } catch {}
}

function Tarea-4 { 
    try { 
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 
        Write-Log "Optimizacion de Entrega (P2P) desactivada." "SUCCESS"
    } catch { Write-Log "Error en Optimizacion de Entrega: $_" "ERROR" } 
}
function Revertir-4 { try { Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode"; Write-Log "Optimizacion de Entrega revertida." "INFO" } catch {} }

function Tarea-5 {
    try {
        if ($global:isWin11) {
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0
        } else {
            Set-RegKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2
        }
        Write-Log "Tweaks de Barra de Tareas aplicados." "SUCCESS"
    } catch { Write-Log "Error en Barra de Tareas: $_" "ERROR" }
}
function Revertir-5 {
    try {
        if ($global:isWin11) { Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 1 }
        else { Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" }
        Write-Log "Barra de Tareas revertida." "INFO"
    } catch {}
}

function Tarea-6 { 
    try { 
        & powercfg.exe /hibernate off | Out-Null 
        Write-Log "Hibernacion desactivada." "SUCCESS"
    } catch { Write-Log "Error en Hibernacion: $_" "ERROR" } 
}
function Revertir-6 { try { & powercfg.exe /hibernate on | Out-Null; Write-Log "Hibernacion revertida." "INFO" } catch {} }

function Tarea-7 {
    try {
        Set-RegKey -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
        Write-Log "Xbox Game Bar y DVR desactivados." "SUCCESS"
    } catch { Write-Log "Error en Xbox Game Bar: $_" "ERROR" }
}
function Revertir-7 { try { Set-RegKey -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1; Write-Log "Xbox Game Bar revertido." "INFO" } catch {} }

function Tarea-8 { 
    try { 
        Set-RegKey -Path "HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\common\clienttelemetry" -Name "disabletelemetry" -Value 1 
        Write-Log "Telemetria de Microsoft Office desactivada." "SUCCESS"
    } catch { Write-Log "Error en Telemetria de Office: $_" "ERROR" } 
}
function Revertir-8 { try { Remove-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\common\clienttelemetry" -Name "disabletelemetry"; Write-Log "Telemetria de Office revertida." "INFO" } catch {} }

function Tarea-9 { 
    try { 
        Set-RegKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value 1 
        Write-Log "Autoplay desactivado (Proteccion USB)." "SUCCESS"
    } catch { Write-Log "Error en Autoplay: $_" "ERROR" } 
}
function Revertir-9 { try { Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay"; Write-Log "Autoplay revertido." "INFO" } catch {} }

function Tarea-10 {
    try {
        if ($global:isWin11) {
            Set-RegKey -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1
            Get-AppxPackage "*Microsoft.Copilot*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        } else {
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
        }
        Write-Log "Hardening de IA y Copilot / Cortana aplicado." "SUCCESS"
    } catch { Write-Log "Error en Hardening de IA: $_" "ERROR" }
}
function Revertir-10 {
    try {
        if ($global:isWin11) {
            Remove-RegValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot"
        } else {
            Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana"
        }
        Write-Log "Hardening de IA revertido." "INFO"
    } catch {}
}

function Tarea-11 { 
    try { 
        Set-RegKey -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 
        Write-Log "Modo Juego activado." "SUCCESS"
    } catch { Write-Log "Error en Modo Juego: $_" "ERROR" } 
}
function Revertir-11 { try { Set-RegKey -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0; Write-Log "Modo Juego revertido." "INFO" } catch {} }

function Tarea-12 {
    try {
        $serviciosManual = @("XblAuthManager", "XblGameSave", "XboxNetApiSvc", "RemoteRegistry")
        foreach ($svc in $serviciosManual) {
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue) { Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue }
        }
        if (Get-Service -Name "SysMain" -ErrorAction SilentlyContinue) {
            Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Servicios optimizados (SysMain y Xbox)." "SUCCESS"
    } catch { Write-Log "Error en Servicios: $_" "ERROR" }
}
function Revertir-12 {
    try {
        $servicios = @("XblAuthManager", "XblGameSave", "XboxNetApiSvc", "RemoteRegistry", "SysMain")
        foreach ($svc in $servicios) {
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
                Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
                Start-Service -Name $svc -ErrorAction SilentlyContinue
            }
        }
        Write-Log "Servicios revertidos." "INFO"
    } catch {}
}

function Tarea-13 {
    try {
        $tareas = @(
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\Usbceip",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
        )
        foreach ($t in $tareas) { Disable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue }
        Write-Log "Tareas programadas de telemetria desactivadas." "SUCCESS"
    } catch { Write-Log "Error en Tareas programadas: $_" "ERROR" }
}
function Revertir-13 {
    try {
        $tareas = @(
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\Usbceip",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
        )
        foreach ($t in $tareas) { Enable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue }
        Write-Log "Tareas programadas revertidas." "INFO"
    } catch {}
}

function Tarea-14 {
    try {
        $interfaces = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        foreach ($adapter in $interfaces) {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
            if (Test-Path $path) {
                Set-RegKey -Path $path -Name "TcpAckFrequency" -Value 1
                Set-RegKey -Path $path -Name "TCPNoDelay" -Value 1
            }
        }
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -Value 0
        Write-Log "Red, TCP/IP y QoS optimizados." "SUCCESS"
    } catch { Write-Log "Error en Red y TCP/IP: $_" "ERROR" }
}
function Revertir-14 {
    try {
        Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit"
        Write-Log "Red y TCP/IP revertidos." "INFO"
    } catch {}
}

function Tarea-15 {
    try {
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value 1 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -PropertyType String
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableSearchBoxSuggestions" -Value 1
        Write-Log "Rendimiento del Sistema (Cierre rapido y Busqueda Bing) aplicado." "SUCCESS"
    } catch { Write-Log "Error en Rendimiento del Sistema: $_" "ERROR" }
}
function Revertir-15 {
    try {
        Remove-RegValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks"
        Remove-RegValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout"
        Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableSearchBoxSuggestions"
        Write-Log "Rendimiento del Sistema revertido." "INFO"
    } catch {}
}

# =========================================================================================
# 5. CONSTRUCCION DE LA INTERFAZ GRAFICA (ESTABLE Y SIN BLOQUEOS)
# =========================================================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "Sygmatch Optimizer Pro - Consola Integral"
$form.Size = New-Object System.Drawing.Size(1200, 720)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#121212")
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

$global:estadoInicialTweaks = @{}

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "SYGMATCH OPTIMIZER PRO (OS: $osCaption)"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(20, 15)
$lblTitle.Size = New-Object System.Drawing.Size(1140, 30)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
$form.Controls.Add($lblTitle)

# Consola de Registro
$txtConsole = New-Object System.Windows.Forms.RichTextBox
$txtConsole.Location = New-Object System.Drawing.Point(20, 60)
$txtConsole.Size = New-Object System.Drawing.Size(430, 595)
$txtConsole.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1C1C1C")
$txtConsole.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 128)
$txtConsole.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$txtConsole.ReadOnly = $true
$txtConsole.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$form.Controls.Add($txtConsole)

function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $time = Get-Date -Format "HH:mm:ss"
    $prefix = "[$time] [$Type]"
    
    $color = [System.Drawing.Color]::White
    if ($Type -eq "SUCCESS") { $color = [System.Drawing.Color]::FromArgb(0, 255, 128) }
    elseif ($Type -eq "ERROR") { $color = [System.Drawing.Color]::FromArgb(255, 80, 80) }
    elseif ($Type -eq "INFO") { $color = [System.Drawing.Color]::FromArgb(100, 200, 255) }

    $txtConsole.SelectionStart = $txtConsole.TextLength
    $txtConsole.SelectionLength = 0
    $txtConsole.SelectionColor = $color
    $txtConsole.AppendText("$prefix $Message`r`n")
    $txtConsole.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(470, 60)
$tabControl.Size = New-Object System.Drawing.Size(690, 530)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.Controls.Add($tabControl)

$tabOpt1 = New-Object System.Windows.Forms.TabPage
$tabOpt1.Text = "Privacidad, Bloatware e IA"
$tabOpt1.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#181818")
$tabControl.Controls.Add($tabOpt1)

$tabOpt2 = New-Object System.Windows.Forms.TabPage
$tabOpt2.Text = "Rendimiento, Red y Servicios"
$tabOpt2.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#181818")
$tabControl.Controls.Add($tabOpt2)

$tabMaint = New-Object System.Windows.Forms.TabPage
$tabMaint.Text = "Mantenimiento Avanzado"
$tabMaint.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#181818")
$tabControl.Controls.Add($tabMaint)

# OPCIONES DE TWEAKS
$listaOpciones = @(
    @{ Id = 1; Name = "Remover Bloatware UWP y Telemetria de Consumo"; Tab = $tabOpt1 },
    @{ Id = 2; Name = "Privacidad y Telemetria Segura"; Tab = $tabOpt1 },
    @{ Id = 3; Name = "Efectos Visuales Balanceados (Con reinicio Explorer)"; Tab = $tabOpt1 },
    @{ Id = 4; Name = "Desactivar Optimizacion de Entrega (P2P)"; Tab = $tabOpt1 },
    @{ Id = 5; Name = "Tweaks de Barra de Tareas (Segun Version)"; Tab = $tabOpt1 },
    @{ Id = 6; Name = "Desactivar Hibernacion (Libera RAM en Disco)"; Tab = $tabOpt1 },
    @{ Id = 7; Name = "Desactivar Xbox Game Bar y DVR"; Tab = $tabOpt1 },
    @{ Id = 8; Name = "Desactivar Telemetria de Microsoft Office"; Tab = $tabOpt1 },
    @{ Id = 9; Name = "Desactivar Autoplay (Proteccion USB)"; Tab = $tabOpt2 },
    @{ Id = 10; Name = "Desactivar Asistentes (Cortana / Hardening IA & Copilot)"; Tab = $tabOpt2 },
    @{ Id = 11; Name = "Modo Juego / HAGS"; Tab = $tabOpt2 },
    @{ Id = 12; Name = "Optimizacion Segura de Servicios (SSD/HDD y SysMain)"; Tab = $tabOpt2 },
    @{ Id = 13; Name = "Tareas Programadas de Telemetria Superficial"; Tab = $tabOpt2 },
    @{ Id = 14; Name = "Red, TCP/IP y Latencia (Nagle / QoS)"; Tab = $tabOpt2 },
    @{ Id = 15; Name = "Rendimiento de Sistema (Cierre Rapido y Busqueda Bing)"; Tab = $tabOpt2 }
)

$yPos1 = 15
$yPos2 = 15

foreach ($op in $listaOpciones) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $op.Name
    $chk.Name = "chk_$($op.Id)"
    $chk.Size = New-Object System.Drawing.Size(650, 26)
    $chk.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    $estadoActual = Obtener-EstadoTweak $op.Id
    $global:estadoInicialTweaks[$op.Id] = $estadoActual
    
    if ($estadoActual) {
        $chk.Checked = $true
        $chk.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
        $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    } else {
        $chk.Checked = $false
        $chk.ForeColor = [System.Drawing.Color]::White
    }

    if ($op.Tab -eq $tabOpt1) {
        $chk.Location = New-Object System.Drawing.Point(15, $yPos1)
        $tabOpt1.Controls.Add($chk)
        $yPos1 += 42
    } else {
        $chk.Location = New-Object System.Drawing.Point(15, $yPos2)
        $tabOpt2.Controls.Add($chk)
        $yPos2 += 42
    }
}

# --- ACCIONES DE MANTENIMIENTO CON NOTIFICACION DE TEXTO ---
$accionesMaint = @(
    @{ Text = "Ejecutar DISM Completo (RestoreHealth)"; Script = {
        Write-Log "Iniciando DISM (RestoreHealth)... Por favor espere, esto puede tardar unos minutos." "INFO"
        Start-Process dism.exe -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
        Write-Log "Proceso DISM finalizado con exito." "SUCCESS"
    }},
    @{ Text = "Ejecutar SFC /scannow (Verificacion del Sistema)"; Script = {
        Write-Log "Iniciando analisis SFC (/scannow)... Por favor espere, le avisaremos al terminar." "INFO"
        Start-Process sfc.exe -ArgumentList "/scannow" -Wait -NoNewWindow
        Write-Log "Analisis SFC completado." "SUCCESS"
    }},
    @{ Text = "Limpieza de Archivos Temporales y Cache"; Script = {
        Write-Log "Iniciando limpieza de archivos temporales..." "INFO"
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Limpieza de temporales completada con exito." "SUCCESS"
    }},
    @{ Text = "Optimizacion de WinSxS (Component Cleanup)"; Script = {
        Write-Log "Iniciando limpieza del almacen WinSxS... Espere un momento." "INFO"
        Start-Process dism.exe -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait -NoNewWindow
        Write-Log "Optimizacion de WinSxS finalizada." "SUCCESS"
    }},
    @{ Text = "Restablecimiento de Cache DNS y Winsock"; Script = {
        Write-Log "Restableciendo red (DNS y Winsock)..." "INFO"
        ipconfig /flushdns | Out-Null
        netsh winsock reset | Out-Null
        Write-Log "Cache DNS y Winsock restablecidos correctamente." "SUCCESS"
    }}
)

$yBtnMaint = 20
foreach ($acc in $accionesMaint) {
    $btnAcc = New-Object System.Windows.Forms.Button
    $btnAcc.Text = $acc.Text
    $btnAcc.Location = New-Object System.Drawing.Point(20, $yBtnMaint)
    $btnAcc.Size = New-Object System.Drawing.Size(635, 45)
    $btnAcc.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D2D")
    $btnAcc.ForeColor = [System.Drawing.Color]::White
    $btnAcc.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnAcc.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnAcc.Tag = $acc.Script
    
    $btnAcc.Add_Click({
        $scriptBlock = $this.Tag
        & $scriptBlock
    })
    $tabMaint.Controls.Add($btnAcc)
    $yBtnMaint += 65
}

# Botones Globales
$btnAplicar = New-Object System.Windows.Forms.Button
$btnAplicar.Text = "Aplicar Cambios (Checkboxes Marcados)"
$btnAplicar.Location = New-Object System.Drawing.Point(855, 605)
$btnAplicar.Size = New-Object System.Drawing.Size(305, 48)
$btnAplicar.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#008066")
$btnAplicar.ForeColor = [System.Drawing.Color]::White
$btnAplicar.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnAplicar.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAplicar.Cursor = [System.Windows.Forms.Cursors]::Hand

$btnAplicar.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show("¿Desea aplicar y guardar todas las configuraciones marcadas en el sistema?", "Confirmacion", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($confirm -eq 'Yes') {
        Write-Log "Iniciando analisis de cambios en directivas..." "INFO"
        $errores = 0
        $cambiosRealizados = 0
        
        for ($i = 1; $i -le 15; $i++) {
            $ctrl = $form.Controls.Find("chk_$i", $true) | Select-Object -First 1
            if ($ctrl) {
                $estadoAnterior = $global:estadoInicialTweaks[$i]
                $estadoActualCheck = $ctrl.Checked
                
                if ($estadoActualCheck -ne $estadoAnterior) {
                    $cambiosRealizados++
                    try {
                        if ($estadoActualCheck -eq $true) {
                            & "Tarea-$i"
                            $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
                            $ctrl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                        } else {
                            & "Revertir-$i"
                            $ctrl.ForeColor = [System.Drawing.Color]::White
                            $ctrl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
                        }
                        $global:estadoInicialTweaks[$i] = $estadoActualCheck
                    } catch { 
                        $errores++ 
                    }
                }
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
        
        if ($cambiosRealizados -eq 0) {
            Write-Log "No se detectaron cambios nuevos para aplicar o revertir." "INFO"
        } elseif ($errores -eq 0) {
            Write-Log "Los cambios seleccionados se aplicaron/revirtieron con exito." "SUCCESS"
        } else {
            Write-Log "El proceso finalizo con algunas advertencias." "ERROR"
        }
    }
})
$form.Controls.Add($btnAplicar)

$linkGithub = New-Object System.Windows.Forms.LinkLabel
$linkGithub.Text = "[GitHub] Repositorio Oficial"
$linkGithub.Location = New-Object System.Drawing.Point(470, 615)
$linkGithub.Size = New-Object System.Drawing.Size(200, 25)
$linkGithub.LinkColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
$linkGithub.ActiveLinkColor = [System.Drawing.Color]::White
$linkGithub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$linkGithub.Add_LinkClicked({
    [System.Diagnostics.Process]::Start("https://github.com/Sygmatch/Sygmatch_Optimizer-Cleaner")
    Write-Log "Abriendo repositorio de GitHub..." "INFO"
})
$form.Controls.Add($linkGithub)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Salir"
$btnExit.Location = New-Object System.Drawing.Point(745, 605)
$btnExit.Size = New-Object System.Drawing.Size(100, 48)
$btnExit.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#B02A2A")
$btnExit.ForeColor = [System.Drawing.Color]::White
$btnExit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnExit.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnExit.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

Write-Log "Interfaz grafica cargada correctamente (Modo seguro sin bloqueos)." "SUCCESS"
Write-Log "Sistema operativo detectado: $osCaption" "INFO"
Write-Log "Estado diferencial de los 15 tweaks registrado correctamente." "INFO"

[void]$form.ShowDialog()