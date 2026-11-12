# Next steps

Updated 2026-11-12. Details and evidence in [Phase2-Notes.md](Phase2-Notes.md).

| # | Step | Status |
|---|---|---|
| 1 | Apply 6.5 Level 1 (per-IP SQL rules, remove `0.0.0.0`) | Done. GET then failed: the Function used an IP absent from Azure's list (Linux Y1 limit) |
| 1b | Restore the `0.0.0.0` rule | Done, POST and GET return 200 again |
| 2 | Publish the code (`sanitize.py` import) | Done |
| 3 | Test with and without key | Done: 401 / 200 / GET 200 |
| 4 | Close PC access to SQL | To do, when `sqlcmd` from the PC is no longer needed |
| 5 | Commit and push | Done |
| 6 | Written answers | To do |
| 7 | Level 2 (private database) | Optional, costs money |

## 4. Close PC access to the database (6.5.2 b)

```powershell
cd infra
terraform plan -var="allow_workstation_access=false" -out=tfplan
terraform apply tfplan
cd ..
.\scripts\alice.ps1      # must still return 401, then 200
```

Reopen for a maintenance window: same commands with `allow_workstation_access=true`.

## 6. Written answers

Listed in section 7 of [Phase2-Notes.md](Phase2-Notes.md): 6.1 to 6.4 short answers, the 6.5.1 exposure table (draft in the notes), 6.5.5 and 6.6.

Points to use:
- **6.5:** IP allow-listing failed in practice on Linux Consumption (error 40615 from an unlisted outbound IP). Real database isolation needs VNet integration + private endpoint, which Y1 does not support.
- **6.6:** rejected 401 calls leave no trace in the `requests` table; `client_IP` shows `0.0.0.0` (masked by Application Insights).

## 7. Optional: Level 2

Flex Consumption + VNet + private endpoint for SQL, public access disabled. Replaces the Function App (republish needed) and private endpoints are billed per hour: do it in one session, then `terraform destroy`.
