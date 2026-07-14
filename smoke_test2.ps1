$s1 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$null = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/login' -Method POST -Body 'subdomain=acme&email=admin@acme.test&password=password123' -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 15 -UseBasicParsing -WebSession $s1

# Test the new ticket form
$new_form = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets/new' -TimeoutSec 15 -UseBasicParsing -WebSession $s1
Write-Output "/tickets/new: $($new_form.StatusCode)"

# Test direct ticket show
$show = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets/1' -TimeoutSec 15 -UseBasicParsing -WebSession $s1
Write-Output "/tickets/1: $($show.StatusCode)"

# Test customers show
$show_c = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/customers/1' -TimeoutSec 15 -UseBasicParsing -WebSession $s1
Write-Output "/customers/1: $($show_c.StatusCode)"

# Test claim route exists (POST only) — don't follow redirects
try {
    $claim = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets/1/claim' -Method POST -TimeoutSec 15 -UseBasicParsing -WebSession $s1 -ErrorAction Stop
    Write-Output "POST /tickets/1/claim: $($claim.StatusCode)"
} catch {
    if ($_.Exception.Response) {
        Write-Output "POST /tickets/1/claim: $($_.Exception.Response.StatusCode) (redirected)"
    } else {
        Write-Output "POST /tickets/1/claim: error - $_"
    }
}

# Test cross-tenant 404
try {
    $cross = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/tickets/99' -TimeoutSec 15 -UseBasicParsing -WebSession $s1 -ErrorAction Stop
    Write-Output "Cross-tenant /tickets/99: $($cross.StatusCode) (unexpected)"
} catch {
    if ($_.Exception.Response) {
        Write-Output "Cross-tenant /tickets/99: $($_.Exception.Response.StatusCode) (should be 404)"
    } else {
        Write-Output "Cross-tenant /tickets/99: error - $_"
    }
}

# Logout
$logout = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/logout' -Method POST -TimeoutSec 15 -UseBasicParsing -WebSession $s1 -ErrorAction SilentlyContinue
if ($null -eq $logout) { Write-Output "POST /logout: (exception)" } else { Write-Output "POST /logout: $($logout.StatusCode)" }
