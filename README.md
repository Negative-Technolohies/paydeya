# paydeya

Платформа связи учеников и репетиторов.

Монорепозиторий-обёртка: сам код живёт в git-сабмодулях.

| Часть | Репозиторий | Стек |
| --- | --- | --- |
| **backend** | [paydeya-backend](https://github.com/Negative-Technolohies/paydeya-backend) | Python 3.13, FastAPI, SQLAlchemy 2 (async), PostgreSQL, Redis, uv |
| **frontend** | [paydeya-frontend](https://github.com/Negative-Technolohies/paydeya-frontend) | Next.js (App Router), TypeScript, Tailwind CSS, npm |

## Установка проекта на новый компьютер

Раздел описывает быструю развёртку проекта с сабмодулями. Проходит за одну команду при выполненных предусловиях.

### Предусловия

| Инструмент | Версия | Зачем |
| --- | --- | --- |
| **git** | 2.x | клонирование и работа с сабмодулями |
| **SSH-ключ** | добавлен в GitHub | сабмодули подключаются по `git@github.com` |
| **Docker** | Docker Desktop / Engine | запуск backend (`make dev`) |
| **Node.js** | 20+ | frontend (`npm install`, `npm run dev`) |
| **npm** | любой актуальный | пакетный менеджер frontend |
| **uv** | опционально | установка зависимостей backend без Docker |
| **make** | опционально | запуск установки через `make setup` |

> Проверка доступа к сабмодулям по ssh: `ssh -T git@github.com` — ожидаем ответ «successfully authenticated». Если его нет — добавь ключ: `ssh-keygen -t ed25519 -C "you@example.com"`, затем ключ в [GitHub → Settings → SSH keys](https://github.com/settings/keys).

### Быстрая установка (одна команда)

Клонирование с сабмодулями + установка зависимостей.

> Разработка идёт на ветке **develop** (все рабочие версии лежат там, не в main). Одна команда выше клонирует сразу `-b develop`, а скрипт дополнительно переводит и сабмодули на `develop` (их последние коммиты, а не закреплённые в суперпроекте). Переопределяется флагом `--branch`.

**Windows — PowerShell (любая версия):**

```powershell
git clone -b develop --recurse-submodules git@github.com:Negative-Technolohies/paydeya.git; cd paydeya; .\setup.ps1
```

**Windows — Git Bash / PowerShell 7+, Linux, macOS:**

```bash
git clone -b develop --recurse-submodules git@github.com:Negative-Technolohies/paydeya.git && cd paydeya && ./setup.sh
```

**Через Makefile (нужен `make`; на Windows — из Git Bash/WSL):**

```bash
git clone -b develop --recurse-submodules git@github.com:Negative-Technolohies/paydeya.git && cd paydeya && make setup
```

Если репозиторий уже склонирован (например, с ошибкой сабмодулей) — просто запусти скрипт из корня:

```bash
./setup.sh          # Linux / macOS / Git Bash
.\setup.ps1         # Windows PowerShell
make setup          # любой вариант
```

### Что делает скрипт

1. Проверяет предусловия (git, доступ к GitHub по ssh, docker, node/npm, uv) — при отсутствии выводит предупреждение, но не прерывается.
2. Переключает репозиторий на ветку `develop` (флаг `--branch` меняет ветку, `--no-branch` отключает).
3. Инициализирует сабмодули: `git submodule update --init --recursive` и переводит их на ту же ветку.
4. Создаёт `backend/.env.dev` из `backend/.env.example`, если тот отсутствует.
5. Устанавливает зависимости backend: `uv sync` (если установлен uv).
6. Устанавливает зависимости frontend: `npm install` (при `--ci` — `npm ci`).
7. Выводит краткую инструкцию по запуску.

Скрипт идемпотентный — повторный запуск безопасен.

### Флаги скриптов

| Флаг | Описание |
| --- | --- |
| `--branch <name>` | ветка для главного репозитория и сабмодулей (по умолчанию `develop`) |
| `--latest` | обновить сабмодули до актуальных веток (`--remote`) вместо закреплённых коммитов |
| `--ci` | ставить frontend через `npm ci` (по `package-lock.json`) |
| `--no-branch` | не переключать ветки (оставить текущую) |
| `--no-submodules` | пропустить шаг сабмодулей |
| `--no-backend` | пропустить настройку backend |
| `--no-frontend` | пропустить установку frontend |

В PowerShell те же флаги в PascalCase (`-Branch`, `-Ci`, `-NoBranch`, …). В Makefile: `make setup FLAGS="--latest"`.

## Запуск

**Backend** (Docker, поднимает БД, порт 7812):

```bash
cd backend
make dev        # docker compose up --build
```

**Backend** (локально без Docker, нужен запущенный PostgreSQL на `localhost:5432`):

```bash
cd backend
uv run uvicorn app.main:app --host 0.0.0.0 --port 7812 --reload
```

**Frontend** (http://localhost:3000):

```bash
cd frontend
npm run dev
```

## Полезные команды

**Backend** (`cd backend`):

| Команда | Описание |
| --- | --- |
| `make dev` | запуск в Docker (backend + PostgreSQL) |
| `make test` | тесты (`uv run pytest -v`) |
| `make lint` | линтер (`uv run ruff check .`) |
| `make format` | форматирование (`uv run ruff format .`) |
| `make migrate` | применить миграции |
| `make seed` | применить все сиды |

**Frontend** (`cd frontend`):

| Команда | Описание |
| --- | --- |
| `npm run dev` | dev-сервер |
| `npm run build` / `npm start` | продакшн-сборка и запуск |
| `npm run lint` | eslint |

Полное описание команд backend и frontend — в `AGENTS.md` внутри сабмодулей.

## Troubleshooting

| Проблема | Решение |
| --- | --- |
| `Permission denied (publickey)` при clone/update | SSH-ключ не настроен — см. раздел «Предусловия» |
| `fatal: remote error: Repository not found` | сабмодуль приватный — проверь доступ к `paydeya-backend`/`paydeya-frontend` |
| Нет `node` / `npm` | поставь Node.js 20+ (рекомендуется через nvm: `nvm install 20`) |
| `docker: command not found` | запусти Docker Desktop / установи Docker Engine; для установки без Docker замени `make dev` на `uv run uvicorn ...` |
| Порт 5432/7812/3000 занят | останови конкурента (`netstat -ano | findstr :5432`) или смени порт в `docker-compose.yml` / `.env.dev` |
| Папка `backend` / `frontend` пустая | не подтянулись сабмодули — запусти `git submodule update --init --recursive` |
| Ошибка при `npm install` | проверь версию Node (`node -v` — должна быть 20+), затем переустанови `rm -rf node_modules package-lock.json`, `npm install` |