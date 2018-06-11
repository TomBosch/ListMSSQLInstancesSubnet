#Scan subnet /24 for MS SQL instances and savin in MS SQL Server database "Inventory"
#11/06/2018
#Version 0.1
#Bosch Tom
#
#Install dbatools module
##Install-Module dbatools 
#Import-Module dbatools

#IP address parts for start IP address:
$IPpart1 = 192
$IPpart2 = 168
$IPpart3 = 0
$IPpart4 = 10

#Open connection to SQL server
#Give your SQLserver
$SQLServer = "SERVERNAME\INSTANCENAME"
#Give the database name
$Database = "DBNAME"
#Give the table name
$Table = "TABLENAME"
#Give the SQL user that can write to database
$SQLUser = "SQLUSER" 
#Give the password
$Password = "TypeInPasswordHere" | ConvertTo-SecureString -AsPlainText -Force
$Password.MakeReadOnly()
#Create Connection string
[string]$connectionString = "Data Source=$SQLServer;Initial Catalog=$Database;"
$cred = New-Object System.Data.SqlClient.SqlCredential($SQLUser,$Password)
#Create new connection string object
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$SqlConnection.credential = $cred
#Open SQL connection
$SqlConnection.Open()


while ($IPpart4 -lt 254) {
$IPexcists = $false
#Compose Ip address
$IPAddress = $IPpart1.ToString() + "." + $IPpart2.ToString() + "." + $IPpart3.ToString() + "." + $IPpart4.ToString()
#create new SQLCommand object
$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $SqlConnection
#T-SQL command to view if there is already a row with this IP address
$Command.CommandText = "SELECT * FROM [$Database].[dbo].[$Table] WHERE IPAddress = '$IPAddress'"
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

#$eID = $Datatable.Rows[0].ID
#$eInstanceName = $Datatable.Rows[0].InstanceName
#$ePort = $Datatable.Rows[0].Port
}
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

#if there is already a row for this IP address compose an update query else compose an insert query
if($IPexcists)
{
#compose update query with values from Find-DbaInstance
$query = “UPDATE [$Database].[dbo].[$Table] SET [InstanceName]='$InstanceName',[Port]='$Port',[Version]='$Version',[ComputerName]='$Computername' WHERE [ID]='$eID'"
}
else
{
#compose insert query with values from Find-DbaInstance
$query = “INSERT INTO [$Database].[dbo].[$Table]([ID],[InstanceName],[Port],[IPAddress],[Version],[ComputerName])VALUES(NEWID(),'$InstanceName','$Port','$IPAddress','$Version','$Computername')"
}

#create new sqlcommand object
$sqlcmd = $SqlConnection.CreateCommand()
$sqlcmd = New-Object System.Data.SqlClient.SqlCommand
$sqlcmd.Connection = $SqlConnection
$sqlcmd.CommandText = $query
#Execute query
$sqlcmd.ExecuteNonQuery()
}
#Go to next IP address
$IPpart4++
}
#Close SQL connection
$SqlConnection.Close()
