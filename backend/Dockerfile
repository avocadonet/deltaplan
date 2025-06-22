FROM python:3.11-slim-bookworm AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .

RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

RUN addgroup --system app && adduser --system --group app

WORKDIR /app

RUN mkdir -p /app/static /app/media && chown -R app:app /app

COPY --from=builder /app/wheels /wheels


RUN pip install --no-cache /wheels/*

COPY ./deltaplan .

RUN chown -R app:app /app

USER app

RUN python manage.py collectstatic --no-input

EXPOSE 8000

CMD ["gunicorn", "deltaplan.wsgi:application", "--bind", "0.0.0.0:8000", "--timeout", "120"]