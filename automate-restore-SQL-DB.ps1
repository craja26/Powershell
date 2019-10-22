# Below script restores database automatically. It identifies list for data and log files in the backup then generate and execute restore script.
# We need to provide backup directory, target data and log file locations.

# Backup directory for SQLLogging
$BackupDir = "C:\SQLBackup\NB0168\SQLLogging\FULL"
if($BackupDir[-1] -ne "\") {$BackupDir += "\"}  #adding backslash if not exists at end

# provide your database name where you want to change database properties
# $DatabaseName = "Maint"
$DatabaseName = "SQLLogging_2"

# Declare destination data and log file paths
$dest_data_file_path = "C:\SQL Server\Database\Data"
if($dest_data_file_path[-1] -ne "\") {$dest_data_file_path += "\"}  #adding backslash if not exists at end
$dest_log_file_path = "C:\SQL Server\Database\Log"
if($dest_log_file_path[-1] -ne "\") {$dest_log_file_path += "\"}  #adding backslash if not exists at end

# Output report for SQL Server restore
$out_restore = "C:\temp\Logs\log_drop_restore_SQLLoing_2_$(get-date -f yyyy-MM-dd-HH-mm)_log.txt"

# Get latest file in the directory For SQLLogging
$Latest_bak = Get-ChildItem -Path $BackupDir | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$Backup_full_name = $Latest_bak.fullname


# Connect to SQL Server
Import-Module SQLPS
cd SQLSERVER:\SQL

# SQL Server Instance Name
$SQLInstanceName = "Localhost"
$Server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $SQLInstanceName
 

# DROP and RESTORE Process starts from here
# create SMO handle to your database IS_GAME
$DBObject_SQLLogging_2 = $Server.Databases[$DatabaseName]
 
# check database exists on server IS_GAME
if ($DBObject_SQLLogging_2)
{
	# instead of drop we will use KillDatabase
	# KillDatabase drops all active connections before dropping the database.
	$Server.KillDatabase($DatabaseName) *> $out_restore
}

$file_list = Invoke-Sqlcmd -ServerInstance $SQLInstanceName -Query "RESTORE FILELISTONLY FROM  DISK = '$Backup_full_name' WITH NOUNLOAD" | Select -Property LogicalName,PhysicalName,type, FileGroupName, FileGroupId
$i = 1
$j = 1
$RelocateData = @()
$file_list|ForEach{ if($_.type -eq 'D'){
		$_.LogicalName
		if($_.FileGroupId -eq 1){
			if($i -eq 1){
				$temp_filename = "_data.mdf"
				$RelocateData += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, "$dest_data_file_path$DatabaseName$temp_filename")				
				$i = $i+1
			}else{
				$temp_filename = "_data_$i.ndf"
				$RelocateData += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, "$dest_data_file_path$DatabaseName$temp_filename")
				$i = $i+1
			}			
		}else{
			$temp_filename = "_"+$_.FileGroupName+"_Data_$i.ndf"
			$RelocateData += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, "$dest_data_file_path$DatabaseName$temp_filename")
			$i = $i+1
		}		
	}ElseIf($_.type -eq 'L'){
		$temp_filename = "_log_$j.ldf"
		$RelocateData += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, "$dest_log_file_path.$DatabaseName$temp_filename")		
		$j = $i+1
	}
}
write-host "$BackupDir$Latest_bak"

Restore-SqlDatabase -ServerInstance $SQLInstanceName -Database $DatabaseName -BackupFile "$Backup_full_name" -RelocateFile @($RelocateData) -Verbose *> $out_restore 

