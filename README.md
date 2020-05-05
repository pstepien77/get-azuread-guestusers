# get-azuread-guestusers
 Retrieve all guest users from the Azure tenant (MS Graph REST API)

This script requires the Web Application and permissions setup in target Azure tenant
No parameters required - just below registered application details updated in the script code:

$ClientID       = "<put your client Id here>"             # Should be a ~35 character string insert your info here
 
$ClientSecret   = "<put your client secret here>"         # Should be a ~44 character string insert your info here

$loginURL       = "https://login.windows.net"

$tenantdomain   = "<your tenant name>.onmicrosoft.com"    # For example, contoso.onmicrosoft.com

How to register application - https://docs.microsoft.com/en-us/graph/auth-v2-service
Permission required - Appliction:Directory.Read.All

Remember to consent to application !
