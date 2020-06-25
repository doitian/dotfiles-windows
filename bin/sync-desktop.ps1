rclone sync -v "$([Environment]::GetFolderPath("Desktop"))\" "onedrive:Sync\$($env:COMPUTERNAME)\"
