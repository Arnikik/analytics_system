FROM python:3-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY stress_test.py .

CMD ["tail", "-f", "/dev/null"] 