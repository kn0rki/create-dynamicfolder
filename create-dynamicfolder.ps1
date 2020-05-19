Import-Module ActiveDirectory -WarningAction "SilentlyContinue"
$ErrorActionPreference = "STOP"

#domaincontroller
$domaincontroller = "172.30.100.1"

#regex for building the PATH var to grouping servers in royal ts
$regex = '^\w\w\w\w\w(\w\w\w).*'

#get domain credentials
if($null -eq $creds) {
    $creds = (Get-Credential)
}

#get all computeraccounts that starts with SV or CL
$servers = Get-ADComputer -Server $domaincontroller -Credential $creds -Filter { dnshostname -like "SV*" -or dnshostname -like "CL*" }

#sort by dnshostname
$servers = $servers | Sort-Object -Property dnshostname

#empty array to save stuff
$arr = @()

#loop over all found ad computer
$servers.dnshostname | Where-Object { $_ -match $regex } | ForEach-Object {
    $resolv = @()
    #check if there a dns record and get a ip address
    $resolv += Resolve-DnsName -Server $dommaincontroller $Matches[0] -ErrorAction "SilentlyContinue"
    #sometimes are more than one ip addresses defined per dns entry.
    if($resolv.count -gt 1) {
        $resolv = $resolv[0]
    }

    #all set - build item hashtable
    if($null -eq $resolv.ipaddress) {

    }else {
        $arr += @{
            Type            = "RemoteDesktopConnection"
            Name            = ($_).ToUpper()
            Computername    = $resolv.IPAddress
            Path            = ($matches[1]).ToUpper()
            CredentialName  = "adminsh"
        }
    }
}
#put array of hashtables into a hashtable
$obj = @{
    Objects = $arr
}

#convert to json format for royalts
$obj | ConvertTo-Json | Write-Host
