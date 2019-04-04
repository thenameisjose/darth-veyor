param([string]$token="",
[string]$mode="",
[string]$channel="#deploy",
[string]$messageid="",
[string]$status="",
[string]$branch="master"
)
 

 
 Write-Host "APPVEYOR_PULL_REQUEST_NUMBER:" $env:APPVEYOR_PULL_REQUEST_NUMBER
 Write-Host "APPVEYOR_REPO_BRANCH:" $env:APPVEYOR_REPO_BRANCH
 Write-Host "APPVEYOR_PULL_REQUEST_TITLE:" $env:APPVEYOR_PULL_REQUEST_TITLE
 Write-Host "APPVEYOR_REPO_COMMIT_MESSAGE:" $env:APPVEYOR_REPO_COMMIT_MESSAGE 

 if(-not ([string]::IsNullOrEmpty($env:APPVEYOR_PULL_REQUEST_NUMBER)) -or $env:APPVEYOR_REPO_BRANCH -ne $branch)
 {
 	 return
 }

 if ([string]::IsNullOrEmpty($env:git_message_text))
{
	$gitData = ConvertFrom-StringData (git log -1 --no-merges --format=format:"commitId=%H%nmessage=%B%ncommitted=%aD" | out-string)
	if ($gitData['message'] -eq "") { $gitData['message'] = "No commit message available for $($gitData['commitid'])" }
	$env:git_message_text = $gitData['message'] 
}
 

$text = "Deployment triggered. `n" + $env:git_message_text
$postUrl = "https://slack.com/api/chat.postMessage"
$updateUrl = "https://slack.com/api/chat.update"
$iconUrl = "https://pbs.twimg.com/profile_images/1604347359/logo_512x512_normal.png"

Write-Host "SLACK API TOKEN:" $env:SLACK_API_TOKEN

$selectedAttachment = switch ( $status )
    {
        success 
        {
            '[{
                "fallback": "Success - Deploy LMS release to UAT.",
                "color": "#228B22",
                "fields": [
                    {
                        "title": "Success",
                        "value": "LMS release to UAT",
                        "short": false
                    }
                ]
            }]'
        }
        failed 
        {
            '[{
                "fallback": "Failed - Deploy LMS release to UAT.",
                "color": "#FF0000",
                "fields": [
                    {
                        "title": "Failed",
                        "value": "LMS release to UAT",
                        "short": false
                    }
                ]
            }]'

        }
        default 
        { 
            '[{
                "fallback": "Pending - Deploy LMS release to UAT.",
                "color": "#FFFF00",
                "fields": [
                    {
                        "title": "Pending",
                        "value": "LMS release to UAT",
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