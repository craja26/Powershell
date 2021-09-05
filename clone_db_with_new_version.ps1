#function for checking connection
function check-connection($connection_str_db1){
    write-host "Connection String: " $connection_str_db1
    TRY{
		$Connection = New-Object System.Data.SQLClient.SQLConnection
		$Connection.ConnectionString = $connection_str_db1#"Server= $srv;Integrated Security=false;Initial Catalog=master;uid=$username; pwd=$password;"
		$Connection.Open()
		#$Command = New-Object System.Data.SQLClient.SQLCommand
		#$Command.Connection = $Connection
		# update sql query as per your requirements
		#$Command.CommandText = $sqlcmd
		#$Reader = $Command.ExecuteReader()
		#$intCounter = 0
        #$report_out = @()
        #$Datatable = New-Object System.Data.DataTable
        #$Datatable.Load($Reader)
		#$report_out
        #$result_set
        #return $Datatable
		$Connection.Close()
        return $true
	}CATCH{
		write-host "$instance $($_.Exception.Message)."		
        return $false
	}
}
function get-sql-query-results($connection_str, $sqlcmd){
    $srv = "localhost"
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
        $report_out = @()
        $Datatable = New-Object System.Data.DataTable
        $Datatable.Load($Reader)
		# while($Reader.Read())
		#  {
		# 	$name = $Reader["name"].ToString()    
		# 	$database_id = $Reader["database_id"].ToString()
		# 	#Write-Host "$SERVERNAME $PRODUCTLEVEL $intCounter"
        #     $report = New-Object -TypeName PSObject
        #     $report | Add-Member -MemberType NoteProperty -Name 'Name' -Value $name
        #     $report | Add-Member -MemberType NoteProperty -Name 'database_id' -Value $database_id
		# 	$report_out += $report
		# 	$intCounter++
		#  }  
		 $report_out
         #$result_set
         
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
#write-host "password is: " $password
$new_db_name = ""
$current_db_name = ""
$last_full_backup
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
$sqlcmd_db_info = "SELECT  name , 
	SUBSTRING(name, PATINDEX('%[0-9]%', name), PATINDEX('%[0-9][^0-9]%', name + 't') - PATINDEX('%[0-9]%', name) + 1) + 5 AS new_db_version,
    CASE WHEN PATINDEX('%[a-z]%', REVERSE(name)) > 1
        THEN LEFT(name, LEN(name) - PATINDEX('%[a-z]%', REVERSE(name)) + 1)
    ELSE '' END AS db_string_part,
    recovery_model_desc ,
    state_desc ,
    d AS 'last_full_backup' ,
    i AS 'Last Differential Backup' ,
    l AS 'Last log Backup'--, physical_device_name
FROM (SELECT db.database_id ,db.name ,
            db.state_desc ,
            db.recovery_model_desc ,
            type ,
            backup_finish_date--, bmf.physical_device_name
	FROM  master.sys.databases db
        LEFT OUTER JOIN msdb.dbo.backupset a ON a.database_name = db.name 
		--LEFT OUTER JOIN msdb.dbo.backupmediafamily bmf ON a.media_set_id = bmf.media_set_id
		where database_id > 4 and db.is_distributor <> 1 AND db.name like 'STG_Web%' 
    ) AS Sourcetable 
PIVOT 
    ( MAX(backup_finish_date) FOR type IN ( D, I, L ) ) AS MostRecentBackup"

[array]$result_db_info = @(get-sql-query-results $connection_str_db1 $sqlcmd_db_info)
write-host "Second-SQL Result: " $result_db_info.name.Count
if ($result_db_info.name.Count -eq 1){
    ForEach($row_db_info in $result_db_info){    
        #write-host "row $i Database name: " $row_db_info.name
        #write-host "row $i new_db_version: " $row_db_info.new_db_version
        #write-host "row $i Last_full_backup: " $row_db_info.last_full_backup    
        #write-host "row $i db_string_part: " $row_db_info.db_string_part 
        $new_db_name = $row_db_info.db_string_part + $row_db_info.new_db_version
        $current_db_name = $row_db_info.name
        $last_full_backup = $row_db_info.last_full_backup
        $i++
    }
}elseif($result_db_info.name.Count -gt 1){
    write-host "There are two web db exists. Might forgot to drop old database or something went wrong. Please check..."
    exit
}else{
    write-host "There is no web db exists. Please check..."
    exit
}
$i = 1
    
write-host "current web database name: " $current_db_name
write-host "New web database name: " $new_db_name
