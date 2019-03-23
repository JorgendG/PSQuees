. .\restqueueclass.ps1

$masterkey = (Get-Content .\keys.txt)[0]
$accountname=(Get-Content .\keys.txt)[1]

$b = New-Object RestQueue( $accountname, $masterkey)

$b.GetMessage("psqueues" )


