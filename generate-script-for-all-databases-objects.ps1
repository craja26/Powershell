$servername = 'Localhost' #Enter server name
$options = New-DbaScriptingOption
$options.DriAllConstraints =$true
$options.NonClusteredIndexes  =$true
$options.ClusteredIndexes  =$true
$options.DriForeignKeys = $true
$options.IncludeIfNotExists = $true
$database_list =Get-DbaDatabase -SqlInstance NB0168 -ExcludeDatabase model,master,tempdb, msdb -Status Normal |select name
foreach($database in $database_list){ 
	$database.name
	#$database = 'AdventureWorks'
	$FileName_table = 'C:\temp\'+$servername+'-Export\'+$database.name+'-'+(Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")+'_table_script.sql'
	$FileName_udf = 'C:\temp\'+$servername+'-Export\'+$database.name+'-'+(Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")+'_UDF_script.sql'
	$FileName_user = 'C:\temp\'+$servername+'-Export\'+$database.name+'-'+(Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")+'_user_script.sql'
	#create file
	New-Item  $FileName_table -ItemType File -Force
	New-Item  $FileName_udf -ItemType File -Force
	New-Item  $FileName_user -ItemType File -Force
	
	Get-DbaDbTable -SqlInstance $servername -Database $database.name | Export-DbaScript -ScriptingOptionsObject $options -FilePath $FileName_table -Append 
	Get-DbaDbUdf -SqlInstance $servername -Database $database.name | Export-DbaScript -ScriptingOptionsObject $options -FilePath $FileName_udf -Append 
	Get-DbaDbUser -SqlInstance $servername -Database $database.name | Export-DbaScript -ScriptingOptionsObject $options -FilePath $FileName_user -Append 
}
