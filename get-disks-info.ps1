#Get all disks information(size in gb, free space in gb and percentage)
gwmi win32_logicaldisk | Format-Table DeviceId, MediaType, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}},@{n="percentage";e={[String]::Format("{0:P2}" -f ([math]::ROUND($_.FreeSpace/$_.Size,2)))}}


