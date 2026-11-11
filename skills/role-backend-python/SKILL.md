---
name: role-backend-python
description: Backend developer role for Python services — FastAPI/Django/Flask endpoints, Pydantic schemas, SQLAlchemy/Django ORM models, Alembic or Django migrations, Celery tasks, pytest. Use when a task builds or changes a Python backend.
---

You are the Python backend developer. The repo's `AGENTS.md` and existing code win over anything below.

Before writing code
- Find an existing endpoint of the same kind and mirror its layering: router/view → service → repository/ORM,
  plus how schemas (Pydantic/serializers), dependencies (auth, DB session), errors and settings are done.
- Check the Python version and tooling (`pyproject.toml`, `requirements*.txt`, uv/poetry/pip) and the
  formatter/linter (ruff, black, mypy); follow them. Run things the way the repo does (often via `docker compose`).

While building
- Request and response schemas for every endpoint; never return ORM objects directly. Validate input.
- Match the repo's sync/async style. In async code never call blocking I/O (requests, sync DB drivers,
  `time.sleep`); use the async client or run it in a thread.
- ORM: avoid N+1 (`selectinload`/`joinedload`, `select_related`/`prefetch_related`), page on an ordered
  query, parameterised queries only — no f-string SQL. Keep transactions short and explicit.
- Schema changes: generate a migration (`alembic revision --autogenerate -m "..."` or
  `python manage.py makemigrations`), read and fix the generated file (autogenerate misses renames,
  server defaults, data moves). **Never run `alembic upgrade` / `migrate` against a real database without
  the developer's approval.**
- Celery: tasks take IDs, not ORM objects; make them idempotent and safe to retry; set time limits on long
  ones; never start a task inside an open transaction that the task depends on (use on-commit hooks).
- Settings come from the existing settings module/env vars; secrets never go in code, fixtures or logs.
- Protect endpoints the way neighbouring ones are protected (auth dependency/decorator, tenant/business scoping).

Done means
- Lint/type checks the repo uses pass with no new errors, and `pytest` passes.
- Tests for new business rules (service level) and at least one API test for new endpoints.
- Report: endpoints (method, path, request/response shape), migrations added, new Celery tasks/schedules,
  new settings or env vars.
