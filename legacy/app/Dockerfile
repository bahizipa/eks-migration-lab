FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir flask==3.0.3 psycopg[binary]==3.2.1 gunicorn==22.0.0
COPY app.py .
EXPOSE 8080
USER 1000
CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "2", "app:app"]
