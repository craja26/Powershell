#I want to get version builds report for selected servers
#create powershell file and execute below code.
#.\PatchReport.ps1 -Email "craja26@gmail.com" -srv_list @("server1", "server2","server3")
param($srv_list, $email)
$result_set = @()
$matched_srv = @()
for ( $i = 0; $i -lt $srv_list.count; $i++ ){
	write-host "Host  $i+1 is $($srv_list[$i])"
	$srv = $srv_list[$i]
	$Connection = New-Object System.Data.SQLClient.SQLConnection
	$Connection.ConnectionString = "Server= $srv;Integrated Security=true;Initial Catalog=master;"
	$Connection.Open()
	$Command = New-Object System.Data.SQLClient.SQLCommand
	$Command.Connection = $Connection
	# update sql query as per your requirements
	$Command.CommandText = "DECLARE  @temp_build_list TABLE(version varchar(100), build_number varchar(100))

	INSERT INTO @temp_build_list VALUES('SQL Server 2012','11.0.3500')
	INSERT INTO @temp_build_list VALUES('SQL Server 2014','12.0.4500')
	INSERT INTO @temp_build_list VALUES('SQL Server 2016','13.0.5923')
	INSERT INTO @temp_build_list VALUES('SQL Server 2017','14.0.1000.169')
	INSERT INTO @temp_build_list VALUES('SQL Server 2019','15.0.3200')

	DECLARE @srv_ver varchar(50)
	IF NOT EXISTS(SELECT version from @temp_build_list WHERE build_number = SERVERPROPERTY('PRODUCTVERSION'))
	BEGIN
		DECLARE @cur_version varchar(30), @compatability varchar(10), @req_version varchar(30)
		SET @cur_version = CONVERT(varchar(30), SERVERPROPERTY('PRODUCTVERSION'))
		SET @compatability = SUBSTRING(@cur_version,1, (CHARINDEX('.',@cur_version)-1))
		SET @req_version = (SELECT build_number FROM @temp_build_list WHERE build_number like @compatability+'%')
		SELECT  @@SERVERNAME as SERVERNAME, SERVERPROPERTY('PRODUCTLEVEL') as PRODUCTLEVEL, SERVERPROPERTY('PRODUCTVERSION') as CURRENT_VERSION, @req_version AS REQUIRED_VERSION, 0 as STATUS
	END
	ELSE
	BEGIN
		SELECT  @@SERVERNAME as SERVERNAME, SERVERPROPERTY('PRODUCTLEVEL') as PRODUCTLEVEL, SERVERPROPERTY('PRODUCTVERSION') as CURRENT_VERSION, SERVERPROPERTY('PRODUCTVERSION') AS REQUIRED_VERSION, 1 as STATUS
	END"
	$Reader = $Command.ExecuteReader()
	$intCounter = 0
	while($Reader.Read())
	 {
		$SERVERNAME = $Reader["SERVERNAME"].ToString()    
		$PRODUCTLEVEL = $Reader["PRODUCTLEVEL"].ToString()
		$CURRENT_VERSION = $Reader["CURRENT_VERSION"].ToString()	
		$REQUIRED_VERSION = $Reader["REQUIRED_VERSION"].ToString()
		$STATUS = $Reader["STATUS"].ToString()
		Write-Host "$SERVERNAME $PRODUCTLEVEL $intCounter"
		$result_set += New-Object psObject -Property @{'SERVERNAME'=$SERVERNAME;'PRODUCTLEVEL'=$PRODUCTLEVEL;'CURRENT_VERSION' = $CURRENT_VERSION; 'REQUIRED_VERSION' = $REQUIRED_VERSION; 'STATUS' = $STATUS}
		$intCounter++
	 }  
	 if($intCounter -eq 0){
		$matched_srv += New-Object psObject -Property @{'MATCHED_SRV' = $srv}
	 }
	$Connection.Close()
	
}

#$result_set
$tr1 = ''
$tr2 = ''
if ($result_set.count -gt 0){
	$j = 1; $k = 1
	for($i = 0; $i -lt $result_set.length; $i++){
		if( $($result_set[$i].STATUS) -eq "0"){
			$tr1 = $tr1 + "<tr><td>$j</td><td>$($result_set[$i].SERVERNAME)</td><td>$($result_set[$i].PRODUCTLEVEL)</td> <td>$($result_set[$i].CURRENT_VERSION)</td><td>$($result_set[$i].REQUIRED_VERSION)</td></tr>";
			$j++
		}else{
			$tr2 = $tr2 + "<tr><td>$k</td><td>$($result_set[$i].SERVERNAME)</td><td>$($result_set[$i].PRODUCTLEVEL)</td> <td>$($result_set[$i].CURRENT_VERSION)</td><td>Build matched</td></tr>";
			$k++
		}		
	}
	if($j -eq 1){
		$tr1 = $tr1 + '<tr><td colspan="5">All server are matching with provided build numbers.</td></tr>';
	}
	if($k -eq 1){
		$tr2 = $tr2 + '<tr><td colspan="5">All server build numbers are not matching.</td></tr>';
	}
}else{
	$tr1 = $tr1 + '<tr><td colspan="5">All server are matching with provided build numbers.</td></tr>';
	#write-host "All server versions are matched with existing list."
}
	#HTML code
		$header = "<head><style> .tbl {  font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;  border-collapse: collapse;  width: 100%;}
		.tbl td, .tbl th {  border: 1px solid #ddd;  padding: 8px;}
		.tbl tr:nth-child(even){background-color: #f2f2f2;}
		.tbl tr:hover {background-color: #ddd;}
		.tbl tr.bgc:hover {background-color: #FF0000;}
		.tbl th {  padding-top: 12px;  padding-bottom: 12px;  text-align: left;  background-color: #4CAF50;  color: white;}
		</style></head>"
		
		$table = "<table class='tbl'><tr><th>Slno</th><th>SERVERNAME</th><th>PRODUCTLEVEL</th><th>CURRENT_VERSION</th><th>REQUIRED_VERSION</th></tr>$tr1</table>"
		$table2 = "<table class='tbl'><tr><th>Slno</th><th>SERVERNAME</th><th>PRODUCTLEVEL</th><th>CURRENT_VERSION</th><th>STATUS</th></tr>$tr2</table>"
		$body = "<html>$header<body><h4>Below SQL Server instances may required upgrade.</h4>$table"
		$body += "<h4>Below SQL Server instances build number matched with provided build#.</h4>"+$table2+"</body></html>"
		$User = "craja26@gmail.com"
		$pass = ConvertTo-SecureString "<Password>" -AsPlainText -Force
		$Credential = New-Object System.Management.Automation.PSCredential($User,$pass)

		$From = "craja26@gmail.com"
		$To = $email
		$Subject = "Server List - Version not matching"
		#$body = $body
		$SMTPServer = "smtp.gmail.com"
		$SMTPPort = "587"
		Send-MailMessage -From $From -to $To -Subject $Subject -Body $body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $Credential
	write-host "Server list sent to $email"
