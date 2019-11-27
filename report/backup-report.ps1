#Backup report
# variable $error_str will capture connection error information. 
$error_str = ''
$secpasswd = ConvertTo-SecureString "xxxxxxxxxxx" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("backup_reader", $secpasswd)

$csv_file = "c:\temp\backup_report_$((get-date).ToString("_yyyyMMdd_HHmmss")).csv"

$csv_instance = Import-Csv "c:\temp\Server_list.csv"
$csv_instance | ForEach-Object{
	$instance = $_.instance_name
	TRY{
		Invoke-Sqlcmd -InputFile "C:\temp\backup-replort-daily.sql" -ServerInstance $instance -Credential $mycreds -ErrorAction 'Stop' | Export-csv $csv_file -notypeInformation -append
	}CATCH{
		$error_str +="$instance "+":"+" $($_.Exception.Message)"+"<br/>"		
	}	
}
IF($error_str -ne ''){
	$error_str = "<p class='tbl' style='color:red;'>Script failed to run following server(s):</p><p class='tbl'>$error_str</p>"
}


$slno = 1
$tr = ''
$csv_backup_report = Import-Csv $csv_file
$csv_backup_report | ForEach-Object{
	$instance = $_.instance_name
	$database_name = $_.database_name
	$recovery_model = $_.recovery_model
	$state_desc = $_.state_desc
	$last_full_backup = $_.last_full_backup
	$last_differential_backup = $_.last_differential_backup
	$last_log_backup = $_.last_log_backup
	
	$get_date = GET-DATE
	IF($last_full_backup -ne ""){
		$days_diff_full = New-TimeSpan -Start $last_full_backup -End $get_date
		$days_diff_full = $days_diff_full.TotalDays
	}
	IF($last_differential_backup -ne ""){
		$hours_diff_diff = New-TimeSpan -Start $last_differential_backup -End $get_date
		$hours_diff_diff = $hours_diff_diff.TotalHours
	}
	IF($last_log_backup -ne ""){
		$hour_diff_log = New-TimeSpan -Start $last_log_backup -End $get_date
		$hour_diff_log = $hour_diff_log.TotalHours
	}	
	IF($recovery_model -eq "FULL"){
		IF( ($last_full_backup -eq "") -or ($last_differential_backup -eq "") -or ($last_log_backup -eq "") -or ($days_diff_full -gt 7) -or ($hours_diff_diff -gt 24) -or ($hour_diff_log -gt 12)){
			$tr += "<tr style='background-color:red;'><td>$slno</td><td>$instance</td><td>$database_name</td><td>$recovery_model</td><td>$state_desc</td><td>$last_full_backup</td><td>$last_differential_backup</td><td>$last_log_backup</td></tr>"
			#bgcolor="#FF0000"
		}ELSE{
			$tr += "<tr><td>$slno</td><td>$instance</td><td>$database_name</td><td>$recovery_model</td><td>$state_desc</td><td>$last_full_backup</td><td>$last_differential_backup</td><td>$last_log_backup</td></tr>"
		}
	}
	ELSE{
		IF( ($last_full_backup -eq "") -or ($last_differential_backup -eq "") -or ($days_diff_full -gt 7) -or ($hours_diff_diff -gt 24) ){
			$tr += "<tr style='background-color:red;'><td>$slno</td><td>$instance</td><td>$database_name</td><td>$recovery_model</td><td>$state_desc</td><td>$last_full_backup</td><td>$last_differential_backup</td><td>$last_log_backup</td></tr>"
			#bgcolor="#FF0000"
		}ELSE{
			$tr += "<tr><td>$slno</td><td>$instance</td><td>$database_name</td><td>$recovery_model</td><td>$state_desc</td><td>$last_full_backup</td><td>$last_differential_backup</td><td>$last_log_backup</td></tr>"
		}
	}
	
	$slno += 1
}
$header = "<head><style> .tbl {  font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;  border-collapse: collapse;  width: 100%;}
	.tbl td, .tbl th {  border: 1px solid #ddd;  padding: 8px;}
	.tbl tr:nth-child(even){background-color: #f2f2f2;}
	.tbl tr:hover {background-color: #ddd;}
	.tbl tr.bgc:hover {background-color: #FF0000;}
	.tbl th {  padding-top: 12px;  padding-bottom: 12px;  text-align: left;  background-color: #4CAF50;  color: white;}
	</style></head>"

$table = "$error_str <p class='tbl'>Backup Report:</p><table class='tbl'><tr><th>Slno</th><th>Instance</th><th>Database</th><th>Recovery Model</th><th>State</th><th>Last Full Backup</th><th>Last Differential Backup</th><th>Last Log Backup</th>$tr</table>"
$body = "<html>$header<body>$table</body></html>"

function fn-Send-Email(){
	Param([parameter(Mandatory=$true)] [String]$emailTo, [parameter(Mandatory=$true)] [String]$subject, [parameter(Mandatory=$true)] [String]$body, $attachment, $cc )
	$emailSmtpServer = "smtp.mail.domaint.com"
	$emailSmtpServerPort = "587"
	$emailSmtpUser = "<email-id>"
	$emailSmtpPass = "<password>"
	 
	$emailFrom = "dba@domain.com"
	$emailTo = $emailTo
	$emailcc=$cc
	 
	$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
	if($cc -eq ""){
		$emailMessage.cc.add($emailcc)
	}	
	$emailMessage.Subject = $subject
	$emailMessage.IsBodyHtml = $true #true or false depends
	$emailMessage.Body = $body
	 
	$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
	$SMTPClient.EnableSsl = $False
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );
	TRY{
		$SMTPClient.Send( $emailMessage )
		return 1
	}CATCH{
		return 0
	}
}

fn-Send-Email "raja.chikkala@domain.com" "Backup report $((get-date).ToString('dd-MM-yyy'))" -body $body
