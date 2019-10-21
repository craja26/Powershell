#Declare output log file
$output_file = "G:\MSSQL\JobLog\Remove_files_$(get-date -f yyyy-MM-dd-HH-mm)_log.log"

#Declare temporary output file to store verbose results in it, then will move results into main output file.
$temp_output = "G:\MSSQL\JobLog\temp_remove_files_log.log"
#Start-Transcript -Path $out_File


# Enter source directory
$source = 'G:\MSSQL\Backup\SERVER_NAME\'
if($source[-1] -ne "\") {$source += "\"}  #adding backslash if not exists at end

Try{
	
	$file_list_log = Get-ChildItem -Path $source  -Filter "LOG" -Recurse -Directory -Force -ErrorAction Stop | ForEach-Object{  Get-ChildItem -Path $_.FullName|Where-Object{$_.Mode -eq '-a----'} | Where-Object {$_.LastWriteTime -lt (Get-Date).AddHours(-48) } |Select-Object Name, mode, directory, FullName}
	Write-Output "Deleting old from SERVER_NAME server"| Out-File $output_file -Append 
    Write-Output "=============****************=============="| Out-File $output_file -Append 
	#verifying source directory whether have files or not.
	if($file_list_log.Count -eq 0){
		Write-Output "LOG: No files are available to delete. Please check source directory." | Out-File $output_file -Append 
	}else{
		$file_list_log|foreach{ $remove_file_log = $_.FullName
			If(Test-Path -Path $remove_file_log){
				"Deleted file at " + "$([DateTime]::Now)" | out-file $output_file -Append
				Remove-Item $remove_file_log -verbose *> $temp_output 
				#appending temp log file information into output file.
				Get-Content $temp_output | Out-File $output_file -Append
			}
		}
	}  

	$file_list_full = Get-ChildItem -Path $source  -Filter "FULL" -Recurse -Directory -Force -ErrorAction Stop | ForEach-Object{  Get-ChildItem -Path $_.FullName|Where-Object{$_.Mode -eq '-a----'} | Where-Object {$_.LastWriteTime -lt (Get-Date).AddHours(-250) } |Select-Object Name, mode, directory, FullName}
	
	#verifying source directory whether have files or not.
	if($file_list_full.Count -eq 0){
		Write-Output "FULL: No files are available to delete. Please check source directory." | Out-File $output_file -Append 
	}else{
		$file_list_full|foreach{ $remove_file_full = $_.FullName
			If(Test-Path -Path $remove_file_full){
				"Deleted file at " + "$([DateTime]::Now)" | out-file $output_file -Append
				Remove-Item $remove_file_full -verbose *> $temp_output 
				#appending temp log file information into output file.
				Get-Content $temp_output | Out-File $output_file -Append
			}
		}
	}
	$file_list_diff = Get-ChildItem -Path $source  -Filter "DIFF" -Recurse -Directory -Force -ErrorAction Stop | ForEach-Object{  Get-ChildItem -Path $_.FullName|Where-Object{$_.Mode -eq '-a----'} | Where-Object {$_.LastWriteTime -lt (Get-Date).AddHours(-72) } |Select-Object Name, mode, directory, FullName}
	
	#verifying source directory whether have files or not.
	if($file_list_diff.Count -eq 0){
		Write-Output "DIFF: No files are available to delete. Please check source directory." | Out-File $output_file -Append 
		Break
	}

	$file_list_diff|foreach{ $remove_file_diff = $_.FullName
	
		If(Test-Path -Path $remove_file_diff){
			"Deleted file at " + "$([DateTime]::Now)" | out-file $output_file -Append
			Remove-Item $remove_file_diff -verbose *> $temp_output 
			#appending temp log file information into output file.
			Get-Content $temp_output | Out-File $output_file -Append
		}
			
	}
}catch [System.Exception]{
	"An error occured while trying to process files. Please check the manual!" | Out-File $output_file -Append 
	$_ | Out-File $output_file -Append
}
