#Set-ExecutionPolicy Bypass

#. "$PSScriptRoot\ICS.ps1"
#. .\ICS.ps1

#Static link
#https://download.wireguard.com/windows-client/wireguard-installer.exe

#Let's checking if wireguard is installed via the registry

$software = "Wireguard";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null

#Download and install wireguard if not already installed

If(-Not $installed) {
	#Write-Host "'$software' NOT is installed.";
    #Create a folder called wg with a date to save the installer into
    $current_date = Get-Date -Format MMddyyyyHHmm
    $new_folder_path = "C:\Users\$env:USERNAME\Downloads\wg-" + $current_date
    New-Item -Path $new_folder_path -ItemType Directory

    Invoke-WebRequest https://download.wireguard.com/windows-client/wireguard-installer.exe -OutFile "$new_folder_path\wireguard-installer.exe"
    $wireguard_installer = "$new_folder_path\wireguard-installer.exe"

    #Start the installer
    Start-Process -Wait -FilePath "$new_folder_path\wireguard-installer.exe"
} else {
   	Write-Host "'$software' is already installed."

}
 
#Write-Host "Let's look for a P81 config file in the current directory"

#mypath = $MyInvocation.MyCommand.Path
#Write-Output "Path of the script : $mypath"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#Write-Output "Current Directory : $scriptPath"
#Write-Host "Let's look for the proper file"
$p81_file_list = Get-ChildItem -Path $scriptPath

$p81_file_name = ""


#Let's look for a file inside this foldre that does not have an extension ps1 and contains a string support@perimeter81.com
foreach($file in $p81_file_list){
    #Write-Host $file
    if ((Get-Content $file.FullName) -match "support@perimeter81.com" -And $file.FullName -notmatch "ps1" ) {
        $p81_file_name = $file.FullName
    }

}

#Write-Host $p81_file_name

$current_CONFIG_pubkey = Get-Content $p81_file_name | Select-String -Pattern "^CONFIG"
$CONFIG_array=$current_CONFIG_pubkey -split "`n"

#Write-Host $CONFIG_array


$config_array_cleanedup=@()
#$config_array_cleanedupNew=New-Object 'system.collections.generic.dictionary[string,string]'

Remove-Item $scriptPath\Perimeter81.conf

$publicKey = ""
$privateKey = ""
$endpoint = ""
$address = ""
$allowedIP = ""
$ifname = ""
$port = ""
$p81subnet = ""


