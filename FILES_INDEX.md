# 📁 Индекс файлов конфигурации

## 📄 Документация (корневая папка)

| Файл | Размер | Описание |
|------|--------|----------|
| [README.md](./README.md) | 10KB | Главная документация, обзор возможностей |
| [QUICKSTART.md](./QUICKSTART.md) | 1KB | Быстрый старт за 3 шага |
| [INSTALL.md](./INSTALL.md) | 4.5KB | Подробные инструкции по установке |
| [CHEATSHEET.md](./CHEATSHEET.md) | 7.5KB | Шпаргалка по командам и использованию |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 16KB | Техническая архитектура системы |
| [SETUP_COMPLETE.md](./SETUP_COMPLETE.md) | 8KB | Отчёт о завершении установки |
| [SUMMARY.txt](./SUMMARY.txt) | 3KB | Краткое резюме (текстовый формат) |
| [FILES_INDEX.md](./FILES_INDEX.md) | этот файл | Индекс всех файлов |

## 🔧 Скрипты

| Файл | Размер | Описание |
|------|--------|----------|
| [install.sh](./install.sh) | 10KB | Интерактивный установщик с проверками |
| [verify-setup.sh](./verify-setup.sh) | 3KB | Проверка корректности установки |

## 📂 Структура .claude/

### Конфигурация

| Файл | Описание |
|------|----------|
| [.claude/settings.json](./.claude/settings.json) | Основные настройки + UserPromptSubmit hook |
| [.claude/README.md](./.claude/README.md) | Документация конфигурации |

### Agents (4 файла)

| Файл | Описание |
|------|----------|
| [auto-error-resolver.md](./.claude/agents/auto-error-resolver.md) | Автоматическое исправление ошибок TypeScript |
| [code-architecture-reviewer.md](./.claude/agents/code-architecture-reviewer.md) | Глубокий архитектурный анализ |
| [documentation-architect.md](./.claude/agents/documentation-architect.md) | Создание и обновление документации |
| [frontend-error-fixer.md](./.claude/agents/frontend-error-fixer.md) | Исправление ошибок фронтенда |

### Commands (5 файлов)

| Файл | Описание |
|------|----------|
| [build-and-fix.md](./.claude/commands/build-and-fix.md) | CI-пайплайн с автоисправлением |
| [dev-docs.md](./.claude/commands/dev-docs.md) | Создание технического плана |
| [dev-docs-update.md](./.claude/commands/dev-docs-update.md) | Checkpoint перед сбросом контекста |
| [test-auth-endpoint.md](./.claude/commands/test-auth-endpoint.md) | Тестирование JWT эндпоинтов |
| [verify.md](./.claude/commands/verify.md) | Глубокий аудит кода |

### Hooks

| Файл | Описание |
|------|----------|
| [skill-activation-prompt.sh](./.claude/hooks/skill-activation-prompt.sh) | Основной hook для активации skills (Bash) |
| [skill-activation-prompt.ts](./.claude/hooks/skill-activation-prompt.ts) | TypeScript версия hook |
| [skill-activation-prompt.js](./.claude/hooks/skill-activation-prompt.js) | JavaScript версия hook |
| node_modules/ | TypeScript зависимости (@types/node) |

### Skills

| Папка/Файл | Описание |
|------------|----------|
| [skill-rules.json](./.claude/skills/skill-rules.json) | **Главный файл правил активации** |
| fastapi-backend-guidelines/ | Backend паттерны (FastAPI/Python/SQLAlchemy) |
| react-frontend-guidelines/ | Frontend паттерны (React/TypeScript/FSD) |
| database-migrations/ | Alembic миграции |
| oauth-integration/ | OAuth 2.0 (Google, Telegram) |
| api-client-generation/ | Orval генерация клиентов |
| skill-developer/ | Создание новых skills |
| + 9 других skills | Всего 15+ skills |

## 🔍 Ключевые файлы для редактирования

### Для кастомизации:

1. **[.claude/skills/skill-rules.json](./.claude/skills/skill-rules.json)**
   - Правила автоактивации skills
   - Keywords, patterns, file triggers
   - Enforcement levels (block/warn/suggest)

2. **[.claude/settings.json](./.claude/settings.json)**
   - Настройка hooks
   - Основная конфигурация Claude Code

### Для создания нового контента:

3. **Новый skill**: `.claude/skills/my-skill/skill.md`
4. **Новый agent**: `.claude/agents/my-agent.md`
5. **Новая команда**: `.claude/commands/my-command.md`

## 📊 Статистика файлов

```
Общая структура:
├── Документация:        8 файлов (50KB)
├── Скрипты:             2 файла (13KB)
├── .claude/agents:      4 файла
├── .claude/commands:    5 файлов
├── .claude/skills:      15+ skills
└── .claude/hooks:       Bash + TypeScript + deps

Всего:
- Markdown файлов: 49
- JSON конфигураций: 25
- Исполняемых скриптов: 3
- Директорий: 59
```

## 🚀 Workflow использования

1. **Первое чтение**: [QUICKSTART.md](./QUICKSTART.md) (2 минуты)
2. **Установка**: `./install.sh` (5 минут)
3. **Проверка**: `./verify-setup.sh` (30 секунд)
4. **Справка**: [CHEATSHEET.md](./CHEATSHEET.md) (держать под рукой)
5. **Углубление**: [ARCHITECTURE.md](./ARCHITECTURE.md) (для понимания)

## 📖 Когда что читать

| Задача | Файл |
|--------|------|
| Быстро начать | [QUICKSTART.md](./QUICKSTART.md) |
| Установить | [INSTALL.md](./INSTALL.md) |
| Посмотреть команды | [CHEATSHEET.md](./CHEATSHEET.md) |
| Понять систему | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| Обзор возможностей | [README.md](./README.md) |
| Кастомизировать | `.claude/skills/skill-rules.json` |

## 🔗 Навигация

- **Главная**: [README.md](./README.md)
- **Быстрый старт**: [QUICKSTART.md](./QUICKSTART.md)
- **Установка**: [INSTALL.md](./INSTALL.md)
- **Справка**: [CHEATSHEET.md](./CHEATSHEET.md)
- **Архитектура**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Конфигурация**: [.claude/README.md](./.claude/README.md)

---

**Обновлено**: 2026-01-12
**Версия**: 1.0
