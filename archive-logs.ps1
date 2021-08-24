# Default execution will zip up and move logs from log directory older than 6 days to archive directory 
# and delete/upload to s3 archived logs older than 30 days
# 
# Example Usage:
# .\archive-logs.ps1 "C:\inetpub\logs\LogFiles" "C:\ArchiveLogs"
#

[CmdletBinding()]
param (
    # e.g. C:\inetpub\logs\LogFiles
    [Parameter()]
    [string]
    $LogDirectory,

    # e.g. C:\ArchiveLogs
    [Parameter()]
    [string]
    $ArchiveDirectory,

    [Parameter()]
    [int]
    $DaysToKeep = -2,

    [Parameter()]
    [int]
    $DaysToUpload = -30
)

if (-not (Test-Path -Path "$LogDirectory")) {
  throw "$LogDirectory does not exist."
}

if (!(Test-Path -Path $ArchiveDirectory -PathType Container)) {
  New-Item -ItemType directory -Path $ArchiveDirectory 
}

# zip and move from iis logs older that 7 days
$logs = Get-ChildItem -Recurse -Path $LogDirectory -Attributes !Directory -Filter *.log  | Where-Object -FilterScript {
  $_.LastWriteTime -lt (Get-Date).AddDays($DaysToKeep)  
}

foreach ($log in $logs) {
  $name = $log.name 
  $directory = $log.DirectoryName 
  $directoryName = $log.Directory.Name 
  $zipFile = $name.Replace('.log','.zip') 
  $lastWriteTime = $log.LastWriteTime #gets the lastwritetime of the file

  $fullFileName = "$directory\$name"
  $fullZipFile = "$directory\$zipFile"
  $destination = "$ArchiveDirectory\$directoryName"

  if (!(Test-Path -Path $destination -PathType Container)) {
    New-Item -ItemType directory -Path $destination 
  }
  
  Compress-Archive -Path $fullFileName -DestinationPath $fullZipFile 

  Get-ChildItem  $fullZipFile | % {$_.LastWriteTime = $lastWriteTime}
  Remove-Item -Path $fullFileName   
  Move-Item $fullZipFile -Destination $destination -force
}

# # upload to s3 from archive directory zipped logs older than 30 days 
# $logs = Get-ChildItem -Recurse -Path $ArchiveDirectory -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {
#   $_.LastWriteTime -lt (Get-Date).AddDays($DaysToUpload)  
# }

# foreach ($log in $logs) {
#   $name = $log.name 
#   $directory = $log.DirectoryName 

#   # should be uploading to s3 instead.
#   #Remove-Item -Path "$directory\$name"   
# }

exit 0
