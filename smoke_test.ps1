$s1 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$null = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/login' -Method POST -Body 'subdomain=acme&email=admin@acme.test&password=password123' -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 15 -UseBasicParsing -WebSession $s1

$s2 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$null = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/login' -Method POST -Body 'subdomain=globex&email=admin@globex.test&password=password123' -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 15 -UseBasicParsing -WebSession $s2

$acme_t = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets' -TimeoutSec 15 -UseBasicParsing -WebSession $s1
$glob_t = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets' -TimeoutSec 15 -UseBasicParsing -WebSession $s2

Write-Output "Acme sees 'Cannot login':         $($acme_t.Content.Contains('Cannot login'))"
Write-Output "Acme sees 'Mobile app crashes':   $($acme_t.Content.Contains('Mobile app crashes'))   (should be False)"
Write-Output "Globex sees 'Mobile app crashes': $($glob_t.Content.Contains('Mobile app crashes'))"
Write-Output "Globex sees 'Cannot login':       $($glob_t.Content.Contains('Cannot login'))   (should be False)"
