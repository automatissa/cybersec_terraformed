# The project explained simply

## What I built

A small app in the cloud (Azure). You send it a name ("Alice"), it counts how many times it has seen that name, and it answers: *"hello Alice this is your 16th call"*.

There are 3 main parts:

- **The Function**: the app itself, the code that answers.
- **The database**: a notebook where the counts are written.
- **Key Vault**: a safe where the database passwords are kept.

**Terraform** is the tool that builds all of this in Azure from text files (the `.tf` files), so you don't have to click around in the Azure website.

## Phase 2 = protecting it (the "hardening")

Think of the app as a **shop**.

| Step | In simple words | Shop comparison |
|---|---|---|
| **6.1 Key** | Nobody can use the app without a secret key. No key = **401** (refused). With key = **200** (OK). | You need a badge to enter. |
| **6.2 Validation** | The app refuses strange names like `x'; DROP TABLE...` (a hacking attempt). It answers **400** (bad request). | The cashier refuses fake money. |
| **6.3 Key Vault** | The database password is no longer written in the app settings; it's in a safe. | The shop keys are in a safe, not under the doormat. |
| **6.4 Two logins** | One login can only *read* the database and another can *write*. If one is stolen, the damage is limited. | The cleaner has a key to the hall, not to the cash register. |
| **6.5 Network** | Limit **who can even reach** the database. | Lock the back door, not just the cash register. |

## The key is not "encryption"

- The **key** = proving **who you are** (like a badge).
- **Encryption** = scrambling the data so nobody can read it on the way (like a sealed envelope). The app already does this with **HTTPS**.

## What happened during the tests

1. **A test "didn't work"** for a simple reason: the commands were run from the wrong folder, so the key was empty, so the app said **401**. That was the protection working.
2. **Then a 500 error**: the database "falls asleep" after 1 hour without use (to save money). The first call wakes it up but takes too long and fails. Wait 1 minute and it works.
3. **Step 6.5 (network)**: we told the database to *only accept the Function's addresses*, using a list Azure gives. But Azure's list was **incomplete**: the Function sometimes used an address not on the list, so the database refused it and the app broke. We put the old rule back, so it works again.

**Lesson for the report:** with this cheap Azure plan (Linux Consumption, Y1), blocking by address doesn't work reliably. Real protection needs a private network (Level 2, which costs money).

## Simple vocabulary

- **401** = "you're not allowed" (no key)
- **400** = "your request is wrong" (bad name)
- **200** = "OK"
- **500** = "something broke on the server"
- **commit / push** = save your work, then send it to GitHub

## Test it yourself

From the project folder:

```powershell
.\scripts\alice.ps1
```

You should see **401** first (no key), then **200** with the counter.

## What's left

1. **Write the answers** to the questions in the subject. The list is in [Phase2-Notes.md](Phase2-Notes.md), section 7. Write them in your own words; the teacher will want to see that you understood.
2. **Optional:** close your PC's access to the database (the commands are in [NEXT-STEPS.md](NEXT-STEPS.md)).
