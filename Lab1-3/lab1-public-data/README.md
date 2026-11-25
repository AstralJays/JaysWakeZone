# Lab 1 — Storage CSPM / DSPM loop

Terraform seeds **two** intentionally public object stores (per cloud) with the same synthetic PII:

| Resource | Purpose |
|----------|---------|
| **remediate** | Public + PII → SA **fixes** exposure and reassesses |
| **exception** | Public + PII → SA **whitelists / accepts risk** |

## Datasets

Patterns follow [dlptest.com/sample-data](https://dlptest.com/sample-data/) (fake only):

| File | Contents |
|------|----------|
| `name-ssn-ccn.csv` | Name + SSN + credit card |
| `name-ssn-dob.csv` | Name + SSN + DOB |
| `name-ccn-zip.csv` | Name + card + ZIP + expiry |
| `name-dob-email.csv` | Name + DOB + email |
| `customers.json` | Compact JSON export |

> Not real people. Workshop / sandbox only.
