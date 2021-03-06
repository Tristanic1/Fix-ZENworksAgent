Import-Module ActiveDirectory

$Machine = Read-Host "Please enter Hostname or IP address"

# Check if it's IP address or Hostname
if ($Machine -notmatch "[a-z]") {
    $Computer = ([System.Net.Dns]::GetHostByAddress($Machine).Hostname).SubString(0,8)
} else {
    $Computer = $Machine
}

# Get Administrator password from AD (LAPS - Local Administrator Password Solution activated)
$Password = Get-ADComputer -Identity $Computer -Properties ms-Mcs-AdmPwd | select -ExpandProperty ms-Mcs-AdmPwd

$psexec = ".\psexec.exe"

# Take the first two letters from the computer name for the ZENworks key
$zenkey = $computer.SubString(0,2)

# Open remote registry
$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $machine)

# Get the Build  Version from the Registry
$RegKey= $Reg.OpenSubKey("SOFTWARE\\ADATUM")                                                                    
$Build=$RegKey.GetValue("BuildVersion") 

# Add the BuildVersion value to the computer type, like PC101
if ($zenkey -eq 'MR' -Or $zenkey -eq 'CR') { 
    $zenkey = 'PC' + $build 
} else {
      $zenkey = $zenkey + $build
}
        
$command = "zac unr -f -u zacreg -p Passw0rd && zac reg https://zcm.adatum.com -k $zenkey -u zacreg -p Passw0rd"

# Execute script via psexec
& $psexec \\$machine -u administrator -p $Password cmd /c $command