param([string]$token="",
[string]$mode="",
[string]$channel="#deploy",
[string]$messageid="",
[string]$status="",
[string]$branch="master")
 
 
 Write-Host "APPVEYOR_PULL_REQUEST_NUMBER:" $env:APPVEYOR_PULL_REQUEST_NUMBER
 Write-Host "APPVEYOR_REPO_BRANCH:" $env:APPVEYOR_REPO_BRANCH
 if($env:APPVEYOR_PULL_REQUEST_NUMBER -ne "")
 {
 	 return
 }

$text = " "
$postUrl = "https://slack.com/api/chat.postMessage"
$updateUrl = "https://slack.com/api/chat.update"
$iconUrl = "https://pbs.twimg.com/profile_images/1604347359/logo_512x512_normal.png"

Write-Host "SLACK API TOKEN:" $env:SLACK_API_TOKEN

$selectedAttachment = switch ( $status )
    {
        success 
        {
            '[{
                "fallback": "Required plain-text summary of the attachment.",
                "color": "#228B22",
                "fields": [
                    {
                        "title": "Success",
                        "value": "Deploy LMS release to UAT",
                        "short": false
                    }
                ]
            }]'
        }
        failed 
        {
            '[{
                "fallback": "Required plain-text summary of the attachment.",
                "color": "#FF0000",
                "fields": [
                    {
                        "title": "Failed",
                        "value": "Deploy LMS release to UAT",
                        "short": false
                    }
                ]
            }]'

        }
        default 
        { 
            '[{
                "fallback": "Required plain-text summary of the attachment.",
                "color": "#FFFF00",
                "fields": [
                    {
                        "title": "Pending",
                        "value": "Deploy LMS release to UAT",
                        "short": false
                    }
                ]
            }]'
        }
    }


if($mode -eq "post"){
    $postSlackMessage = @{
        text=$text;
        token=$token;
        channel=$channel;
        attachments = $selectedAttachment;
        username="LMS Deploy"
    }

    $response = Invoke-RestMethod -Uri $postUrl -Body $postSlackMessage 

    if($response.ok)
    {
        $messageId = $response.ts
        $channelId = $response.channel
        Write-Host "Call success!:" $response
        $env:slack_message_id = $messageId
        $env:slack_channel_id = $channelId
    }
    else
    {
        Write-Host "Call failed!:" $response
    }
}

    

if($mode -eq "update") {

    $messageId = $env:slack_message_id
    $channelId = $env:slack_channel_id

    if (-not ([string]::IsNullOrEmpty($messageId)))
    {
    $postSlackMessage = @{
        text=$text;
        token=$token;
        channel=$channelId;
        ts=$messageID;
        attachments=$selectedAttachment;
        username="LMS Deploy"
		}


        $response = Invoke-RestMethod -Uri $updateUrl -Body $postSlackMessage 
    }
    else
    {
     $postSlackMessage = @{
        text=$text;
        token=$token;
        channel=$channel;
        attachments = $selectedAttachment;
        username="LMS Deploy"}
        
        $response = Invoke-RestMethod -Uri $postUrl -Body $postSlackMessage 
    }

    if($response.ok)
    {
        #$messageId = $response.ts
        #$channelId = $response.channel
        Write-Host "Update Call success!:" $response
        
    }
    else
    {
        Write-Host "Update Call failed!:" $response
    }
}