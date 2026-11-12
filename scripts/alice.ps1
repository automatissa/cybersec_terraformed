# Calls the API with Alice, without and with the function key.
# Usage (from anywhere): .\scripts\alice.ps1
$Root     = Split-Path $PSScriptRoot -Parent
$Rg       = terraform -chdir="$Root\infra" output -raw resource_group_name
$FuncName = terraform -chdir="$Root\infra" output -raw function_app_name
$Url      = "https://$FuncName.azurewebsites.net/api/http_trigger"
$Key      = az functionapp keys list --name $FuncName --resource-group $Rg --query functionKeys.default -o tsv

Write-Host "Without key (expect 401):"
curl.exe -s -w " [%{http_code}]`n" -X POST $Url -H "Content-Type: application/json" -d "@$Root\src\alice.json"

Write-Host "With key (expect 200):"
curl.exe -s -w " [%{http_code}]`n" -X POST $Url -H "Content-Type: application/json" -H "x-functions-key: $Key" -d "@$Root\src\alice.json"
