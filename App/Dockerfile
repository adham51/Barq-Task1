# Stage 1: install the Python packages
FROM python:3.12.7-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: final image with only the installed packages and the code
FROM python:3.12.7-slim
COPY --from=builder /install /usr/local

# Python normally buffers output, so docker logs can look empty or lose the last lines on a crash
# This makes every log line appear in docker logs immediately
ENV PYTHONUNBUFFERED=1

RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app app
WORKDIR /app
COPY app.py .
COPY static/ static/
USER app

EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--preload", "app:app"]
