# Define a class
class RestQueue
{
    [string] $AccountName
    [string] $MasterKey
    hidden [string] $xmlversion = "2017-04-17"

    # Constructor
    RestQueue ([string] $accountname, [string] $MasterKey)
    {
        $this.AccountName = $accountname
        $this.MasterKey = $MasterKey
    }
   

    hidden [hashtable]NewAuthorizationSignatureSharedLite( [string]$method, [string]$contentType, [string]$resource, [string]$dateTime)
    {
        $canonheaders = "x-ms-date:$dateTime`nx-ms-version:$($this.xmlversion)"
        
        $stringToSign = "$method`n" + # verb
                        "`n" + # content-md5
                        "$contenttype`n" + # content-type
                        "`n" + # date
                        "$canonheaders`n" +  # canonheaders
                        "/$($this.AccountName)/$resource"
        $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
        $hmacsha.key = [Convert]::FromBase64String($this.MasterKey)
        $signature = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign))
        $signature = [Convert]::ToBase64String($signature)
        $headers = @{
            'x-ms-date' = $dateTime
            Authorization = "SharedKeyLite " + $this.AccountName + ":" + $signature
            "x-ms-version" = $this.xmlversion
        }
        return $headers
    }

    [string[]]ListQueues()
    {
        $method = "GET"
        $contenttype = "application/x-www-form-urlencoded"
        $dateTime = [DateTime]::UtcNow.ToString("r")
        $queue_url = "https://$($this.accountname).queue.core.windows.net/?comp=list"
        $resource = "?comp=list"

        $authHeader = $this.NewAuthorizationSignatureSharedLite( $method, $contenttype, $resource, $dateTime )
        $result = Invoke-RestMethod -Method $method -Uri $queue_url -Headers $authheader -ContentType $contenttype
        [xml]$responseXml = $result.Substring($result.IndexOf("<"))
        return ($responseXml.EnumerationResults.Queues.Queue | Select-Object -ExpandProperty name )
    }

    [void]NewMessage( $queuename, $QueueMessage)
    {
        $method = "POST"
        $contenttype = "application/x-www-form-urlencoded"
        $resource = "$QueueName/messages"
        $GMTTime = (Get-Date).ToUniversalTime().toString('R')
        $queue_url = "https://$($this.AccountName).queue.core.windows.net/$resource"

        $headers = $this.NewAuthorizationSignatureSharedLite( $method, $contenttype, $resource, $GMTTime )
        
        $QueueMessage = [Text.Encoding]::UTF8.GetBytes($QueueMessage)
        $QueueMessage =[Convert]::ToBase64String($QueueMessage)
        $body = "<QueueMessage><MessageText>$QueueMessage</MessageText></QueueMessage>"
        Invoke-RestMethod -Method $method -Uri $queue_url -Headers $headers -Body $body -ContentType $contenttype

    }

    [string]PeekMessage($queuename)
    {
        $method = "GET"
        $contenttype = "application/x-www-form-urlencoded"
        $resource = "$QueueName/messages"
        $GMTTime = (Get-Date).ToUniversalTime().toString('R')
        $queue_url = "https://$($this.AccountName).queue.core.windows.net/$($resource)?peekonly=true"

        $headers = $this.NewAuthorizationSignatureSharedLite( $method, $contenttype, $resource, $GMTTime )
        
        $result = Invoke-RestMethod -Method $method -Uri $queue_url -Headers $headers -ContentType $contenttype

        [xml]$responseXml = $result.Substring($result.IndexOf("<"))
        $encoded = "$($responseXml.QueueMessagesList.QueueMessage.MessageText)"
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
        return $decoded
    }

    [void]DeleteMessage($queuename, [string]$messageid, [string]$popreceipt)
    {

        $method = "DELETE"
        $contenttype = "application/x-www-form-urlencoded"
        $resource = "$QueueName/messages/$($messageid)"
        $GMTTime = (Get-Date).ToUniversalTime().toString('R')
        

        $headers = $this.NewAuthorizationSignatureSharedLite( $method, $contenttype, $resource, $GMTTime )
        $popreceipt = $popreceipt.Replace( '+', '%2B' )
        $resource = "$QueueName/messages/$($messageid)?popreceipt=$popreceipt"
        $queue_url = "https://$($this.AccountName).queue.core.windows.net/$($resource)"
        Invoke-RestMethod -Method $method -Uri $queue_url -Headers $headers -ContentType $contenttype

    }

    [string]GetMessage($queuename)
    {
        $method = "GET"
        $contenttype = "application/x-www-form-urlencoded"
        $resource = "$QueueName/messages"
        $GMTTime = (Get-Date).ToUniversalTime().toString('R')
        $queue_url = "https://$($this.AccountName).queue.core.windows.net/$($resource)"
        $headers = $this.NewAuthorizationSignatureSharedLite( $method, $contenttype, $resource, $GMTTime )
        
        $result = Invoke-RestMethod -Method $method -Uri $queue_url -Headers $headers -ContentType $contenttype
        [xml]$responseXml = $result.Substring($result.IndexOf("<"))
        $messageid=$responseXml.QueueMessagesList.QueueMessage.MessageId
        $popreceipt=$responseXml.QueueMessagesList.QueueMessage.PopReceipt
        $encoded = "$($responseXml.QueueMessagesList.QueueMessage.MessageText)"
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
        if( $null -ne $messageid)
        {
            $this.DeleteMessage( $QueueName, $messageid, $popreceipt )
        }
        return $decoded
    }
}
