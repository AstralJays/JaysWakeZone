# Not used by Terraform.
# AWS Lambda zips app.py. Azure/GCP boot a public python image inline.
FROM python:3.9-bullseye
WORKDIR /app
COPY app.py .
CMD ["python", "-c", "print('Lab 3 AWS handler is app.lambda_handler — deploy with Terraform, not this image')"]
