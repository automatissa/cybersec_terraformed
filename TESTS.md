# Tests to run

Run everything in the **same PowerShell window**, from the project folder. Variables (`$Url`, `$Key`...) only exist in the window where they were created: in a new window, run Step 0 again.

## Step 0: preparation (once per window)

```powershell
cd C:\Users\issad\source\repos\cybersec_terraformed
$Rg       = terraform -chdir=infra output -raw resource_group_name
$FuncName = terraform -chdir=infra output -raw function_app_name
$Key      = az functionapp keys list --name $FuncName --resource-group $Rg --query functionKeys.default -o tsv
$Url      = "https://$FuncName.azurewebsites.net/api"

# Check (do not skip):
"URL: $Url"
"Key length: $($Key.Length)"
```

✅ Expected:
```
URL: https://func-namecounter-lab-8cd658.azurewebsites.net/api
Key length: 56        (any number above 0)
```

❌ If `URL` is `https://.azurewebsites.net/api` → Terraform did not answer: check you are in the project folder.
❌ If `Key length: 0` → run `az login`, then Step 0 again.

## Test 1: without the key → must be refused (6.1)

```powershell
curl.exe -s -w " [%{http_code}]`n" -X POST "$Url/http_trigger" -H "Content-Type: application/json" -d "@src\alice.json"
```

✅ Expected: `[401]`

## Test 2: with the key → must work (6.1)

```powershell
curl.exe -s -w " [%{http_code}]`n" -X POST "$Url/http_trigger" -H "Content-Type: application/json" -H "x-functions-key: $Key" -d "@src\alice.json"
```

✅ Expected: `hello Alice this is your Nth call [200]`
⚠️ `[500]` → the database was asleep. Wait 1 minute and run it again.

## Test 3: hacking attempt → must be refused (6.2)

```powershell
'{"name": "x''; DROP TABLE dbo.Names;--"}' | Set-Content -Encoding ascii src\hack.json
curl.exe -s -w " [%{http_code}]`n" -X POST "$Url/http_trigger" -H "Content-Type: application/json" -H "x-functions-key: $Key" -d "@src\hack.json"
```

✅ Expected: `{"error": "name: 1-100 characters, ..."} [400]`
For the report: the app refuses this name **before** touching the database.

## Test 4: read the list → must work with the "reader" login (6.4)

```powershell
curl.exe -s -w " [%{http_code}]`n" -H "x-functions-key: $Key" "$Url/names"
```

✅ Expected: `{"names": [{"name": "alice", "count": ...}]} [200]`

## Test 5: see the tests in the logs (6.6)

Wait **2–3 minutes** (logs arrive late), then:

1. Azure Portal → `appi-namecounter-lab-8cd658` → **Logs**
2. Paste this and click **Run**:
   ```
   requests
   | where timestamp > ago(30m)
   | project timestamp, name, resultCode
   | order by timestamp desc
   ```

✅ Expected: the **200** and **400** calls appear. The **401** from Test 1 does **not** appear: write that in the 6.6 answer.

## Result codes

| Code | Meaning |
|---|---|
| `200` | OK |
| `400` | Bad request (invalid name, not JSON) |
| `401` | Not allowed (no key or wrong key) |
| `500` | Server error (often: database waking up, retry after 1 min) |
| `000` | curl never reached the server: `$Url` is empty → run Step 0 again |

## Results

| Test | Expected | Got |
|---|---|---|
| 1. No key | 401 | |
| 2. With key | 200 | |
| 3. Hacking name | 400 | |
| 4. GET /names | 200 | |
| 5. Logs | 200 and 400 visible, 401 missing | |
