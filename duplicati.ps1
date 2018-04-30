cls

###
# API URLS
#
$urlSysteminfo ="http://10.4.4.21:8200/api/v1/Systeminfo"
#ServerVersion, OSType, MachineName,CLROSInfo
$urlServerstate ="http://10.4.4.21:8200/api/v1/serverstate"
#programState, UpdatedVersion, UpdateState, ProposedSchedule, HasWarning, HasError, LastEventID, LastDataUpdateID, LastNotificationUpdateID
$urlServersettings ="http://10.4.4.21:8200/api/v1/serversettings"
$urlNotifications ="http://10.4.4.21:8200/api/v1/notifications"
$urlBackups ="http://10.4.4.21:8200/api/v1/backups/" 
$urlBackup = "http://10.4.4.21:8200/api/v1/backup/"







$Headers = @{
    #"Host" = "10.4.4.21:8200"
    #"User-Agent" = "Mozilla/5.0 (Windows NT 10.0; …) Gecko/20100101 Firefox/59.0"
    #"Accept" = "application/json, text/plain, */*"
    #"Accept-Language" = "de,en;q=0.7,en-US;q=0.3"
    #"Content-Type" = ""
    "X-XSRF-Token" = "G4KrlO23/uDtfi7wRoEwbvHSRDUF/9YCJBkkoaMJ6Dc="
    #"Referer" = "http://10.4.4.21:8200/ngax/index.html"
    #"Content-Length" = ""
    #"Cookie" = "xsrf-token=G4KrlO23%2FuDtfi7wR…aMJ6Dc%3D; default-theme=ngax"
    "Cookie" = "xsrf-token=G4KrlO23%2FuDtfi7wR…aMJ6Dc%3D"
    #"Connection" = "keep-alive"
    #"Pragma" = "no-cache"
    #"Cache-Control" = "no-cache, max-age=0"
}


#$Url = "http://10.4.4.21:8200/api/v1/backup/1/remotelog/"

#$Url = "http://10.4.4.21:8200/api/v1/backup/2/information"
#$backups = Invoke-RestMethod -Uri $Url -Method GET -Headers $Headers -ContentType application/json
#write-host $backups



<#
$backups = Invoke-RestMethod -Uri $urlBackups -Method GET -Headers $Headers -ContentType application/json

#remove unnecessary chars
$backups =  $backups.Substring(6)
$backups = $backups.Substring(0,$backups.Length -2  )

#split into json objects
$arrBackups = $backups -split '},
  {'

#fixing the json objects
for ($i=0; $i -lt $arrBackups.Length; $i++){
    #write-host "i: " + $i;

   
    if($i -eq 0){
         # fixing first json object
        $arrBackups[0] = $arrBackups[0] + "}"

    }elseif($i -eq $arrBackups.Length - 1){
        # fixing last json object
        $arrBackups[$i] = "{" + $arrBackups[$i]

    }else{
        # fixing middle json objects
        $arrBackups[$i] = "{" + $arrBackups[$i] + "}"

    }  
}
#write-host $arrBackups[0]

#>

<#
write-host $arrBackups[1]
$json=ConvertFrom-Json $arrBackups[1]
$json.schedule.lastrun
#>




function get_backups{
    
    $backups = Invoke-RestMethod -Uri $urlBackups -Method GET -Headers $Headers -ContentType application/json

    #remove unnecessary chars
    $backups =  $backups.Substring(6)
    $backups = $backups.Substring(0,$backups.Length -2  )

    #split into json objects
    $arrBackups = $backups -split '},
  {'


    #fixing the json objects
    for ($i=0; $i -lt $arrBackups.Length; $i++){
   
        if($i -eq 0){
            # fixing first json object
            #write-host "fixing first"
            $arrBackups[0] = $arrBackups[0] + "}"

        }elseif($i -eq $arrBackups.Length - 1){
            # fixing last json object
            #write-host "fixing last"
            $arrBackups[$i] = "{" + $arrBackups[$i]

        }else{
            # fixing middle json objects
            #write-host "fixing others"
            $arrBackups[$i] = "{" + $arrBackups[$i] + "}"
            #write-host $arrBackups[$i] -f Green
        }  
    }

    write-host $arrBackups -f Yellow

    $j=0;
    foreach ($backup in $arrBackups){
        $json=ConvertFrom-Json $backup
        #$json.Backup.ID
        $backup_ids += @($json.Backup.ID) 
        $j++

    }



    return $backup_ids
}


function get_backup_info($backup_ids){
    foreach ($backupID in $backup_ids){
        #write-host "ID: " $backupID
        $backupJson = Invoke-RestMethod -Uri $urlBackup$backupID -Method GET -Headers $Headers -ContentType application/json
        write-host $backupJson -f Gray

        #remove unnecessary chars
        $backupJson =  $backupJson.Substring(3)
        $backupJson = ConvertFrom-Json $backupJson

        $backup_info += @($backupJson)

        
        #write-host "success: " $backupJson.success
        #write-host "ID: " $backupJson.data.Backup.ID
        #write-host "--------------" -f Green

    }

    return $backup_info
}

$backup_info = get_backup_info(get_backups)

#write-host "Count:" $backup_info.Count

for($i=0; $i -lt $backup_info.Count; $i++){
    write-host "Name:" $backup_info[$i].data.backup.name
    write-host "ID:" $backup_info[$i].data.backup.id
    write-host "success:" $backup_info[$i].success
    write-host "LastStart:" $backup_info[$i].data.backup.metadata.LastStarted
    write-host "LastFinished:" $backup_info[$i].data.backup.metadata.LastFinished
    write-host "LastDuration:" $backup_info[$i].data.backup.metadata.LastDuration

    write-host ""
}

#$backup_ids = get_backups

#write-host $backup_ids.Length

#$backup = Invoke-RestMethod -Uri $urlBackup -Method GET -Headers $Headers -ContentType application/json
#write-host $backup