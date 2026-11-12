# Phase 2 — Hardening notes

Progress notes for Phase 2 of the exercise (`Cloud-Exercise-Terraform-Windows11.md`).

| Section | Status |
|---|---|
| 6.1 Function key authentication | Done, tested (401 without key, 200 with key) |
| 6.2 Input validation | Done (`src/sanitize.py`, HTTP 400 on invalid name) |
| 6.3 Key Vault + Managed Identity | Done (`infra/keyvault.tf`) |
| 6.4 Least-privilege database roles | Done (editor login for POST, reader login for GET `/api/names`) |
| 6.5 Network segregation, Level 1 | Applied 2026-11-12. Per-IP rules **break the app on Linux Y1**, so `0.0.0.0` was restored (see section 4). Workstation switch ready, not used yet |
| 6.5 Network segregation, Level 2 | Not started (needs Flex Consumption plan, extra cost) |
| 6.6 Monitoring discussion | To write |

---

## 1. Authentication vs encryption

The function key is **authentication**: it proves who is calling. It does not encrypt anything.

Encryption in transit is provided by:
- HTTPS on the Function App (`https_only = true` in `functions.tf`);
- TLS to the database (`Encrypt=yes;TrustServerCertificate=no` in the connection string, `minimum_tls_version = "1.2"` on the SQL server).

Both have been active since Phase 1.

## 2. Reproducing the 6.1 test

Easiest: `.\scripts\alice.ps1` from any folder (calls without and with the key). Manual version below.

Manual version, run from `src\` (paths are relative):

```powershell
$Rg       = terraform -chdir="..\infra" output -raw resource_group_name
$FuncName = terraform -chdir="..\infra" output -raw function_app_name
$Url      = "https://$FuncName.azurewebsites.net/api"

# Publish the code with AuthLevel.FUNCTION
func azure functionapp publish $FuncName

# Get the default function key (never commit or share it)
$Key = az functionapp keys list --name $FuncName --resource-group $Rg --query functionKeys.default -o tsv

# Without key -> 401 (rejected by the Functions host, the Python code never runs)
curl.exe -s -w " [%{http_code}]`n" -X POST "$Url/http_trigger" -H "Content-Type: application/json" -d "@alice.json"

# With key -> 200, counter increments
curl.exe -s -w " [%{http_code}]`n" -X POST "$Url/http_trigger" -H "Content-Type: application/json" -H "x-functions-key: $Key" -d "@alice.json"

