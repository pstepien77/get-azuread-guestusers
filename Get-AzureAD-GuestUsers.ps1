
# This script will require the Web Application and permissions setup in Azure Active Directory
# No parameters required - just below registered application

$ClientID       = "<put your client Id here>"             # Should be a ~35 character string insert your info here
$ClientSecret   = "<put your client secret here>"         # Should be a ~44 character string insert your info here
$loginURL       = "https://login.windows.net"
$tenantdomain   = "<your tenant name>.onmicrosoft.com"    # For example, contoso.onmicrosoft.com

# How to register application - https://docs.microsoft.com/en-us/graph/auth-v2-service
# Permission required - Appliction:Directory.Read.All
# Remember to consent to application !


function GetReport ($url, $reportname, $tenantname) {
    # Get an Oauth 2 access token based on client id, secret and tenant domain
    $loginURL = "https://login.windows.net"
    $resource = "https://graph.microsoft.com"

    # setup output file location and file name according to provided details
    $AuditOutputCSV = $Pwd.Path + "\" + $tenantname + "_$reportname.csv"

    # create body, and invoke rest api call to get the token
    $body = @{grant_type = "client_credentials"; resource = $resource; client_id = $ClientID; client_secret = $ClientSecret }
    $oauth = Invoke-RestMethod -Method POST -Uri $loginURL/$tenantname/oauth2/token?api-version=1.0 -Body $body

    # if token present in the response
    if ($oauth.access_token -ne $null) {

        # prepere headers, and trigger GET web request
        $headerParams = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method GET)

        # convert response from JSON
        $ConvertedReport = ConvertFrom-Json -InputObject $myReport.Content
        $ReportValues = $ConvertedReport.value
        $nextURL = $ConvertedReport."@odata.nextLink"

        # gather all response pages till next link is not NULL
        if ($nextURL -ne $null) {
            Do {
                $NextResults = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $nextURL -Method Get -ErrorAction SilentlyContinue
                $NextConvertedReport = ConvertFrom-Json -InputObject $NextResults.Content
                $ReportValues += $NextConvertedReport.value
                $nextURL = $NextConvertedReport."@odata.nextLink"
            }
            While ($nextURL -ne $null)
        }
        # place results into a CSV
        $AuditOutputCSV = $Pwd.Path + "\" + $tenantname + "_$reportname.csv"

        # create a PSObject to place the results into before export to CSV so that values are expanded
        $AuditReport = New-Object PSObject
        $AuditReportArray = @()

        # loop thru all entires in reported values, and push it to final report object
        foreach ($AuditEntry in $ReportValues) {
            $AuditReport = New-Object PSObject
            add-member -inputobject $AuditReport -membertype noteproperty -name "displayName" -value $AuditEntry.displayName
            add-member -inputobject $AuditReport -membertype noteproperty -name "createdDateTime" -value $AuditEntry.createdDateTime
            add-member -inputobject $AuditReport -membertype noteproperty -name "mail" -value $AuditEntry.mail
            add-member -inputobject $AuditReport -membertype noteproperty -name "externalUserState" -value $AuditEntry.externalUserState
            add-member -inputobject $AuditReport -membertype noteproperty -name "userPrincipalName" -value $AuditEntry.userPrincipalName
            add-member -inputobject $AuditReport -membertype noteproperty -name "id" -value $AuditEntry.id
            add-member -inputobject $AuditReport -membertype noteproperty -name "userType" -value $AuditEntry.userType
            add-member -inputobject $AuditReport -membertype noteproperty -name "accountEnabled" -value $AuditEntry.accountEnabled
            $AuditReportArray += $AuditReport
            $AuditReport = $null
        }

        # export report to .csv
        $AuditReportArray | Export-csv $AuditOutputCSV -NoTypeInformation -Force
        Write-Host "The report can be found at $AuditOutputCSV`n" -ForegroundColor Yellow
    } else
    { # exit - no token
        Write-Host "Can't get token ! Hard stop!" -ForegroundColor Red
        Exit 1
    }
    if ($ConvertedReport.value.count -eq 0) {
        Write-Host "No Data Returned." -ForegroundColor Yellow
    }
}


Write-Output "Searching the tenant $tenantdomain ..."

# build URI filter based on userType=Guest + additional attributes
[string]$URIfilter = "?`$filter=userType eq 'Guest'&`$select=displayName, createdDateTime, mail, externalUserState, userPrincipalName, id, userType, accountEnabled"

# construct final URL
$url = "https://graph.microsoft.com/beta/users" + $URIfilter

# trigger function to get the report
GetReport $url "GuestUsersAll" $tenantdomain
