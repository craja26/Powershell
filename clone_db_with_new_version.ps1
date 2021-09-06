#function for checking connection
function check-connection($connection_str_db1){
    TRY{
		$Connection = New-Object System.Data.SQLClient.SQLConnection
		$Connection.ConnectionString = $connection_str_db1#"Server= $srv;Integrated Security=false;Initial Catalog=master;uid=$username; pwd=$password;"
		$Connection.Open()
		$Connection.Close()
        return $true
	}CATCH{
		write-host "$instance $($_.Exception.Message)."		
        return $false
	}
}
function get-sql-query-results($connection_str, $sqlcmd){
    TRY{
		$Connection = New-Object System.Data.SQLClient.SQLConnection
		$Connection.ConnectionString = $connection_str
		$Connection.Open()
		$Command = New-Object System.Data.SQLClient.SQLCommand
		$Command.Connection = $Connection
		# update sql query as per your requirements
		$Command.CommandText = $sqlcmd
		$Reader = $Command.ExecuteReader()
		$intCounter = 0
        $Datatable = New-Object System.Data.DataTable
        $Datatable.Load($Reader)
		$Connection.Close()
        return $Datatable
	}CATCH{
		write-host "$instance $($_.Exception.Message)."		
	}
}
$username = "sa"
$password = Read-Host 'What is your password?' -AsSecureString
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
$server_db1 = "localhost"
$server_db2 = "."
$database = "SQLLogging"
$web_db_str = "STAGE_Web" 
$new_db_name = ""
$current_db_name = ""
$last_full_backup
$backup_old_days
$backup_file
$required_backup_type
$backup_command
$result_set = @()
$result_db_info = @()
# Check server db1 connection
#$sqlcmd = "select name, database_id from sys.databases"
$connection_str_db1 = "Server= $server_db1;Integrated Security=false;Initial Catalog=master;uid=$username; pwd=$password; Database=$database"
$connection_status = check-connection $connection_str_db1 #$sqlcmd
if ($connection_status -eq "True"){
    write-host "DB1 server connected successfully."
}else{
    write-host "Not able to connect DB1 server, please check connection properties..."
    exit
}

#check server db2 connection
$connection_str_db2 = "Server= $server_db2;Integrated Security=false;Initial Catalog=master;uid=$username; pwd=$password; Database=$database"
$connection_status = check-connection $connection_str_db2
if ($connection_status -eq "True"){
    write-host "DB2 server connected successfully."
}else{
    write-host "Not able to connect DB2 server, please check connection properties..."
    exit
}
# Get latest DB backup information
$sqlcmd_db_info = "DECLARE @row_cnt int
IF OBJECT_ID('tempdb..#temp_db_backup_info') IS NOT NULL DROP TABLE #temp_db_backup_info
IF OBJECT_ID('tempdb..#temp_physical_file') IS NOT NULL DROP TABLE #temp_physical_file
CREATE TABLE #temp_db_backup_info(slno int identity(1,1)
	, name varchar(100)
	, new_db_version int
	, last_full_backup datetime
	, last_differential_backup datetime
	, last_log_backup datetime
	, last_full_backup_physical_file varchar(2000)
	, backup_old int)
CREATE TABLE #temp_physical_file(slno int identity(1,1), database_name varchar(100), physical_device_name varchar(500),backup_finish_date datetime)
INSERT INTO #temp_db_backup_info(name, new_db_version, last_full_backup, last_differential_backup, last_log_backup)
SELECT  name , 
	SUBSTRING(name, PATINDEX('%[0-9]%', name), PATINDEX('%[0-9][^0-9]%', name + 't') - PATINDEX('%[0-9]%', name) + 1) + 5 AS new_db_version,
    d AS 'last_full_backup' ,
    i AS 'last_differential_backup' ,
    l AS 'last_log_backup'
FROM (SELECT db.database_id ,db.name ,
            db.state_desc ,
            db.recovery_model_desc ,
			type ,
            backup_finish_date
	FROM  master.sys.databases db
        LEFT OUTER JOIN msdb.dbo.backupset a ON a.database_name = db.name 
		where database_id > 4 and db.is_distributor <> 1 AND db.name like '$web_db_str'--'BSG-STAGE_Web%' 
    ) AS Sourcetable 
PIVOT 
    ( MAX(backup_finish_date) FOR type IN ( D, I, L ) ) AS MostRecentBackup
SET @row_cnt = @@ROWCOUNT
IF (@row_cnt = 1)
BEGIN
	INSERT INTO #temp_physical_file(database_name, physical_device_name, backup_finish_date)
	SELECT TOP 1
		bs.database_name,
		bmf.physical_device_name,
		bs.backup_finish_date
	FROM   msdb.dbo.backupmediafamily AS bmf
	INNER JOIN msdb.dbo.backupset AS bs ON bmf.media_set_id = bs.media_set_id 
		WHERE bs.database_name in (select name from #temp_db_backup_info) AND (CONVERT(datetime, bs.backup_start_date, 102) >= GETDATE() - 17)
		AND bs.type = 'D' 
	ORDER BY 
		bs.backup_start_date desc
END
UPDATE tbi SET backup_old = DATEDIFF(day, tbi.last_full_backup, GETDATE()), tbi.last_full_backup_physical_file = tpf.physical_device_name
FROM  #temp_db_backup_info tbi INNER JOIN #temp_physical_file tpf ON tbi.name = tpf.database_name WHERE tbi.last_full_backup = tpf.backup_finish_date
SELECT slno, name, new_db_version, last_full_backup, last_differential_backup, last_full_backup_physical_file
FROM #temp_db_backup_info
IF OBJECT_ID('tempdb..#temp_db_backup_info') IS NOT NULL DROP TABLE #temp_db_backup_info
IF OBJECT_ID('tempdb..#temp_physical_file') IS NOT NULL DROP TABLE #temp_physical_file"

[array]$result_db_info = @(get-sql-query-results $connection_str_db1 $sqlcmd_db_info)
write-host "Second-SQL Result count: " $result_db_info.name.Count
if ($result_db_info.name.Count -eq 1){
    ForEach($row_db_info in $result_db_info){    
        $new_db_name        = $web_db + $row_db_info.new_db_version
        $current_db_name    = $row_db_info.name
        $last_full_backup   = $row_db_info.last_full_backup
        $backup_old_days    = $row_db_info.backup_old
        $backup_file        = $row_db_info.last_full_backup_physical_file
        $i++
    }
    write-host "last full backup: " $backup_file
    if(($backup_file.length -lt 8) -or ($backup_old_days -gt 3)){
        write-host "No recent full backup is available. Creating new DB backup."
        $required_backup_type = "FULL"
        $backup_command = "BACKUP DATABASE [$current_db_name] TO DISK = ''"
    }else{
        $required_backup_type = "DIFF"
    }
}elseif($result_db_info.name.Count -gt 1){
    write-host "There are two web db exists. Might forgot to drop old database or something went wrong. Please check..."
    exit
}else{
    write-host "There is no web db exists. Please check..."
    exit
}


write-host "current web database name: " $current_db_name
write-host "New web database name: " $new_db_name
write-host "Require backup type: " $required_backup_type
