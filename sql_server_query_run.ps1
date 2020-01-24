#Here is the sample code to connect and run SQL Server script on Windows Server 2008R2/ Powershell 2.0

$SQLServer = "SERVER_NAME"
$SQLDBName = "DB_NAME"
$uid ="SQL_Login_id"
$pwd = "Password"
$SqlQuery = "SELECT * from db_name.dbo.table_name;"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; User ID = $uid; Password = $pwd;"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

$DataSet.Tables[0] 

#Note: If want to connect using windows authentication need to specify "Integrated Security = True;" in the connection string.
#Ex: $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True;"
