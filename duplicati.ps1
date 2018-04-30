cls

### Duplicati Server URL
$url ="http://10.4.4.21:8200/index.html"


### API URLS
$urlSysteminfo ="http://10.4.4.21:8200/api/v1/Systeminfo"
#ServerVersion, OSType, MachineName,CLROSInfo
$urlServerstate ="http://10.4.4.21:8200/api/v1/serverstate"
#programState, UpdatedVersion, UpdateState, ProposedSchedule, HasWarning, HasError, LastEventID, LastDataUpdateID, LastNotificationUpdateID
$urlServersettings ="http://10.4.4.21:8200/api/v1/serversettings"
$urlNotifications ="http://10.4.4.21:8200/api/v1/notifications"
$urlBackups ="http://10.4.4.21:8200/api/v1/backups/" 
$urlBackup = "http://10.4.4.21:8200/api/v1/backup/"


### start by loading duplicati index.html
$headers = @{
"Accept"='text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8';
"Upgrade-Insecure-Requests"="1";
}

Invoke-WebRequest -Uri $url -Method GET -Headers $headers -SessionVariable SFSession | Out-Null


#Gets required tokens
$headers = @{
"Accept"='application/xml, text/xml, */*; q=0.01';
"Content-Length"="0";
"X-Requested-With"="XMLHttpRequest";
"X-Citrix-IsUsingHTTPS"="Yes";
"Referer"=$url;
}

Invoke-WebRequest -Uri ($url) -Method POST -Headers $headers -WebSession $sfsession|Out-Null


$xsrf = $sfsession.cookies.GetCookies($url)|where{$_.name -like "xsrf-token"}


###Setting the Header
$Headers = @{
    "X-XSRF-Token" = [System.Net.WebUtility]::UrlDecode($xsrf.value)
    "Cookie" = "$xsrf"
}


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

    #write-host $arrBackups -f Yellow

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
        #write-host $backupJson -f Gray

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
    write-host "SourceFilesSize (Byte):" $backup_info[$i].data.backup.metadata.SourceFilesSize
    $backupSourceFilesSize = $backup_info[$i].data.backup.metadata.SourceFilesSize
    $backupSourceFilesSize = [math]::round($backupSourceFilesSize / [math]::pow(1024,3),2)
    write-host "SourceFilesSize (GB):" $backupSourceFilesSize


    write-host ""
}

#$backup_ids = get_backups

#write-host $backup_ids.Length

#$backup = Invoke-RestMethod -Uri $urlBackup -Method GET -Headers $Headers -ContentType application/json
#write-host $backup


#$urlBackupLog = "http://10.4.4.21:8200/api/v1/backup/1/log"
#$backupLog = Invoke-RestMethod -Uri $urlBackupLog -Method GET -Headers $Headers -ContentType application/json
#write-host $backupLog