foreach ($item in $CONFIG_array){
    $item_string = ($item.Split('#')[0] -split "=", 2)
    #write-host $item_string
    $first_element = $item_string.Split(" ")[0]
    $second_element = $item_string.Split(" ")[1].replace("`"","")
    #write-host $first_element



    if($first_element.Contains("pubKey")){$publicKey = $second_element}
    if($first_element.Contains("privateKey")){$privateKey = $second_element}
    if($first_element.Contains("endpoint")){$endpoint = $second_element}
    if($first_element.Contains("address")){$address = $second_element}
    if($first_element.Contains("allowedIP")){$allowedIP = $second_element}
    #if($first_element.Contains("ifname"){$ifname = $second_element}
    if($first_element.Contains("CONFIG_port")){$port = $second_element}
    if($first_element.Contains("p81subnet")){$p81subnet = $second_element}

    #write-host $first_element `t`t $second_element

    #Out-File -FilePath

    #$config_array_cleanedup.Add[$first_element] = $second_element

}

#Break

#This is a rerall bad way to do this but I can't figure out disctionaries in PS
"[Interface]" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"PrivateKey = $privateKey" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"ListenPort = $port" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"Address = $address" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
" " | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"[Peer]" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"PublicKey = $publicKey" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"AllowedIPs = $allowedIP" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"Endpoint = $endpoint" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append
"PersistentKeepalive = 10" | Out-File -FilePath $scriptPath\Perimeter81.conf -Append

#write-host $config_array_cleanedup


$wireguardServiceName = Get-Service -Displayname "*wireguard tunnel*"

#write-host $wireguardServiceName.Status
#write-host $wireguardServiceName.Name


if ($wireguardServiceName.Status -ne "Running"){
#MOVE DOWN AFTER the config file is ready
Start-Process -Wait -FilePath "C:\Program Files\WireGuard\wireguard.exe" -ArgumentList "/installtunnelservice C:\Users\user\Downloads\wg\Perimeter81.conf" -Verb RunAs

}

$ISCService = Get-Service -Name "*SharedAccess*"
#write-host $ISCService.Status

Set-Service -Name SharedAccess -StartupType Automatic
Set-Service -Name SharedAccess -Status Running

#$rebootPersistKey = "EnableRebootPersistConnection";
$registryPathSharedAccess = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess"



$regCheck=Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess -Name EnableRebootPersistConnection | select -ExpandProperty EnableRebootPersistConnection


if ($regCheck -ne '1') {
    New-ItemProperty -Path $registryPathSharedAccess -Name 'EnableRebootPersistConnection' -Value 1 -PropertyType DWord
}

Break

<#
foreach ($item in $CONFIG_array){
    $result = New-Object psobject
    $result | Add-Member -MemberType NoteProperty -Name "Field_Name" -Value ($item -split "=")[0]
    $result | Add-Member -MemberType NoteProperty -Name "Field_Value" -Value (($item -split "=",2)[1]).replace("`"","")
    Write-Host $result
    $config_array_cleanedup +=$result
}
foreach($line in $config_array_cleanedup){
    Write-Host $line['Field_Name']

}
#>

#$CONFIG_array.field_value[1]

#write-host $p81_file_name










<#
#$current_CONFIG_pubkey_split = $current_CONFIG_pubkey -split 
#region Input Network Adapter
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Network Interface'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select a Network Interface:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

$all_net_adapters  = Get-NetAdapter

foreach ($nic in $all_net_adapters.name){
    #[void] $listBox.Items.Add('atl-dc-001')
    [void] $listBox.Items.Add($nic)}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
    $x
}

$selected_adapter = Get-NetAdapter | Where-Object {$_.Name -eq $x}
$selected_adapter.InterfaceAlias
#endregion

#>



#Requires -Version 3.0 -Modules NetAdapter
function Set-MrInternetConnectionSharing {

<#
.SYNOPSIS
    Configures Internet connection sharing for the specified network adapter(s).
 
.DESCRIPTION
    Set-MrInternetConnectionSharing is an advanced function that configures Internet connection sharing
    for the specified network adapter(s). The specified network adapter(s) must exist and must be enabled.
    To enable Internet connection sharing, Internet connection sharing cannot already be enabled on any
    network adapters.
 
.PARAMETER InternetInterfaceName
    The name of the network adapter to enable or disable Internet connection sharing for.
 
 .PARAMETER LocalInterfaceName
    The name of the network adapter to share the Internet connection with.
 .PARAMETER Enabled
    Boolean value to specify whether to enable or disable Internet connection sharing.
.EXAMPLE
    Set-MrInternetConnectionSharing -InternetInterfaceName Ethernet -LocalInterfaceName 'Internal Virtual Switch' -Enabled $true
.EXAMPLE
    'Ethernet' | Set-MrInternetConnectionSharing -LocalInterfaceName 'Internal Virtual Switch' -Enabled $false
.EXAMPLE
    Get-NetAdapter -Name Ethernet | Set-MrInternetConnectionSharing -LocalInterfaceName 'Internal Virtual Switch' -Enabled $true
.INPUTS
    String
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateScript({
            If ((Get-NetAdapter -Name $_ -ErrorAction SilentlyContinue -OutVariable INetNIC) -and (($INetNIC).Status -ne 'Disabled' -or ($INetNIC).Status -ne 'Not Present')) {
                $True
            }
            else {
                Throw "$_ is either not a valid network adapter of it's currently disabled."
            }
        })]
        [Alias('Name')]
        [string]$InternetInterfaceName,

        [ValidateScript({
            If ((Get-NetAdapter -Name $_ -ErrorAction SilentlyContinue -OutVariable LocalNIC) -and (($LocalNIC).Status -ne 'Disabled' -or ($INetNIC).Status -ne 'Not Present')) {
                $True
            }
            else {
                Throw "$_ is either not a valid network adapter of it's currently disabled."
            }
        })]
        [string]$LocalInterfaceName,

        [Parameter(Mandatory)]
        [bool]$Enabled
    )

    BEGIN {
        if ((Get-NetAdapter | Get-MrInternetConnectionSharing).SharingEnabled -contains $true -and $Enabled) {
            Write-Warning -Message 'Unable to continue due to Internet connection sharing already being enabled for one or more network adapters.'
            Break
        }

        regsvr32.exe /s hnetcfg.dll
        $netShare = New-Object -ComObject HNetCfg.HNetShare
    }
    
    PROCESS {
        
        $publicConnection = $netShare.EnumEveryConnection |
        Where-Object {
            $netShare.NetConnectionProps.Invoke($_).Name -eq $InternetInterfaceName
        }

        $publicConfig = $netShare.INetSharingConfigurationForINetConnection.Invoke($publicConnection)

        if ($PSBoundParameters.LocalInterfaceName) {
            $privateConnection = $netShare.EnumEveryConnection |
            Where-Object {
                $netShare.NetConnectionProps.Invoke($_).Name -eq $LocalInterfaceName
            }

            $privateConfig = $netShare.INetSharingConfigurationForINetConnection.Invoke($privateConnection)
        } 
        
        if ($Enabled) {
            $publicConfig.EnableSharing(0)
            if ($PSBoundParameters.LocalInterfaceName) {
                $privateConfig.EnableSharing(1)
            }
        }
        else {
            $publicConfig.DisableSharing()
            if ($PSBoundParameters.LocalInterfaceName) {
                $privateConfig.DisableSharing()
            }
        }

    }

}

