# Lab 4 walkthrough — Juice Shop on containers

## What this is

A **quick deploy** of [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) on ECS / ACA / Cloud Run.  
No Dockerfile, no ECR/ACR/GAR — public image only.

## Steps

1. Apply stack 2: `infrastructure/<cloud>/lab4-containers/`
2. Open `terraform output lab4_url`
3. Confirm the Juice Shop UI loads
4. Install the Upwind **tracer** for this service (portal / console)
5. Browse the shop, create an account, try a few Juice Shop challenges to generate traffic / vulns
6. In Upwind: agentless / image findings on the Juice Shop image + tracer runtime if installed
7. `terraform destroy` in that folder

## Notes

- First cold start can take a minute (image pull).
- AWS: ALB costs money while up — destroy when finished.
- Lab 3 (in `lab1-3`) is still the small serverless function (Lambda / App Service / Cloud Run lab3). Lab 4 is the **container** Juice Shop track.
