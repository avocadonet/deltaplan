FROM python:3.11-slim as builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY requirements.txt .

RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

FROM python:3.11-slim

RUN addgroup --system app && adduser --system --group app

WORKDIR /app

RUN mkdir -p /app/static /app/media && chown -R app:app /app

COPY --from=builder /app/wheels /wheels
COPY requirements.txt .

RUN pip install --no-cache /wheels/*

COPY ./deltaplan .

RUN python manage.py collectstatic --no-input

RUN chown -R app:app /app

USER app

EXPOSE 8000

CMD ["gunicorn", "deltaplan.wsgi:application", "--bind", "0.0.0.0:8000", "--timeout", "120"]