. .\restqueueclass.ps1

$masterkey = (Get-Content .\keys.txt)[0]
$accountname=(Get-Content .\keys.txt)[1]

$b = New-Object RestQueue( $accountname, $masterkey)

$b.ListQueues()
$myMessage = $b.GetMessage("psqueues" )

Write-Host "Retrieved a message from the queue"
Write-Host "-->$myMessage<--"
