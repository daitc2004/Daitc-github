#################################################################################
# Disable UAC
#################################################################################
function setRegistryValue($key, $name, $value)
{  

    If ((Test-Path -Path $key) -Eq $false) { New-Item -ItemType Directory -Path $key | Out-Null }  

    Set-ItemProperty -Path $key -Name $name -Value $value -Type "Dword"  

}
function getRegistryValue($key, $name)
{

    (Get-ItemProperty $key $name).$name

}
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

$ConsentPromptBehaviorAdmin_Name = "ConsentPromptBehaviorAdmin"

$PromptOnSecureDesktop_Name = "PromptOnSecureDesktop"

setRegistryValue $Key $ConsentPromptBehaviorAdmin_Name 0

setRegistryValue $Key $PromptOnSecureDesktop_Name 0

################################################################################
# Disable Windows Firewall
# ##############################################################################

Set-NetFirewallProfile -Profile Public,Private,Domain -Enabled False

###############################################################################
# Allow Remote Connetions
# #############################################################################

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0

###############################################################################
# Set time zone to Central Standard time
# #############################################################################

tzutil /s "Central Standard Time"

##############################################################################
# Set region to US
# ###########################################################################

Set-Culture en-US
Set-WinSystemLocale en-US
Set-WinUserLanguageList en-US -Force

###############################################################################
# Install .Net Framework 3.5
# #############################################################################

Install-WindowsFeature NET-Framework-Core -Source E:\sources\sxs

################################################################################
# Enable and configure WinRM
################################################################################

Set-NetFirewallRule -Name WINRM-HTTP-In-TCP-PUBLIC -RemoteAddress Any
Enable-WSManCredSSP -Force -Role Server
set-wsmanquickconfig -force

$outFile = "E:\vmtools\setup64.exe"

Write-Host "Running E:\vmtools\setup64.exe"
& "$outFile" /S /v/qn REBOOT=R

#autostart
sc.exe config WinRM start=auto

# Allow unencrypted
Enable-PSRemoting -Force -SkipNetworkProfileCheck
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'

net stop winrm
Write-host "Sleeping for 1 minute, then restarting"
start-sleep -s 120
#Configure NIC as Env has no DHCP
$netadapter = Get-NetAdapter -Name Ethernet0
## Disable DHCP
$netadapter | Set-NetIPInterface -DHCP Disabled
# Disable IPv6
Disable-NetAdapterBinding -InterfaceAlias Ethernet0 -ComponentID ms_tcpip6
# Configure the IP address and default gateway for "VM Network" in Env
$netadapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress 172.26.42.241 -PrefixLength 24 -Type Unicast -DefaultGateway 172.26.42.1
# Reboot system
shutdown /r /c "packer restart" /t 8
