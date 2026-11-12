# Next steps

State checked on 2026-11-12: no state lock left, and `terraform plan` gives **25 to add, 0 to change, 1 to destroy**. That is exactly 6.5 Level 1. "0 to change" confirms the Function App tag fix worked.

## 1. Apply 6.5 Level 1

Adds one SQL firewall rule per Function outbound IP and deletes the `0.0.0.0` "AllowAzureServices" rule.

```powershell
.\scripts\deploy.ps1          # shows the plan, type "yes" to apply
```

## 2. Publish today's code

Azure still runs the old `function_app.py`, not the version that imports `sanitize.py`.

```powershell
.\scripts\publish.ps1
```

## 3. Check that it still works

Without the `0.0.0.0` rule, the Function reaches the database only through its own IP rules.

```powershell
.\scripts\alice.ps1           # expect 401, then 200
```

If you get a 500, wait a minute and retry, because the database may be waking up from auto-pause. If it still fails, run `.\scripts\logs.ps1`. A `Client with IP address ... is not allowed` error means an outbound IP is missing from the rules.

## 4. Close your PC's access to the database (6.5.2 b)

Only once you no longer need `sqlcmd` from your PC.

```powershell
.\scripts\deploy.ps1 -CloseWorkstation
.\scripts\alice.ps1           # must still return 200: only the Function can reach the DB now
```

To reopen it later for maintenance: `.\scripts\deploy.ps1`.

## 5. Commit

Commit the work done since the teacher's update.

## 6. Written answers

Listed in section 7 of [Phase2-Notes.md](Phase2-Notes.md):

- 6.1 to 6.4 short answers
- the 6.5.1 exposure table (a draft is in the notes)
- 6.5.5 questions
- 6.6 monitoring: use `.\scripts\logs.ps1 -Summary` for the numbers. Two findings from the logs help here: rejected 401 calls leave no trace in the `requests` table, and client IPs show as `0.0.0.0` (masked by Application Insights).

## 7. Optional: 6.5 Level 2 (fully private database)

Replaces the Function App with a Flex Consumption one and adds private endpoints that bill by the hour. Do it in one session, then run `terraform destroy`.
