# Paydeya — AGENTS.md

> Инструкция для ИИ-агентов (opencode / cursor / copilot). Читать перед началом работы.

## О проекте

**Paydeya** — платформа для связи учеников и репетиторов.

Монорепозиторий-агрегатор, который содержит код и ссылки на два подмодуля-сервиса:

| Сабмодуль | Путь   | Репозиторий                                            | AGENTS.md            |
| --------- | ------ | ------------------------------------------------------ | -------------------- |
| Backend   | `backend/`  | https://github.com/Negative-Technolohies/paydeya-backend  | `backend/AGENTS.md`  |
| Frontend  | `frontend/` | https://github.com/Negative-Technolohies/paydeya-frontend | `frontend/AGENTS.md` |

Сабмодули привязаны к ветке `develop` их репозиториев и обновляются через GitHub Actions (`on-submodule-update.yml`).

## Структура репозитория

```
.
├── backend/                 # сабмодуль: FastAPI-бэкенд → backend/AGENTS.md
├── frontend/                # сабмодуль: Next.js-фронтенд → frontend/AGENTS.md
├── docs/
│   └── git-workflow.md      # правила веток, PR, ревью, Conventional Commits
├── .github/workflows/       # CI/CD: синхронизация сабмодулей, связка issues/project
└── README.md
```

## Git workflow

Подробный мануал — в [docs/git-workflow.md](docs/git-workflow.md). Кратко:

```
main (релизы) → develop (разработка) → feature/* / fix/*
hotfix/* — от main для срочных фиксов прода
```

- Ветки фич/фиксов ответвляются от `develop`, PR — в `develop` (не в `main`).
- Прямые коммиты в `main` и `develop` запрещены.
- Минимум 1 approver; автор не мержит свой PR.
- Мёржить только при зелёном CI.
- После мёржа feature-ветка удаляется.

## Коммиты: Conventional Commits

Формат: `<type>(<scope>): <описание на русском>`

- Типы: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Scope: backend — `auth`, `api`, `db`, `services`, `utils`; frontend — `ui`, `pages`, `hooks`, `store`, `api`

Примеры:
- `feat(auth): добавить форму регистрации с валидацией`
- `fix(api): обработать 404 при отсутствии пользователя`
- `test(db): покрыть UserRepository интеграционными тестами`

## CI/CD (GitHub Actions)

- Backend: `ruff` + `mypy` (линт), `pytest` (тесты), сборка образа.
- Frontend: `eslint` + `prettier` (линт), `vitest` (тесты), `next build` (сборка).
- Синхронизация сабмодулей: пуш в `develop` сабмодуля → dispatch в `paydeya` → обновление привязки сабмодуля.
- Smoke-тесты на `main`: `GET /ping` (backend), загрузка страницы (frontend).

## Разработка

Правила работы с сабмодулями:

```bash
# обновить сабмодули
git submodule update --remote backend frontend

# работаем внутри сабмодуля как с отдельным репозиторием
cd backend   # или frontend
git checkout -b feature/GH-123-описание develop
```

Команды запуска и структура каждого сервиса — в `backend/AGENTS.md` и `frontend/AGENTS.md`.
