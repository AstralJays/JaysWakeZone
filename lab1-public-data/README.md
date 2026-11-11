# Lab 1 — Public object storage with synthetic PII

Intentionally **public** cloud storage seeded with fake customer / PCI-style exports for CSPM and data-exposure demos.

> All files are **synthetic**. Patterns follow common DLP test datasets (e.g. [dlptest.com sample data](https://dlptest.com/sample-data/)). Not real people.

| File | Contents |
|------|----------|
| `name-ssn-ccn.csv` | Name + SSN + credit card (30 rows) |
| `name-ssn-dob.csv` | Name + SSN + date of birth (30 rows) |
| `name-ccn-zip.csv` | Name + card + ZIP + expiry (50 rows) |
| `name-dob-email.csv` | Name + DOB + email (50 rows) |
| `customers.json` | Compact JSON export for quick browser checks |

Terraform under `infrastructure/{aws,azure,gcp}` uploads these objects and opens anonymous read/list.
