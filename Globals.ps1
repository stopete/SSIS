#requires -Version 5.1
<#
.SYNOPSIS
    Global variables and helper functions for a SAPIEN PowerShell Studio Windows Forms application.

.DESCRIPTION
    - Resolves script and executable directories reliably in designer, console, and packaged EXE contexts.
    - Exposes minimal globals intended to be shared between Startup and Forms.
    - Provides UI-safe helpers for updating controls from background threads (InvokeRequired-safe).
    - Adds lightweight MessageBox helpers for consistent UI prompts.
    - Includes optional logging helper; Startup can set $script:LogFile to enable.

.NOTES
    Dot-source this file early from Startup.pss:
        . "$PSScriptRoot\Globals.ps1"
#>

#region Directory Resolution Helpers

function Get-ExecutableDirectory
{
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	
	try
	{
		$base = [System.AppDomain]::CurrentDomain.BaseDirectory
		if (![string]::IsNullOrWhiteSpace($base))
		{
			return (Resolve-Path -Path $base).ProviderPath
		}
	}
	catch { }
	
	try
	{
		$procPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
		if ($procPath) { return (Split-Path -Path $procPath -Parent) }
	}
	catch { }
	
	return (Get-Location).Path
}

function Get-ScriptDirectory
{
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	
	if ($PSScriptRoot) { return $PSScriptRoot }
	if ($script:MyInvocation -and $script:MyInvocation.MyCommand -and $script:MyInvocation.MyCommand.Path)
	{
		return (Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent)
	}
	return (Get-ExecutableDirectory)
}

#endregion Directory Resolution Helpers

#region Small Utility Helpers

function Ensure-TrailingBackslash
{
	[CmdletBinding()]
	[OutputType([string])]
	param ([Parameter(Mandatory)]
		[string]$Path)
	
	if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
	if ($Path[-1] -ne '\') { return $Path + '\' }
	return $Path
}

function Resolve-PathSafe
{
	[CmdletBinding()]
	[OutputType([string])]
	param ([Parameter(Mandatory)]
		[string]$Path)
	
	try { return (Resolve-Path -Path $Path -ErrorAction Stop).ProviderPath }
	catch { return $null }
}

function Test-Admin
{
	[CmdletBinding()]
	[OutputType([bool])]
	param ()
	
	try
	{
		$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
		$p = New-Object System.Security.Principal.WindowsPrincipal($id)
		return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
	}
	catch { return $false }
}

#endregion Small Utility Helpers

#region WinForms Helpers (UI-safe)

function Invoke-Ui
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[System.Windows.Forms.Control]$Control,
		[Parameter(Mandatory)]
		[ScriptBlock]$ScriptBlock,
		[object[]]$Arguments
	)
	
	if ($Control.IsDisposed) { return }
	if ($Control.InvokeRequired)
	{
		$null = $Control.BeginInvoke($ScriptBlock, @($Control) + $Arguments)
	}
	else
	{
		& $ScriptBlock $Control @Arguments
	}
}

function Set-UiText
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[System.Windows.Forms.Control]$Control,
		[Parameter(Mandatory)]
		[string]$Text
	)
	Invoke-Ui -Control $Control -ScriptBlock { param ($ctl,
			$t) $ctl.Text = $t } -Arguments $Text
}

function Append-UiText
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[System.Windows.Forms.TextBoxBase]$TextBox,
		[Parameter(Mandatory)]
		[string]$Text,
		[bool]$NewLine = $true
	)
	
	$sb = {
		param ($tb,
			$t,
			$nl)
		if ($nl) { $tb.AppendText("$t`r`n") }
		else { $tb.AppendText($t) }
		$tb.ScrollToCaret()
	}
	Invoke-Ui -Control $TextBox -ScriptBlock $sb -Arguments @($Text, $NewLine)
}

function Show-InfoDialog
{
	[CmdletBinding()]
	param ([Parameter(Mandatory)]
		[string]$Message,
		[string]$Caption = 'Information')
	[void][System.Windows.Forms.MessageBox]::Show($Message, $Caption, 'OK', 'Information')
}

function Show-ErrorDialog
{
	[CmdletBinding()]
	param ([Parameter(Mandatory)]
		[string]$Message,
		[string]$Caption = 'Error')
	[void][System.Windows.Forms.MessageBox]::Show($Message, $Caption, 'OK', 'Error')
}

function Show-ConfirmDialog
{
	[CmdletBinding()]
	[OutputType([bool])]
	param ([Parameter(Mandatory)]
		[string]$Message,
		[string]$Caption = 'Confirm')
	$res = [System.Windows.Forms.MessageBox]::Show($Message, $Caption, 'YesNo', 'Question')
	return ($res -eq [System.Windows.Forms.DialogResult]::Yes)
}

#endregion WinForms Helpers (UI-safe)

#region Global/Shared Variables

[string]$script:ScriptDirectory = Get-ScriptDirectory
[string]$script:ExecutableDirectory = Get-ExecutableDirectory

# Media root (e.g., 'E:\') set by Startup
[string]$script:TargetDrive = $null

# Optional central log file (set by Startup; used by Write-Log)
[string]$script:LogFile = $null

[hashtable]$script:AppContext = [ordered]@{
	IsElevated = (Test-Admin)
	WindowsDir = $env:WINDIR
	LastError  = $null
	StartedAt  = (Get-Date)
}

#endregion Global/Shared Variables

#region Logging (optional)

function Write-Log
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Message,
		[ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
		[string]$Level = 'INFO',
		[switch]$Echo
	)
	
	$line = '{0:u} [{1}] {2}' -f (Get-Date), $Level, $Message
	
	if ($Echo)
	{
		switch ($Level)
		{
			'ERROR' { Write-Error $Message }
			'WARN'  { Write-Warning $Message }
			'DEBUG' { Write-Verbose $Message }
			default { Write-Information $Message -InformationAction Continue }
		}
	}
	
	if ($script:LogFile)
	{
		try { Add-Content -Path $script:LogFile -Value $line -ErrorAction Stop }
		catch { $script:AppContext.LastError = $_.Exception.Message }
	}
}

#endregion Logging (optional)