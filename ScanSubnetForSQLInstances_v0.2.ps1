#Scan subnet /24 for MS SQL instances and savin in MS SQL Server database "Inventory" and table "Instances"
#Write output to log file with SQL query's
#13/06/2018
#Version 0.2
#Bosch Tom
#
##Install-Module sqlserver
#Import-Module sqlserver
##Install-Module dbatools 
#Import-Module dbatools

#Location and file for logging output
#Change variable Disklocation
$Disklocation = "E:\PATH\queryinstance"
$Date = get-date -Format FileDateTime
$file= $Disklocation + $Date + ".log"

#Give IP address parts for start address: IP address = IPpart1 + IPpart2 + IPpart3 + IPpart4
$IPpart1 = 192
$IPpart2 = 168
$IPpart3 = 0
$IPpart4 = 10

#Give part 4 for end address: IP address = IPpart1 + IPpart2 + IPpart3 + EndIPpart4
$EndIPpart4 = 254

#Give parameters from your database server
#Give your SQLserver
$SQLServer = "SERVERNAME\INSTANCENAME"
#Give the SQL user that can write to database
$SQLUser = "SQLUSER" 
#Give the password
$Password = "TypeInPasswordHere" | ConvertTo-SecureString -AsPlainText -Force
$Password.MakeReadOnly()

#Function is copy (with little change in output) from https://gallery.technet.microsoft.com/scriptcenter/Invoke-TSPingSweep-b71f1b9b
function Invoke-TSPingSweep {
  <#
    .SYNOPSIS
    Scan IP-Addresses, Ports and HostNames

    .DESCRIPTION
    Scan for IP-Addresses, HostNames and open Ports in your Network.
    
    .PARAMETER StartAddress
    StartAddress Range

    .PARAMETER EndAddress
    EndAddress Range

    .PARAMETER ResolveHost
    Resolve HostName

    .PARAMETER ScanPort
    Perform a PortScan

    .PARAMETER Ports
    Ports That should be scanned, default values are: 21,22,23,53,69,71,80,98,110,139,111,
    389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,
    5801,5900,5555,5901

    .PARAMETER TimeOut
    Time (in MilliSeconds) before TimeOut, Default set to 100

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost -ScanPort

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost -ScanPort -TimeOut 500

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.10.254 -ResolveHost -ScanPort -Port 80

    .LINK
    http://www.truesec.com

    .NOTES
    Goude 2012, TrueSec
  #>
  Param(
    [parameter(Mandatory = $true,
      Position = 0)]
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
    [string]$StartAddress,
    [parameter(Mandatory = $true,
      Position = 1)]
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
    [string]$EndAddress,
    [switch]$ResolveHost,
    [switch]$ScanPort,
    [int[]]$Ports = @(21,22,23,53,69,71,80,98,110,139,111,389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,5801,5900,5555,5901),
    [int]$TimeOut = 100
  )
  Begin {
    $ping = New-Object System.Net.Networkinformation.Ping
  }
  Process {
    foreach($a in ($StartAddress.Split(".")[0]..$EndAddress.Split(".")[0])) {
      foreach($b in ($StartAddress.Split(".")[1]..$EndAddress.Split(".")[1])) {
        foreach($c in ($StartAddress.Split(".")[2]..$EndAddress.Split(".")[2])) {
          foreach($d in ($StartAddress.Split(".")[3]..$EndAddress.Split(".")[3])) {
            write-progress -activity PingSweep -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100)
            $pingStatus = $ping.Send("$a.$b.$c.$d",$TimeOut)
            if($pingStatus.Status -eq "Success") {
              if($ResolveHost) {
                write-progress -activity ResolveHost -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100) -Id 1
                $getHostEntry = [Net.DNS]::BeginGetHostEntry($pingStatus.Address, $null, $null)
              }
              if($ScanPort) {
                $openPorts = @()
                for($i = 1; $i -le $ports.Count;$i++) {
                  $port = $Ports[($i-1)]
                  write-progress -activity PortScan -status "$a.$b.$c.$d" -percentcomplete (($i/($Ports.Count)) * 100) -Id 2
                  $client = New-Object System.Net.Sockets.TcpClient
                  $beginConnect = $client.BeginConnect($pingStatus.Address,$port,$null,$null)
                  if($client.Connected) {
                    $openPorts += $port
                  } else {
                    # Wait
                    Start-Sleep -Milli $TimeOut
                    if($client.Connected) {
                      $openPorts += $port
                    }
                  }
                  $client.Close()
                }
              }
              if($ResolveHost) {
                $hostName = ([Net.DNS]::EndGetHostEntry([IAsyncResult]$getHostEntry)).HostName
              }
              # Return Object
              New-Object PSObject -Property @{
                IPAddress = "$a.$b.$c.$d";
                HostName = $hostName;
                Ports = $openPorts
              } | Select-Object IPAddress, HostName, Ports
            }
          }
        }
      }
    }
  }
  End {
  }
}

