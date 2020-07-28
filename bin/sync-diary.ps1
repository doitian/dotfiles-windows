rclone sync -v "$([Environment]::GetFolderPath("Desktop"))\diary\" "onedrive:Sync\$($env:COMPUTERNAME)\"
