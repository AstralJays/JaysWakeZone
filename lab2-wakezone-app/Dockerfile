FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl iputils-ping \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV JWZ_DEMO_AWS_ACCESS_KEY_ID=AKIAJWZDEMOEXAMPLE00
ENV JWZ_DEMO_AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ENV JWZ_DEMO_DB_PASSWORD=wakezone-super-secret
ENV PYTHONUNBUFFERED=1

EXPOSE 8080
WORKDIR /app/app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
