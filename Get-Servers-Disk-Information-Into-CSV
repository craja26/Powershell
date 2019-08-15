#**********Exporting servers disk information into a CSV file ***********#

$LogDate = Get-Date -Format "MM-dd-yyyy HH:mm:ss"

#Getting server names from a text file. 
$File = Get-Content -Path "C:\AUTOMATION\DISK_Collection\ServerName.txt"

#declaring output file to store results.
$OutputFile = "C:\AUTOMATION\DISK_Collection\REPORTS\DiskReport.CSV"

#store error information in a text file.
$ErrorOutput = "C:\AUTOMATION\DISK_Collection\OUTPUT\Host_Not_Reachable.txt"

#clear output and error log files data 
Clear-Content $OutputFile
Clear-Content $ErrorOutput

#loop servers then fetch disk information and save into a CSV file
ForEach ($Servernames in ($File)) 
{
	try
	{
		write-host $Servernames

		Get-WmiObject win32_volume -ComputerName $Servernames -Filter { DriveType=3 and name like '%:%' }   -ErrorAction Stop | 
		Select-Object @{Label = "Server_Name";Expression = {$Servernames}},
		@{Label = "Drive_letter";Expression = {$_.Name}},
		@{Label = "Total_Capacity_GB";Expression = {"{0:F1}" -f( $_.Capacity / 1GB)}},
		@{Label = "Free_Space_GB";Expression = {"{0:F1}" -f( $_.Freespace / 1GB ) }},
		@{Label = 'Free_Space_Prec'; Expression = {"{0:F1}" -f (($_.Freespace/$_.Capacity)*100)}} ,
		@{Label = 'Date'; Expression = {$LogDate}}  | Export-Csv -path $OutputFile -NoTypeinformation -APPEND
	}
	catch 
	{
		write-host "$Servernames : Exception Message: $($_.Exception.Message)" -ForegroundColor Red 
		$Servernames + ' | ' +  $_.Exception.Message | Out-File $ErrorOutput -Append
	}
}
