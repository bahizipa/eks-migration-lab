import os
import psycopg
from flask import Flask, jsonify, request

app = Flask(__name__)
DATABASE_URL = os.environ["DATABASE_URL"]
APP_ENV = os.environ.get("APP_ENV", "unknown")


def conn():
    return psycopg.connect(DATABASE_URL, connect_timeout=3)


@app.get("/health")
def health():
    try:
        with conn() as c:
            c.execute("SELECT 1")
        return jsonify(status="ok", env=APP_ENV), 200
    except Exception as e:  # noqa: BLE001
        return jsonify(status="degraded", env=APP_ENV, error=str(e)), 503


@app.get("/notes")
def list_notes():
    with conn() as c:
        rows = c.execute("SELECT id, title, body, created_at FROM notes ORDER BY id").fetchall()
    return jsonify([dict(id=r[0], title=r[1], body=r[2], created_at=r[3].isoformat()) for r in rows])


@app.post("/notes")
def create_note():
    data = request.get_json(force=True)
    with conn() as c:
        row = c.execute(
            "INSERT INTO notes (title, body) VALUES (%s, %s) RETURNING id",
            (data["title"], data.get("body")),
        ).fetchone()
    return jsonify(id=row[0]), 201


@app.get("/notes/count")
def count():
    with conn() as c:
        n = c.execute("SELECT count(*) FROM notes").fetchone()[0]
    return jsonify(count=n, env=APP_ENV)
