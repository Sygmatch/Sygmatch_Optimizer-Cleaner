# =========================================================================================
# SCRIPT: Sygmatch-Optimizer-GUI.ps1
# DESCRIPTION: Herramienta de optimización, limpieza, hardening y GUI con verificación en vivo
# =========================================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# 1. VERIFICACIÓN DE PRIVILEGIOS DE ADMINISTRADOR
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$osInfo = Get-CimInstance Win32_OperatingSystem
$osCaption = $osInfo.Caption
$global:isWin11 = $osCaption -match "Windows 11"

# =========================================================================================
# 2. GESTIÓN INTELIGENTE DEL PUNTO DE RESTAURACIÓN (< 24h)
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
                $mensaje = "Se encontró un punto de restauración reciente:`n`nFecha: $($fechaCreacion)`nDescripción: $($ultimo.Description)`n`n¿Desea crear un nuevo punto de todas formas o usar el existente?"
                $resultado = [System.Windows.Forms.MessageBox]::Show($mensaje, "Verificación de Seguridad - Sygmatch", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                
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
# 3. VERIFICADOR DE ESTADO EN VIVO
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
                $s1 = (Get-Service -Name "XblAuthManager" -ErrorAction SilentlyContinue).StartType
                if ($s1 -eq 'Manual') { $aplicado = $true }
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
# 4. TAREAS DE APLICACIÓN Y REVERSIÓN
# =========================================================================================
function Tarea-1 {
    try {
        $apps = @("CandyCrush", "Disney", "Spotify", "BingWeather", "BingNews", "WindowsMaps", "SkypeApp", "Microsoft.GetHelp", "Microsoft.FeedbackHub", "Microsoft.QuickAssist", "MicrosoftSolitaireCollection")
        foreach ($app in $apps) { 
            Get-AppxPackage "*$app*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    } catch {}
}
function Revertir-1 { try { Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" } catch {} }

function Tarea-2 {
    try {
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
        Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
    } catch {}
}
function Revertir-2 {
    try {
        Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"
        Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 1
    } catch {}
}

function Tarea-3 {
    try {
        Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "MinAnimate" -Value 0 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value 0 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value 2 -PropertyType String
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    } catch {}
}
function Revertir-3 {
    try {
        Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 1
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "MinAnimate" -Value 1 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value 1 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value 2 -PropertyType String
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Tarea-4 { try { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 } catch {} }
function Revertir-4 { try { Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" } catch {} }

function Tarea-5 {
    try {
        if ($global:isWin11) {
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0
        } else {
            Set-RegKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2
        }
    } catch {}
}
function Revertir-5 {
    try {
        if ($global:isWin11) { Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 1 }
        else { Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" }
    } catch {}
}

function Tarea-6 { try { & powercfg.exe /hibernate off | Out-Null } catch {} }
function Revertir-6 { try { & powercfg.exe /hibernate on | Out-Null } catch {} }

function Tarea-7 {
    try {
        Set-RegKey -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
    } catch {}
}
function Revertir-7 { try { Set-RegKey -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 } catch {} }

function Tarea-8 { try { Set-RegKey -Path "HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\common\clienttelemetry" -Name "disabletelemetry" -Value 1 } catch {} }
function Revertir-8 { try { Remove-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\common\clienttelemetry" -Name "disabletelemetry" } catch {} }

function Tarea-9 { try { Set-RegKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value 1 } catch {} }
function Revertir-9 { try { Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" } catch {} }

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
    } catch {}
}
function Revertir-10 {
    try {
        if ($global:isWin11) {
            Remove-RegValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot"
            Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot"
            Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis"
        } else {
            Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana"
        }
    } catch {}
}

function Tarea-11 { try { Set-RegKey -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 } catch {} }
function Revertir-11 { try { Set-RegKey -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0 } catch {} }

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
    } catch {}
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
    } catch {}
}
function Revertir-13 {
    try {
        $tareas = @(
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\Usbceip",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
        )
        foreach ($t in $tareas) { Enable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue }
    } catch {}
}

function Tarea-14 {
    try {
        $interfaces = Get-NetAdapter -State Up -ErrorAction SilentlyContinue
        foreach ($adapter in $interfaces) {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
            if (Test-Path $path) {
                Set-RegKey -Path $path -Name "TcpAckFrequency" -Value 1
                Set-RegKey -Path $path -Name "TCPNoDelay" -Value 1
            }
        }
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -Value 0
    } catch {}
}
function Revertir-14 {
    try {
        $interfaces = Get-NetAdapter -State Up -ErrorAction SilentlyContinue
        foreach ($adapter in $interfaces) {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
            if (Test-Path $path) {
                Remove-RegValue -Path $path -Name "TcpAckFrequency"
                Remove-RegValue -Path $path -Name "TCPNoDelay"
            }
        }
        Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit"
    } catch {}
}

function Tarea-15 {
    try {
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value 1 -PropertyType String
        Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -PropertyType String
        Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableSearchBoxSuggestions" -Value 1
    } catch {}
}
function Revertir-15 {
    try {
        Remove-RegValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks"
        Remove-RegValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout"
        Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableSearchBoxSuggestions"
    } catch {}
}

# =========================================================================================
# 5. CONSTRUCCIÓN DE LA INTERFAZ GRÁFICA MODERNA (GUI)
# =========================================================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "Sygmatch Optimizer Pro - Hardening & Mantenimiento Avanzado"
$form.Size = New-Object System.Drawing.Size(920, 650)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#191919")
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "SYGMATCH OPTIMIZER (OS: $osCaption)"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(20, 12)
$lblTitle.Size = New-Object System.Drawing.Size(750, 25)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
$form.Controls.Add($lblTitle)

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(15, 45)
$tabControl.Size = New-Object System.Drawing.Size(875, 485)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.Controls.Add($tabControl)

$tabOpt1 = New-Object System.Windows.Forms.TabPage
$tabOpt1.Text = "Privacidad, Bloatware e IA"
$tabOpt1.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f1f1f")
$tabControl.Controls.Add($tabOpt1)

$tabOpt2 = New-Object System.Windows.Forms.TabPage
$tabOpt2.Text = "Rendimiento, Red y Servicios"
$tabOpt2.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f1f1f")
$tabControl.Controls.Add($tabOpt2)

$tabMaint = New-Object System.Windows.Forms.TabPage
$tabMaint.Text = "Limpieza y Mantenimiento"
$tabMaint.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f1f1f")
$tabControl.Controls.Add($tabMaint)

$listaOpciones = @(
    @{ Id = 1; Name = "1. Remover Bloatware UWP y Telemetría de Consumo"; Tab = $tabOpt1 },
    @{ Id = 2; Name = "2. Privacidad y Telemetría Segura"; Tab = $tabOpt1 },
    @{ Id = 3; Name = "3. Efectos Visuales Balanceados (Con reinicio Explorer)"; Tab = $tabOpt1 },
    @{ Id = 4; Name = "4. Desactivar Optimización de Entrega (P2P)"; Tab = $tabOpt1 },
    @{ Id = 5; Name = "5. Tweaks de Barra de Tareas (Según Versión)"; Tab = $tabOpt1 },
    @{ Id = 6; Name = "6. Desactivar Hibernación (Libera RAM en Disco)"; Tab = $tabOpt1 },
    @{ Id = 7; Name = "7. Desactivar Xbox Game Bar y DVR"; Tab = $tabOpt1 },
    @{ Id = 8; Name = "8. Desactivar Telemetría de Microsoft Office"; Tab = $tabOpt1 },
    @{ Id = 9; Name = "9. Desactivar Autoplay (Protección USB)"; Tab = $tabOpt2 },
    @{ Id = 10; Name = "10. Desactivar Asistentes (Cortana / Hardening IA & Copilot)"; Tab = $tabOpt2 },
    @{ Id = 11; Name = "11. Modo Juego / HAGS"; Tab = $tabOpt2 },
    @{ Id = 12; Name = "12. Optimización Segura de Servicios (SSD/HDD y SysMain)"; Tab = $tabOpt2 },
    @{ Id = 13; Name = "13. Tareas Programadas de Telemetría Superficial"; Tab = $tabOpt2 },
    @{ Id = 14; Name = "14. Red, TCP/IP y Latencia (Nagle / QoS)"; Tab = $tabOpt2 },
    @{ Id = 15; Name = "15. Rendimiento de Sistema (Cierre Rápido y Búsqueda Bing)"; Tab = $tabOpt2 }
)

$yPosTab1 = 20
$yPosTab2 = 20

foreach ($op in $listaOpciones) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $op.Name
    $chk.Name = "chk_$($op.Id)"
    $chk.Size = New-Object System.Drawing.Size(820, 26)
    
    $estadoActual = Obtener-EstadoTweak $op.Id
    if ($estadoActual) {
        $chk.Checked = $true
        $chk.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
        $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    } else {
        $chk.Checked = $false
        $chk.ForeColor = [System.Drawing.Color]::White
    }

    if ($op.Tab -eq $tabOpt1) {
        $chk.Location = New-Object System.Drawing.Point(20, $yPosTab1)
        $tabOpt1.Controls.Add($chk)
        $yPosTab1 += 50
    } else {
        $chk.Location = New-Object System.Drawing.Point(20, $yPosTab2)
        $tabOpt2.Controls.Add($chk)
        $yPosTab2 += 50
    }
}

# --- CONTENIDO PESTAÑA MANTENIMIENTO (AJUSTADO: SIN REINICIO DE IP PARA PROTEGER IP FIJA) ---
$grpMaint = New-Object System.Windows.Forms.GroupBox
$grpMaint.Text = " Herramientas de Mantenimiento Avanzado (Progreso Visible en Consola) "
$grpMaint.ForeColor = [System.Drawing.Color]::LightGray
$grpMaint.Location = New-Object System.Drawing.Point(15, 10)
$grpMaint.Size = New-Object System.Drawing.Size(840, 430)

$acciones = @(
    @{ Text = "Ejecutar DISM Completo (ScanHealth y RestoreHealth con Progreso)"; Action = 'dism.exe /Online /Cleanup-Image /ScanHealth; dism.exe /Online /Cleanup-Image /RestoreHealth; Write-Host ""; Read-Host "Proceso finalizado. Presione Enter para salir"' },
    @{ Text = "Ejecutar SFC /scannow (Verificación y Reparación de Sistema)"; Action = 'sfc.exe /scannow; Write-Host ""; Read-Host "Proceso finalizado. Presione Enter para salir"' },
    @{ Text = "Diagnóstico Inteligente de Almacenamiento (TRIM / Unidades)"; Action = 'foreach($d in Get-PhysicalDisk){$d}; foreach($d in Get-PhysicalDisk) { if($d.MediaType -eq "SSD") { Optimize-Volume -DriveLetter C -ReTrim -Verbose } else { Optimize-Volume -DriveLetter C -Defrag -Verbose } }; Write-Host ""; Read-Host "Proceso finalizado. Presione Enter para salir"' },
    @{ Text = "Limpieza de Archivos Temporales y Caché del Sistema"; Action = 'Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "¡Archivos temporales eliminados con éxito!"; Read-Host "Presione Enter para salir"' },
    @{ Text = "Optimización de WinSxS (Limpieza de Componentes Base)"; Action = 'dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase; Write-Host ""; Read-Host "Proceso finalizado. Presione Enter para salir"' },
    @{ Text = "Restablecimiento de Caché DNS y Winsock (Seguro para IP Fija)"; Action = 'ipconfig /flushdns; netsh winsock reset; Write-Host ""; Read-Host "Caché DNS y Winsock restablecidos. Presione Enter para salir"' }
)

$yBtn = 35
foreach ($acc in $acciones) {
    $btnAccion = New-Object System.Windows.Forms.Button
    $btnAccion.Text = $acc.Text
    $btnAccion.Location = New-Object System.Drawing.Point(30, $yBtn)
    $btnAccion.Size = New-Object System.Drawing.Size(780, 42)
    $btnAccion.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2d2d2d")
    $btnAccion.ForeColor = [System.Drawing.Color]::White
    $btnAccion.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    
    $btnAccion.Tag = $acc.Action
    
    $btnAccion.Add_Click({
        $comandoAEjecutar = $this.Tag
        $resp = [System.Windows.Forms.MessageBox]::Show("Se abrirá una consola dedicada para ejecutar este proceso en tiempo real y mostrar su avance porcentual. ¿Desea continuar?", "Confirmación de Mantenimiento", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($resp -eq 'Yes') {
            try {
                $bytes = [System.Text.Encoding]::Unicode.GetBytes($comandoAEjecutar)
                $encoded = [Convert]::ToBase64String($bytes)
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -Verb RunAs
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Ocurrió un error al iniciar la consola de proceso: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    })
    
    $grpMaint.Controls.Add($btnAccion)
    $yBtn += 60
}
$tabMaint.Controls.Add($grpMaint)

# =========================================================================================
# BOTÓN GLOBAL "APLICAR CAMBIOS"
# =========================================================================================

$btnAplicar = New-Object System.Windows.Forms.Button
$btnAplicar.Text = "Aplicar Cambios (Checkboxes)"
$btnAplicar.Location = New-Object System.Drawing.Point(590, 545)
$btnAplicar.Size = New-Object System.Drawing.Size(300, 45)
$btnAplicar.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#008066")
$btnAplicar.ForeColor = [System.Drawing.Color]::White
$btnAplicar.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnAplicar.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

$btnAplicar.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show("¿Desea aplicar y guardar todas las configuraciones marcadas en el sistema?", "Confirmación de Cambios", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($confirm -eq 'Yes') {
        $lblStatus.Text = "Progreso: Aplicando directivas de optimización..."
        [System.Windows.Forms.Application]::DoEvents()
        
        $erroresGlobales = 0
        for ($i = 1; $i -le 15; $i++) {
            $ctrl = $form.Controls.Find("chk_$i", $true) | Select-Object -First 1
            if ($ctrl) {
                try {
                    if ($ctrl.Checked) {
                        & "Tarea-$i"
                        $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
                        $ctrl.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
                    } else {
                        & "Revertir-$i"
                        $ctrl.ForeColor = [System.Drawing.Color]::White
                        $ctrl.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
                    }
                } catch {
                    $erroresGlobales++
                }
            }
        }

        if ($erroresGlobales -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("¡Todas las configuraciones se han aplicado correctamente! (Los efectos visuales y el explorador se han actualizado).", "Proceso Finalizado", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            $lblStatus.Text = "Progreso: Configuración aplicada con éxito."
        } else {
            [System.Windows.Forms.MessageBox]::Show("El proceso finalizó con algunas advertencias en $erroresGlobales opciones.", "Aviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            $lblStatus.Text = "Progreso: Finalizado con advertencias menores."
        }
    }
})
$form.Controls.Add($btnAplicar)

$tabControl.Add_SelectedIndexChanged({
    if ($tabControl.SelectedTab -eq $tabMaint) {
        $btnAplicar.Visible = $false
    } else {
        $btnAplicar.Visible = $true
    }
})

# =========================================================================================
# ENLACE A GITHUB
# =========================================================================================
$linkGithub = New-Object System.Windows.Forms.LinkLabel
$linkGithub.Text = "[GitHub] Sygmatch_Optimizer-Cleaner"
$linkGithub.Location = New-Object System.Drawing.Point(15, 538)
$linkGithub.Size = New-Object System.Drawing.Size(260, 20)
$linkGithub.LinkColor = [System.Drawing.ColorTranslator]::FromHtml("#00FFCC")
$linkGithub.ActiveLinkColor = [System.Drawing.Color]::White
$linkGithub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$linkGithub.Add_LinkClicked({
    [System.Diagnostics.Process]::Start("https://github.com/Sygmatch/Sygmatch_Optimizer-Cleaner")
})
$form.Controls.Add($linkGithub)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Progreso: Listo. Las opciones en verde indican que ya están aplicadas."
$lblStatus.Location = New-Object System.Drawing.Point(15, 562)
$lblStatus.Size = New-Object System.Drawing.Size(550, 25)
$lblStatus.ForeColor = [System.Drawing.Color]::DarkGray
$form.Controls.Add($lblStatus)

# Ejecutar la interfaz gráfica
[void] $form.ShowDialog()
