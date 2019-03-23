. .\restqueueclass.ps1

$masterkey = (Get-Content .\keys.txt)[0]
$accountname=(Get-Content .\keys.txt)[1]

$b = New-Object RestQueue( $accountname, $masterkey)
$b.ListQueues()

"4","5","6" | %{$b.NewMessage("psqueues", "Hallo daar$($_)" )}

