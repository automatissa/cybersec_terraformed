# Phase 2 — Hardening notes

Progress notes for Phase 2 of the exercise (`Cloud-Exercise-Terraform-Windows11.md`).

| Section | Status |
|---|---|
| 6.1 Function key authentication | Done, tested (401 without key, 200 with key) |
| 6.2 Input validation | Done (`src/sanitize.py`, HTTP 400 on invalid name) |
| 6.3 Key Vault + Managed Identity | Done (`infra/keyvault.tf`) |
| 6.4 Least-privilege database roles | Done (editor login for POST, reader login for GET `/api/names`) |
| 6.5 Network segregation, Level 1 | Code written, **not applied yet** |
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

Easiest: `.\scripts\test-api.ps1` (see section 8). Manual version below.

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
| `infra/sql.tf` | Removed the `0.0.0.0` `AllowAzureServices` rule; added one firewall rule per Function outbound IP (`function_outbound`, `for_each`); workstation rule made switchable with `count`; `moved` block so the existing rule is not recreated |
| `infra/variables.tf` | New variable `allow_workstation_access` (bool, default `true`) |
| `infra/functions.tf` | `lifecycle.ignore_changes` on the `hidden-link` tag that Azure adds to link Application Insights |

Dry-run result (`terraform plan`): **25 to add, 0 to change, 1 to destroy** (the `0.0.0.0` rule).

**Limit of this control:** on the Consumption (Y1) plan the outbound addresses come from a pool shared with other customers' apps and can change when Azure moves the app. It is a filter, not isolation; a change of addresses causes an outage until the next `terraform apply`.

## 5. Next steps

1. If a plan was interrupted, release the state lock: `terraform force-unlock <lock-id>` in `infra\` (the ID is printed in the lock error).
2. Finish every task that needs the PC to reach the database (6.4 users and roles).
3. Apply Level 1:
   ```powershell
   cd infra
   terraform plan -out=tfplan
   terraform apply tfplan
   ```
4. Republish the code (`function_app.py` changed, `sanitize.py` is new): `func azure functionapp publish $FuncName` from `src\`, then rerun the tests in section 2.
5. Close workstation access: `terraform apply -var="allow_workstation_access=false"`. The API must still work; `sqlcmd` from the PC must fail.
6. Reopen it only for a maintenance window: `-var="allow_workstation_access=true"`.

## 6. Exposure map (6.5.1) — draft, to review

| Component | Reachable today from | Control that reduces exposure | What it requires |
|---|---|---|---|
| Function inbound | Whole internet (required) | Function key (6.1), WAF / API gateway, rate limiting | Works on every plan |
| Function outbound | Anywhere | VNet integration + subnet rules | Not available on Y1 |
| SQL server | Function outbound IPs + PC IP (after Level 1) | Private endpoint, deny public access | VNet; Function needs VNet integration (not Y1) |
| Key Vault | Internet, protected by RBAC | Private endpoint, deny public access | Same as SQL |
| Function storage account | Internet, protected by keys | Private endpoints (blob/file) | Plan with VNet integration |
| Terraform state storage | Internet, protected by Entra ID + RBAC | Network rules allowing only the workstation/pipeline | Workstation IP must stay allowed |

## 7. Still to write
- 6.1: why one shared function key is weaker than a per-device identity.
- 6.2: why `{"name": "x'; DROP TABLE dbo.Names;--"}` fails safely.
- 6.3: what a passwordless design (Entra auth, Managed Identity as SQL user) changes.
- 6.4: why two narrow roles are safer than one `db_owner` account (5–10 lines).
- 6.5.5 and 6.6 discussion questions.

## 8. Automation scripts (`scripts\`)

Run from the repo root, after `az login`. If PowerShell blocks scripts: `Set-ExecutionPolicy -Scope Process RemoteSigned`.

| Script | What it does |
|---|---|
| `.\scripts\deploy.ps1` | `fmt` + `validate` + `plan`, then asks `yes` before `apply`. Options: `-PlanOnly`, `-CloseWorkstation` (6.5: remove your PC's SQL rule), `-DetectIp` (update the rule to your current public IP), `-AutoApprove` |
| `.\scripts\publish.ps1` | Publishes `src\` to the Function App (no need to `cd src`) |
| `.\scripts\test-api.ps1` | 7 checks: no key / wrong key → 401, valid POST → 200, SQL injection / not JSON / missing name → 400, GET `/names` → 200. Retries automatically while the database wakes up from auto-pause. `-Name Bob` to change the name |
| `.\scripts\logs.ps1` | Recent requests and errors from Application Insights (`-Minutes 120`). `-Summary` gives the 6.6 numbers: calls per hour, 4xx/5xx, client IPs |
| `.\scripts\all.ps1` | deploy → publish → test. `-SkipDeploy` for a code-only change, `-CloseWorkstation` for 6.5 |

`scripts\common.ps1` holds the shared helpers (Terraform outputs, function key, App Insights query through the REST API so no CLI extension is needed). The function key is never printed.

**Observations from the logs (useful for 6.6):**
- Calls rejected with **401 do not appear in the `requests` table**: the Functions host rejects them before the function runs. A brute-force on the key would leave no trace there.
- `client_IP` is always `0.0.0.0`: Application Insights masks client IPs by default (privacy), so "from which IPs" cannot be answered without changing that setting.
- 400 rejections are visible both as `requests` (resultCode 400) and as warning `traces` ("Rejected request: ...").
