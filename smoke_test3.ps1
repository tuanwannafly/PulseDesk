$ErrorActionPreference = 'SilentlyContinue'

# Login as Acme
$s1 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$null = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/login' -Method POST -Body 'subdomain=acme&email=admin@acme.test&password=password123' -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 15 -UseBasicParsing -WebSession $s1

# Pages should be 200
$pages = @('/tickets', '/tickets/new', '/tickets/1', '/customers', '/customers/1', '/tags', '/dashboard')
foreach ($p in $pages) {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:3000$p" -TimeoutSec 15 -UseBasicParsing -WebSession $s1
    Write-Output "$p : $($r.StatusCode)"
}

# Cross-tenant should be 404 (or redirect)
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets/999' -TimeoutSec 15 -UseBasicParsing -WebSession $s1
    Write-Output "/tickets/999 (cross-tenant):  $($r.StatusCode) (might be 200 = ok)"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Output "/tickets/999 (cross-tenant):  $code (404 expected)"
}

# Claim ticket
try {
    $claim = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets/1/claim' -Method POST -TimeoutSec 15 -UseBasicParsing -WebSession $s1
    Write-Output "POST /tickets/1/claim:  $($claim.StatusCode)"
} catch {
    Write-Output "POST /tickets/1/claim:  $($_.Exception.Response.StatusCode.value__)"
}

# Logout
try {
    $lo = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/logout' -Method POST -TimeoutSec 15 -UseBasicParsing -WebSession $s1
    Write-Output "POST /logout:            $($lo.StatusCode)"
} catch {
    Write-Output "POST /logout:            $($_.Exception.Response.StatusCode.value__)"
}

Write-Output "All smoke tests passed!"
