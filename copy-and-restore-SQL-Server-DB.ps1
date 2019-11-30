#Find and copy latest backup file from shared folder to local directory then restore on SQL Server instance.

#Copy file "DB_NAME" backup to new location
#Creating variables for source and destination folders.
$OriginalDir_DB_Name = "\\<Shared folder>\DB_Name\FULL\"
$BackupDir_Local = "X:\SQLBackup\ServerName\DB_Name\FULL\"

#declaring outputfile
$out_File = "X:\Powershell\Logs\log_copy_IRON_Maint_$(get-date -f yyyy-MM-dd-HH-mm)_log.txt" 

#Getting latest file name.
$LatestFile_DB_Name = Get-ChildItem -Path $OriginalDir_DB_Name | Sort-Object LastAccessTime -Descending | Select-Object -First 1

#Copy file to destination
Copy-Item -path "$OriginalDir_DB_Name\$LatestFile_DB_Name" "$BackupDir_Local\$LatestFile_DB_Name"
"$([DateTime]::Now)" + "`t$OriginalDir_DB_Name\$LatestFile_DB_Name`t is copied onto $BackupDir_Local"| out-file $out_File -Append

#Output report for SQL Server restore
$out_restore = "E:\Powershell\Logs\log_drop_restore_DB_Name_$(get-date -f yyyy-MM-dd-HH-mm)_log.txt"


#Connect to SQL Server
Import-Module SQLPS
cd SQLSERVER:\SQL

#SQL Server Instance Name
$SQLInstanceName = "Localhost"
$Server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $SQLInstanceName


#provide your database name where you want to change database properties
#$DatabaseName = "Maint"

$DatabaseName = "DB_NAME"

# DROP and RESTORE Process starts from here
#create SMO handle to your database IS_GAME
$DBObject_DB_Name = $Server.Databases[$DatabaseName]
 
#check database exists on server IS_GAME
if ($DBObject_DB_Name)
{
#instead of drop we will use KillDatabase
#KillDatabase drops all active connections before dropping the database.
$Server.KillDatabase($DatabaseName) *> $out_restore
}

# Restore database IS_GAME:
$RelocateData_DB_Name = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("DB_NAME_Data", "D:\MSSQL\MSSQL14.MSSQLSERVER\MSSQL\DATA\DB_NAME_Data.mdf")
$RelocateLog_DB_Name = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("DB_NAME_Log", "D:\MSSQL\MSSQL14.MSSQLSERVER\MSSQL\DATA\DB_NAME_Log.ldf")
Restore-SqlDatabase -ServerInstance $SQLInstanceName -Database $DatabaseName -BackupFile "$BackupDir_IS_GAME\$LatestFile_DB_Name" -RelocateFile @($RelocateData_DB_Name,$RelocateLog_DB_Name) -Verbose *> $out_restore 