#Open connection to SQL server
#Give the database name
$Database = "Inventory"
#Give the table name
$Table = "Instances"
#Create Connection string
[string]$connectionString = "Data Source=$SQLServer;Initial Catalog=$Database;"
$cred = New-Object System.Data.SqlClient.SqlCredential($SQLUser,$Password)
#Create new connection string object
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$SqlConnection.credential = $cred
#Open SQL connection
$SqlConnection.Open()

while ($IPpart4 -lt $EndIPpart4) {
$IPexcists = $false
#Compose Ip address
$IPAddress = $IPpart1.ToString() + "." + $IPpart2.ToString() + "." + $IPpart3.ToString() + "." + $IPpart4.ToString()
$IPAddress | Out-File -Append $file

Try{
#Scan IP address if host excists
$Scan = Invoke-TSPingSweep -StartAddress $IPAddress -EndAddress $IPAddress
}
Catch { "Error: No such host is known" | Out-File -Append $file }

if ($Scan.IPAddress) {

#Search for SQL instances on this IP address
try{$SQLInstance = Find-DbaInstance -ScanType Browser,SqlConnect -DiscoveryType IPRange -IpAddress $IPAddress}
Catch{$error= "error"}

#if there are SQL instances then read line per line
foreach($line in $SQLInstance)
{
#get values from SQL instance
$InstanceName = $line.InstanceName
$Port = $Line.Port
$Version = $line.BrowseReply.Version
$Computername = $line.BrowseReply.ComputerName

#create new SQLCommand object
$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $SqlConnection
#T-SQL command to view if there is already a row with this IP address
$Command.CommandText = "SELECT * FROM [$Database].[dbo].[$Table] WHERE IPAddress = '$IPAddress' AND Port = '$Port'"
#Execute select SQL command
$Reader = $Command.ExecuteReader()
#Create new datatable object
$Datatable = New-Object System.Data.DataTable
#Fill datatable with values from select command
$Datatable.Load($Reader)
#If there is a row in the datatable then tere is already a row with this IP address
if($DataTable.Rows.Count -eq 1 ){
#set variable IPexcist to true
$IPexcists = $true
$eID = $Datatable.Rows[0].ID
$eInstanceName = $Datatable.Rows[0].InstanceName
$ePort = $Datatable.Rows[0].Port
$eVersion = $Datatable.Rows[0].Version
#$eID = $Datatable.Rows[0].ID
#$eInstanceName = $Datatable.Rows[0].InstanceName
#$ePort = $Datatable.Rows[0].Port
}

#if there is already a row for this IP address compose an update query else compose an insert query
if($IPexcists)
{
#compose update query with values from Find-DbaInstance
$query = “UPDATE [$Database].[dbo].[$Table] SET [InstanceName]='$InstanceName',[Port]='$Port',[Version]='$Version',[ComputerName]='$Computername' WHERE [ID]='$eID'"
$query | Out-File -Append $file 
}
else
{
#NEW SQL INstance found send e-mail?
#compose insert query with values from Find-DbaInstance
$query = “INSERT INTO [$Database].[dbo].[$Table]([ID],[InstanceName],[Port],[IPAddress],[Version],[ComputerName])VALUES(NEWID(),'$InstanceName','$Port','$IPAddress','$Version','$Computername')"
$query | Out-File -Append $file
}

#create new sqlcommand object
$sqlcmd = $SqlConnection.CreateCommand()
$sqlcmd = New-Object System.Data.SqlClient.SqlCommand
$sqlcmd.Connection = $SqlConnection
$sqlcmd.CommandText = $query
#Execute query
$sqlcmd.ExecuteNonQuery()
}
}
#Go to next IP address
$IPpart4++
}
#Close SQL connection
$SqlConnection.Close()
