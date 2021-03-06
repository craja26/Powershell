#Task:
#Copy newly genereated backup files to target server without override existing backup files in the destination directory.

#Below is the powershell script to copy past 24  hours backups from source to target server. Here we need to specify source and destination folders, output log file and temporary output log file.
#if you want to schedule this task, save below code as .ps1 file then create a SQL Server agent job.

#Declare output log file
$output_file = "G:\MSSQL\Joblog\copy_files_Repl_$((get-date).ToString("_yyyyMMdd_HHmmss"))_log.log"

#Declare temporary output file to store verbose results in it, then will move results into main output file.
$temp_output = "G:\MSSQL\Joblog\temp_copy_files_Repl_log.log"
#Start-Transcript -Path $out_File


# Enter source directory
$source = 'G:\MSSQL\Backup\<Source_Server>\'
if($source[-1] -ne "\") {$source += "\"}  #adding backslash if not exists at end

# Enter destination directory
$destination = '\\<Destination-Server>\g$\MSSQL\Backup-<DEST-SERVERNAME>\'
if($destination[-1] -ne "\") {$destination += "\"}  #adding backslash if not exists at end

#$file_list = Get-ChildItem -Path $source  -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object{  Get-ChildItem -Path $_.FullName|Where-Object{$_.Mode -eq '-a----'}|Select-Object Name, mode, directory, FullName}
Try{
	#checking source and destination directories
<#	If(!(Test-Path -Path $source )){
		Write-Output "$([DateTime]::Now) : Please choose valid source($source) directory."| Out-File $output_file -Append
		#exit
		Break
	}elseif(!(Test-Path -Path $destination )){
		Write-Output "$([DateTime]::Now) : Please choose valid destination($destination) directory." | Out-File $output_file -Append
		#exit
		Break
	}
#>
	$file_list = Get-ChildItem -Path $source  -Recurse -Directory -Force -ErrorAction Stop | ForEach-Object{  Get-ChildItem -Path $_.FullName|Where-Object{$_.Mode -eq '-a----'} | Where-Object {$_.CreationTime -gt (Get-Date).AddHours(-24)} |Select-Object Name, mode, directory, FullName}
	
	#verifying source directory whether have files or not.
	if($file_list.Count -eq 0){
		Write-Output "No files are available to copy. Please check source directory." | Out-File $output_file -Append
		Break
	}

	$file_list|foreach{$copy_file = $_.FullName.replace($source, $destination)
		If(Test-Path -Path $copy_file){
			"$copy_file is exists at destination directory." | Out-File $output_file -Append
		}
		Else{
			$dest_folder = $copy_file.replace($_.name,'')
			If(!(Test-Path -Path $dest_folder)){
				mkdir $dest_folder 
				"$([DateTime]::Now) : Created new directory $dest_folder"| Out-File $output_file -Append -encoding utf8
			}
			"Copy Start: " + "$([DateTime]::Now)" | out-file $output_file -Append
			# copy files, storing output in a temp log file. Data in this file is flushed once another file is copying.
			Copy-Item -path $_.FullName -Destination ($dest_folder) -verbose *> $temp_output 
			
			#appending temp log file information into output file.
			Get-Content $temp_output | Out-File $output_file -Append
			"Copy End: " + "$([DateTime]::Now) `n" | out-file $output_file -Append
		}	
	}
}catch [System.Exception]{
	"An error occured while trying to process files. Please check the manual!" | Out-File $output_file -Append
	$_ | Out-File $output_file -Append -encoding utf8
}
