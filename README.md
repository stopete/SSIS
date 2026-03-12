🖥️ SSIS Simple Seat Imaging System

🚀 SSIS Simple Seat Imaging System is a PowerShell-based Windows deployment and imaging platform designed for rapid workstation provisioning, disk imaging, and recovery operations.

![IMG_9425](https://github.com/user-attachments/assets/0f48dc56-a688-4b27-b21f-8524bb5ef0ff)


It is commonly used in WinPE environments to automate system deployment.

The tool integrates:

Disk imaging

Windows deployment automation

Post-install scripting

Recovery tools

Disk utilities

Hostname provisioning

🧰 Preparing Windows PE to Launch SSIS Automatically

Before using SSIS Simple Seat Imaging System, you can configure Windows PE (WinPE) so that the SSIS provisioning application launches automatically when the system boots.

This is useful for automated workstation deployment environments.

⚙️ Step-by-Step Instructions
1️⃣ Create a Bootable WinPE USB Drive

Create a bootable USB drive containing Windows PE.

You can use the Windows ADK tools to generate WinPE media.

If needed, search online for guides on creating WinPE bootable media.

2️⃣ Mount the WinPE WIM Image

Mount the WinPE WIM file so that you can modify its contents.

Get the WIM Image Index
Get-WindowsImage -ImagePath D:\Boot\boot_x64.wim

Mount the Image
Mount-WindowsImage -Path C:\Mount\ -ImagePath D:\Boot\boot_x64.wim -Index 1

3️⃣ Copy the SSIS Application

Copy the SSIS executable into the mounted image.

Example destination:

C:\Mount\ssis\


Example executable:

ProvisionTool_DKL.exe

4️⃣ Modify Startnet.cmd to Auto-Launch the Tool

Edit the file:

C:\Mount\Windows\System32\Startnet.cmd


Replace or add the following content:

@echo off

powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powershell.exe set-executionpolicy remotesigned

REG ADD "HKCU\Console" /v "WindowAlpha" /t REG_DWORD /d "247" /f >nul
REG IMPORT X:\ssis\modules\console.reg

Start x:\ssis\ProvisionTool_DKL.exe

wpeinit /unattend:x:\ssis\pe_unattend.xml
wpeutil disablefirewall

What these commands do
Command	Purpose
powercfg	Enables high-performance power plan
set-executionpolicy	Allows PowerShell scripts to run
REG ADD	Configures console appearance
REG IMPORT	Imports console registry configuration
Start ProvisionTool_DKL.exe	Launches the SSIS imaging tool
wpeinit	Initializes WinPE services
disablefirewall	Disables firewall in WinPE
5️⃣ Dismount and Save the WIM

After modifications are complete, dismount the WIM and commit the changes.

Save changes
Dismount-WindowsImage -Path C:\Mount\ -Save

Discard changes (if needed)
Dismount-WindowsImage -Path C:\Mount\ -Discard

🚀 Result

After completing these steps:

WinPE will automatically launch the SSIS imaging tool

No manual commands are required

Systems boot directly into the deployment interface

Ideal environments:

🏫 Computer labs

🏢 Enterprise IT

🖥 Rapid workstation deployment

🔧 IT support centers

📦 Features
💾 Disk Imaging

Restore TeraByte Image (.tbi) system images

Capture disk images using imagew.exe

Automatic disk wipe before deployment

Runtime imaging progress logging

🖥 Windows Deployment

The tool automates Windows provisioning by:

Injecting post-install scripts

Injecting unattend.xml

Automatically setting hostnames

Detecting Windows partitions

🔧 Integrated System Tools

The SSIS interface includes quick launch buttons for several utilities.

Tool	Purpose
🛠 Microsoft DaRT	Windows recovery environment
🔍 FRST	Malware diagnostics
🔐 BitLocker Tool	Encryption management
🧩 Partition Wizard	Disk partitioning
🗂 Explorer++	File explorer
📝 Notepad++	Script editing
💿 GImageX	WIM imaging
🧾 Logging System

The tool uses a centralized logging system.

Function
Write-UiLog


Logs messages to:

GUI log window

PowerShell console

Optional external logs

Log Levels
INFO
WARN
ERROR
DEBUG


Example:

Write-UiLog "Imaging started..."
Write-UiLog "Disk not found." -Level ERROR

📂 Image Management
Load Available Images

Function:

Load-TBI-Files


Scans the configured image directory for .tbi files and loads them into the GUI.

Capture Disk Image

Uses:

imagew.exe


Example capture command:

imagew.exe /b /rb:0 /d:0 /f:"image.tbi"

💿 Image Restore Process

The GO button starts the provisioning process.

Process Flow

1️⃣ Select target disk
2️⃣ Choose .tbi image
3️⃣ Enter hostname
4️⃣ Confirm disk wipe
5️⃣ Restore disk image
6️⃣ Detect Windows partition
7️⃣ Inject scripts and unattend file

⚠️ All data on the selected disk will be erased.

🧬 Post-Install Automation

Scripts can be automatically injected after deployment.

Script Location
C:\ProgramData\Dev_Sys_Setup\Post_Setup


Example scripts:

RenameComputer.ps1
DriverInstall.ps1
SoftwareInstall.ps1

🖥 Hostname Provisioning

Hostname values are inserted into:

Windows\Panther\unattend.xml


Placeholder replacement:

PROVISIONING → COMPUTERNAME

🔍 Windows Partition Detection

After imaging, the system automatically scans partitions for:

Windows\System32


Drive letters are assigned automatically.

Partition	Drive
System	S
Recovery	R
Windows/Data	P → descending
🧰 Utility Functions
Format-Bytes

Converts raw byte values into readable units.

Example:

1024 → 1.02 kB
1048576 → 1.05 MB

Ensure-Path

Ensures a directory exists.

Example:

Ensure-Path "C:\Deploy" -CreateIfMissing

Write-ColorSafe

Writes colored text if the PSWriteColor module is available.

🛠 Recovery Tools
Microsoft DaRT

Launches:

MSDartTools.exe


Allows repair of offline Windows installations.

🔘 GUI Controls
Button	Action
GO	Restore disk image
Capture Image	Create .tbi image
DaRT	Launch Microsoft DaRT
FRST	Run Farbar Recovery Tool
BitLocker Tool	Manage BitLocker
Explorer++	Open file explorer
Notepad++	Edit scripts
GImageX	Manage WIM images
Restart	Reboot system
Shutdown	Power off system
📁 Directory Layout

Example project structure:

SSIS/
│
├─ apps/
│   ├─ ImageW_LD/
│   ├─ Microsoft_DaRT/
│   ├─ FarbarRecoveryScanTool/
│   ├─ BitLockerTool/
│   ├─ Explorer++/
│   ├─ Notepad++/
│   └─ MiniToolPartitionWizard12/
│
├─ scripts/
│
├─ tbi_images/
│
├─ modules/
│   └─ pswritecolor/
│
└─ SSISSimpleSeatImaging.ps1

⚙️ Configuration Variables

Global configuration values typically defined in:

Globals.ps1

Variable	Purpose
$default_tbi_imagepath	TBI image storage location
$default_scriptpath	Post-install scripts
$default_modulespath	PowerShell modules
$default_unattendpath	Unattend files
$default_appspath	External tools
🚀 Running the Tool

Launch using PowerShell:

powershell.exe -ExecutionPolicy Bypass -File SSISSimpleSeatImaging.ps1


Recommended environment:

✔ Windows PE
✔ Administrator privileges

🧪 Typical Deployment Workflow
1. Boot system into WinPE
2. Launch SSIS Imaging Tool
3. Select target disk
4. Choose system image
5. Enter hostname
6. Restore image
7. Inject scripts
8. Reboot system


Typical deployment time:

⏱ 5-10 minutes per workstation

📜 License

Internal deployment utility.