#Requires -Version 3.0
function Get-MrInternetConnectionSharing {

<#
.SYNOPSIS
    Retrieves the status of Internet connection sharing for the specified network adapter(s).
 
.DESCRIPTION
    Get-MrInternetConnectionSharing is an advanced function that retrieves the status of Internet connection sharing
    for the specified network adapter(s).
 
.PARAMETER InternetInterfaceName
    The name of the network adapter(s) to check the Internet connection sharing status for.
 
.EXAMPLE
    Get-MrInternetConnectionSharing -InternetInterfaceName Ethernet, 'Internal Virtual Switch'

.EXAMPLE
    'Ethernet', 'Internal Virtual Switch' | Get-MrInternetConnectionSharing

.EXAMPLE
    Get-NetAdapter | Get-MrInternetConnectionSharing

.INPUTS
    String
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string[]]$InternetInterfaceName
    )

    BEGIN {
        regsvr32.exe /s hnetcfg.dll
        $netShare = New-Object -ComObject HNetCfg.HNetShare
    }

    PROCESS {
        foreach ($Interface in $InternetInterfaceName){
        
            $publicConnection = $netShare.EnumEveryConnection |
            Where-Object {
                $netShare.NetConnectionProps.Invoke($_).Name -eq $Interface
            }
            
            try {
                $Results = $netShare.INetSharingConfigurationForINetConnection.Invoke($publicConnection)
            }
            catch {
                Write-Warning -Message "An unexpected error has occurred for network adapter: '$Interface'"
                Continue
            }

            [pscustomobject]@{
                Name = $Interface
                SharingEnabled = $Results.SharingEnabled
                SharingConnectionType = $Results.SharingConnectionType
                InternetFirewallEnabled = $Results.InternetFirewallEnabled
            }
            
        }
    
    }    

}

#Get-MrInternetConnectionSharing -InternetInterfaceName "Ethernet"

#Set-MrInternetConnectionSharing -InternetInterfaceName Ethernet -LocalInterfaceName 'Perimeter81' -Enabled $true