# GET with the reader login (6.4)
curl.exe -s -H "x-functions-key: $Key" "$Url/names"
```

Notes:
- Use `-d "@alice.json"` instead of inline JSON: quoting JSON in PowerShell 5.1 is unreliable.
- A call that returns 200 without a key means the deployed code is still `AuthLevel.ANONYMOUS`: republish.
- `alice` and `Alice` are the **same** row: the default Azure SQL collation (`SQL_Latin1_General_CP1_CI_AS`) is case-insensitive.
- The 401 appears in the Application Insights `requests` table (`resultCode == 401`), not in `exceptions`.
- **500 with `Login timeout expired` in the logs** = the serverless database was auto-paused (after 60 min idle) and took longer than the 30 s connection timeout to resume. Not a security or code problem: wait ~1 minute and call again. Check with `az sql db show -g $Rg -s <server> -n NameCounterDB --query status -o tsv` (`Paused` / `Resuming` / `Online`).

## 3. Merge with the teacher's update (commits `1926bcb`, `d6cd6dd`)

The teacher's update contains a reference solution for 6.2/6.3 and the new section 6.5.

- `src/sanitize.py` (teacher) is used; `function_app.py` imports `validate_name` from it.
- The local error handling is kept: an invalid name returns its own 400 message. In the reference version the `ValueError` from `validate_name` is caught by the JSON-parsing `except` and wrongly reported as "Body must be valid JSON".
- The local `keyvault.tf` is kept: two secrets (`SqlConnStringEditor`, `SqlConnStringReader`) instead of one admin secret, as required by 6.4.

## 4. Section 6.5 Level 1 — what changed

| File | Change |
|---|---|
| `infra/sql.tf` | Added one firewall rule per Function outbound IP (`function_outbound`, `for_each`, 25 rules); workstation rule made switchable with `count`; `moved` block so the existing rule is not recreated. The `0.0.0.0` rule was removed, then **restored** (see below) |
| `infra/variables.tf` | New variable `allow_workstation_access` (bool, default `true`) |
| `infra/functions.tf` | `lifecycle.ignore_changes` on the `hidden-link` tag that Azure adds to link Application Insights |

### What happened when applied (2026-11-12)

1. Applied: 25 per-IP rules added, `0.0.0.0` rule destroyed. Code republished.
2. Test: POST → 200, but GET `/names` → 500 every time.
3. Application Insights `traces`:
   ```
   Cannot open server 'sql-namecounter-lab-8cd658' requested by the login.
   Client with IP address '131.189.239.33' is not allowed to access the server. (40615)
   ```
4. `az functionapp show --query "{possible:possibleOutboundIpAddresses, current:outboundIpAddresses}"`: `131.189.239.33` is in **neither** list.
5. Decision: restore the `0.0.0.0` rule (1 to add). Retest: POST 200, GET 200 (3/3).

**Conclusion:** on **Linux Consumption (Y1)**, workers run in a shared regional pool and the outbound IPs Azure publishes for the app are incomplete. An IP allow-list on the database is therefore not just "a filter that can drift": it breaks the app at random from day one (POST happened to run on a listed IP, GET did not). Network-level isolation of the database is only reliable with VNet integration + private endpoint (Level 2), which Y1 does not support.

The per-IP rules are kept (harmless, they document the published list); with `0.0.0.0` present they add no restriction.

## 5. Next steps

1. Close workstation access once the PC no longer needs `sqlcmd` (still meaningful: your PC is not an Azure IP):
   ```powershell
   cd infra
   terraform plan -var="allow_workstation_access=false" -out=tfplan
   terraform apply tfplan
   ```
   Then `.\scripts\alice.ps1` must still return 200. Reopen for maintenance with `allow_workstation_access=true`.
2. If a plan is interrupted, release the state lock: `terraform force-unlock <lock-id>` in `infra\` (the ID is printed in the lock error).
3. Optional: Level 2 (Flex Consumption + private endpoint), the only real fix for the SQL exposure.

## 6. Exposure map (6.5.1) — draft, to review

| Component | Reachable today from | Control that reduces exposure | What it requires |
|---|---|---|---|
| Function inbound | Whole internet (required) | Function key (6.1), WAF / API gateway, rate limiting | Works on every plan |
| Function outbound | Anywhere | VNet integration + subnet rules | Not available on Y1 |
| SQL server | Any Azure resource (`0.0.0.0` rule, kept because per-IP rules fail on Linux Y1) + PC IP | Private endpoint, deny public access | VNet; Function needs VNet integration (not Y1) |
| Key Vault | Internet, protected by RBAC | Private endpoint, deny public access | Same as SQL |
| Function storage account | Internet, protected by keys | Private endpoints (blob/file) | Plan with VNet integration |
| Terraform state storage | Internet, protected by Entra ID + RBAC | Network rules allowing only the workstation/pipeline | Workstation IP must stay allowed |

## 7. Still to write
- 6.1: why one shared function key is weaker than a per-device identity.
- 6.2: why `{"name": "x'; DROP TABLE dbo.Names;--"}` fails safely.
- 6.3: what a passwordless design (Entra auth, Managed Identity as SQL user) changes.
- 6.4: why two narrow roles are safer than one `db_owner` account (5–10 lines).
- 6.5.5 and 6.6 discussion questions.

## 8. Useful commands

```powershell
.\scripts\alice.ps1                                         # call with and without key
cd src; func azure functionapp publish func-namecounter-lab-8cd658; cd ..   # publish code
terraform -chdir=infra plan -out=tfplan; terraform -chdir=infra apply tfplan  # deploy infra
```

Read Application Insights without the CLI extension (it prompts to install and fails non-interactively):

```powershell
$id = az resource show -g rg-namecounter-lab-8cd658 -n appi-namecounter-lab-8cd658 --resource-type microsoft.insights/components --query id -o tsv
@{query="union traces, exceptions | where timestamp > ago(30m) | where severityLevel >= 2 or itemType=='exception' | project timestamp, operation_Name, message, innermostMessage | order by timestamp desc | take 10"} | ConvertTo-Json | Out-File -Encoding ascii q.json
(az rest --method post --url "https://management.azure.com$id/query?api-version=2018-04-20" --body "@q.json" -o json | ConvertFrom-Json).tables[0].rows
```

Telemetry arrives 1–3 minutes after the call.

**Observations from the logs (useful for 6.6):**
- Calls rejected with **401 do not appear in the `requests` table**: the Functions host rejects them before the function runs. A brute-force on the key would leave no trace there.
- `client_IP` is always `0.0.0.0`: Application Insights masks client IPs by default (privacy), so "from which IPs" cannot be answered without changing that setting.
- 400 rejections are visible both as `requests` (resultCode 400) and as warning `traces` ("Rejected request: ...").
