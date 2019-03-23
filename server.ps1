. .\restqueueclass.ps1

$masterkey = (Get-Content .\keys.txt)[0]
$accountname=(Get-Content .\keys.txt)[1]

$b = New-Object RestQueue( $accountname, $masterkey)
$b.ListQueues()

"1","2","3" | %{$b.NewMessage("psqueues", "Hallo daar$($_)" )}

