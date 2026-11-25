# Lab 1 — Storage CSPM / DSPM loop

Terraform seeds **two** intentionally public object stores (per cloud) with the same synthetic PII and fake secrets:

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
| `secrets.env` | Fake env secrets (AWS doc example key, DB password, placeholder token) |
| `aws-credentials` | Fake AWS shared-credentials file (documentation example key) |
| `api-keys.json` | Same fake secrets as JSON |
| `id_rsa` | Non-usable private-key fixture (detector bait only) |

Objects land under `exports/` (PII) and `secrets/` (credentials) in **both** the remediate and exception stores.

> Not real people or credentials. Workshop / sandbox only. AWS key material is the [published documentation example](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys).

## Deploy / destroy

Use the parent stack: [`../README.md`](../README.md) (`Lab1-3/infrastructure/<cloud>/`).
