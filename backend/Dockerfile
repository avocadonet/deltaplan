FROM python:3.11-slim-bookworm AS builder

WORKDIR /app_builder

COPY requirements.txt .

RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

FROM python:3.11-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/*

RUN addgroup --system app && adduser --system --ingroup app app

COPY --from=builder /wheels /wheels

RUN pip install --no-cache /wheels/*.whl

COPY . .

RUN mkdir -p /app/deltaplan/static /app/deltaplan/media && chown -R app:app /app/deltaplan/static /app/deltaplan/media

RUN chown -R app:app /app
USER app

WORKDIR /app/deltaplan
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "deltaplan.wsgi:application", "--bind", "0.0.0.0:8000", "--timeout", "120"]
