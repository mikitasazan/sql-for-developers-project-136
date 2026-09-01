# Образовательная платформа

Схема базы данных для образовательной платформы (курсы, программы обучения,
зачисления, оплаты, сертификаты) — один файл `database.sql` с DDL, без
приложения поверх него.

Сущности: `programs` (программы обучения) → `modules` → `courses` → `lessons`
(через связующие таблицы `program_modules`, `module_courses`); `users` с ролью
(`student`/`teacher`/`admin`) и опциональной учебной группой
(`teaching_groups`); `enrollments` (зачисление на программу) с `payments` и
`program_completions`; `certificates`, `quizzes`, `exercises`, `discussions`,
`blogs`.

### Hexlet tests and linter status:
[![Actions Status](https://github.com/mikitasazan/sql-for-developers-project-136/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/mikitasazan/sql-for-developers-project-136/actions)

## Стек

- PostgreSQL (DDL: `ENUM`, `BIGSERIAL`, `TIMESTAMPTZ`, `JSONB`, `CHECK`,
  внешние ключи с `ON DELETE CASCADE/RESTRICT/SET NULL`)

## Проверка локально

Готового приложения нет — артефакт этого проекта сама схема. Проверяется
применением `database.sql` к чистой базе:

```bash
docker run -d --name edu-platform-pg -e POSTGRES_PASSWORD=audit \
  -e POSTGRES_USER=audit -e POSTGRES_DB=edu_platform -p 55432:5432 postgres:18-alpine

PGPASSWORD=audit psql -h 127.0.0.1 -p 55432 -U audit -d edu_platform \
  -v ON_ERROR_STOP=1 -f database.sql
# ожидаемо: 5x CREATE TYPE, 16x CREATE TABLE, без ошибок

docker rm -f edu-platform-pg
```
