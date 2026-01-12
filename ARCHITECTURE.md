# 🏗️ Архитектура конфигурации Claude Code

## 📐 Обзор системы

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INPUT (Промпт)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              UserPromptSubmit HOOK                           │
│  (.claude/hooks/skill-activation-prompt.sh)                  │
│                                                               │
│  1. Перехватывает промпт                                     │
│  2. Анализирует контекст (файлы, путь, содержимое)          │
│  3. Проверяет skill-rules.json                               │
│  4. Матчит триггеры (keywords, patterns, files)              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
            ┌──────────┴──────────┐
            │  Match found?       │
            └──────────┬──────────┘
                  Yes  │  No
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────────┐    ┌──────────────────┐
│  Load Skill       │    │  Pass through    │
│  Instructions     │    │  unchanged       │
└────────┬──────────┘    └──────────┬───────┘
         │                          │
         └────────────┬─────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              ENHANCED PROMPT + SKILL CONTEXT                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    CLAUDE PROCESSING                         │
│                                                               │
│  Uses:                                                        │
│  • Skill guidelines                                           │
│  • Agent capabilities                                         │
│  • Command templates                                          │
│  • Guardrail rules                                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      OUTPUT / ACTION                         │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Поток активации Skills

### Пример: Backend разработка

```
USER: "Создай endpoint для получения пользователей"
  │
  ▼
Hook: Анализ промпта
  │
  ├─ Ключевые слова: "endpoint" ✓
  ├─ Намерение: "(создать|create).*endpoint" ✓
  └─ Контекст файлов: Нет
  │
  ▼
Match: fastapi-backend-guidelines
  │
  ├─ Type: domain
  ├─ Enforcement: suggest
  ├─ Priority: high
  └─ Триггеры: ✓ 2/3
  │
  ▼
Load: /skills/fastapi-backend-guidelines/skill.md
  │
  ▼
Enhanced Prompt:
  "Создай endpoint для получения пользователей

   [SKILL: fastapi-backend-guidelines]
   - Используй Router → Service → Repository
   - Применяй Dependency Injection
   - Используй Pydantic для валидации
   - Следуй Feature-First структуре
   ..."
  │
  ▼
Claude: Генерирует код с применением паттернов
```

## 🎯 Типы триггеров

### 1. Prompt Triggers (Триггеры промпта)

```json
{
  "promptTriggers": {
    "keywords": [
      "endpoint",      // Точное совпадение (case-insensitive)
      "FastAPI",
      "роутер"
    ],
    "intentPatterns": [
      "(создать|create).*endpoint",  // Regex намерение
      "(добавить|add).*?(роут|route)"
    ]
  }
}
```

**Как работает:**
1. Hook проверяет наличие keywords в промпте
2. Проверяет совпадение с regex patterns
3. Если хотя бы один match → skill активируется

### 2. File Triggers (Триггеры файлов)

```json
{
  "fileTriggers": {
    "pathPatterns": [
      "back/app/features/**/*.py",   // Glob pattern для путей
      "front/src/pages/**/*.tsx"
    ],
    "contentPatterns": [
      "@router\\.",                   // Regex для содержимого
      "class.*Service"
    ],
    "pathExclusions": [
      "**/*test*.py",                 // Исключения
      "**/__pycache__/**"
    ]
  }
}
```

**Как работает:**
1. Hook читает файлы в текущем контексте
2. Проверяет пути файлов (glob matching)
3. Проверяет содержимое (regex matching)
4. Применяет исключения
5. Если match → skill активируется

### 3. Комбинированные триггеры

Skills могут активироваться по **любому** из триггеров:
- Prompt Trigger ИЛИ File Trigger
- Несколько keywords
- Несколько patterns

## 🛡️ Enforcement механизмы

### Block (Блокировка)

```
USER: "DROP TABLE users"
  │
  ▼
Hook: database-verification
  │
  ├─ Enforcement: BLOCK
  ├─ Priority: CRITICAL
  └─ Pattern match: "DROP TABLE" ✓
  │
  ▼
БЛОКИРОВКА ВЫПОЛНЕНИЯ
  │
  ▼
OUTPUT:
"⛔ КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ
Операция DROP TABLE может привести к потере данных.
Требуется явное подтверждение и резервное копирование."
```

### Warn (Предупреждение)

```
USER: "Импортируй pages в widgets"
  │
  ▼
Hook: fsd-architecture-guard
  │
  ├─ Enforcement: WARN
  ├─ Priority: HIGH
  └─ Violation detected ✓
  │
  ▼
ПРЕДУПРЕЖДЕНИЕ (не блокирует)
  │
  ▼
OUTPUT:
"⚠️ ПРЕДУПРЕЖДЕНИЕ FSD
Нарушение архитектурных слоёв:
pages не должны импортироваться в widgets
Рекомендация: [исправления...]"
```

### Suggest (Рекомендация)

```
USER: "Создай компонент"
  │
  ▼
Hook: react-frontend-guidelines
  │
  ├─ Enforcement: SUGGEST
  ├─ Priority: HIGH
  └─ Keyword match ✓
  │
  ▼
ПРЕДЛОЖЕНИЕ (мягкое)
  │
  ▼
Enhanced Prompt + Guidelines применяются автоматически
```

## 🎨 Структура Skill

### Минимальный skill

```markdown
---
name: my-skill
description: Краткое описание
version: 1.0
---

# My Skill

## Применение
Когда использовать этот skill

## Инструкции
Что должен делать Claude
```

### Продвинутый skill

```markdown
---
name: fastapi-backend-guidelines
description: FastAPI best practices
version: 1.0
tags: [backend, python, fastapi]
priority: high
---

# FastAPI Backend Guidelines

## Architecture Layers

### 1. Router Layer
[Детальные инструкции...]

### 2. Service Layer
[Детальные инструкции...]

### 3. Repository Layer
[Детальные инструкции...]

## Code Examples
[Примеры кода...]

## Best Practices
[Лучшие практики...]

## Common Pitfalls
[Частые ошибки...]
```

## 🔌 Hook система

### UserPromptSubmit Hook

```bash
#!/bin/bash
# .claude/hooks/skill-activation-prompt.sh

# 1. Получить промпт от stdin
PROMPT=$(cat)

# 2. Получить контекст (файлы, путь)
CONTEXT=$(get_context)

# 3. Загрузить skill-rules.json
RULES=$(cat .claude/skills/skill-rules.json)

# 4. Матчинг триггеров
for skill in $RULES; do
  if matches_prompt_triggers "$PROMPT" "$skill"; then
    MATCHED_SKILLS+=("$skill")
  fi

  if matches_file_triggers "$CONTEXT" "$skill"; then
    MATCHED_SKILLS+=("$skill")
  fi
done

# 5. Загрузить skills по priority
sort_by_priority "$MATCHED_SKILLS"

# 6. Создать enhanced prompt
ENHANCED_PROMPT="$PROMPT\n"
for skill in $MATCHED_SKILLS; do
  SKILL_CONTENT=$(cat ".claude/skills/$skill/skill.md")
  ENHANCED_PROMPT+="\n[SKILL: $skill]\n$SKILL_CONTENT"
done

# 7. Вернуть enhanced prompt
echo "$ENHANCED_PROMPT"
```

### TypeScript Hook альтернатива

```typescript
// .claude/hooks/skill-activation-prompt.ts
import { readFileSync } from 'fs';
import { join } from 'path';

interface SkillRules {
  [skillName: string]: {
    type: 'guardrail' | 'domain';
    enforcement: 'block' | 'warn' | 'suggest';
    priority: 'critical' | 'high' | 'medium' | 'low';
    promptTriggers?: {
      keywords: string[];
      intentPatterns: string[];
    };
    fileTriggers?: {
      pathPatterns: string[];
      contentPatterns: string[];
    };
  };
}

async function activateSkills(prompt: string): Promise<string> {
  // 1. Загрузить правила
  const rules: SkillRules = JSON.parse(
    readFileSync('.claude/skills/skill-rules.json', 'utf-8')
  );

  // 2. Найти совпадения
  const matchedSkills: string[] = [];

  for (const [skillName, config] of Object.entries(rules)) {
    if (matchesPromptTriggers(prompt, config)) {
      matchedSkills.push(skillName);
    }
  }

  // 3. Сортировать по priority
  matchedSkills.sort((a, b) =>
    priorityWeight(rules[a].priority) - priorityWeight(rules[b].priority)
  );

  // 4. Загрузить skills
  let enhancedPrompt = prompt;
  for (const skillName of matchedSkills) {
    const skillContent = readFileSync(
      `.claude/skills/${skillName}/skill.md`,
      'utf-8'
    );
    enhancedPrompt += `\n\n[SKILL: ${skillName}]\n${skillContent}`;
  }

  return enhancedPrompt;
}
```

## 📊 Priority система

### Веса приоритетов

```
critical  = 1000  (всегда первым)
high      = 100   (важные)
medium    = 10    (средние)
low       = 1     (последними)
```

### Порядок загрузки

1. **Critical Guardrails** (database, security)
2. **High Priority Skills** (fastapi, react)
3. **Medium Priority Skills** (testing, performance)
4. **Low Priority Skills** (documentation)

## 🎯 Примеры матчинга

### Пример 1: Backend endpoint

```
Промпт: "Создай POST /api/users endpoint"

Матчинг:
├─ fastapi-backend-guidelines
│  ├─ keywords: ["endpoint", "API"] ✓
│  ├─ intentPatterns: "(создать|create).*endpoint" ✓
│  └─ MATCH (2/2) ✓
│
└─ database-migrations (нет match)
   └─ keywords: ["migration", "alembic"] ✗

Результат: Активируется fastapi-backend-guidelines
```

### Пример 2: React компонент

```
Промпт: "Добавь UserCard компонент"
Файл: front/src/entities/User/ui/UserCard.tsx (открыт)

Матчинг:
├─ react-frontend-guidelines
│  ├─ keywords: ["компонент"] ✓
│  ├─ fileTriggers: "front/src/entities/**/*.tsx" ✓
│  └─ MATCH (2/2) ✓
│
└─ fsd-architecture-guard
   ├─ fileTriggers: "front/src/entities/**/*.tsx" ✓
   └─ MATCH (1/1) ✓

Результат: Активируются оба skills
Порядок: react-frontend-guidelines → fsd-architecture-guard
```

### Пример 3: Критическая операция

```
Промпт: "DROP TABLE users"

Матчинг:
├─ database-verification (GUARDRAIL)
│  ├─ keywords: ["DROP TABLE"] ✓
│  ├─ enforcement: BLOCK ✓
│  ├─ priority: CRITICAL ✓
│  └─ MATCH + BLOCK ✓

Результат:
1. Активируется database-verification
2. Enforcement = BLOCK
3. Выполнение останавливается
4. Требуется подтверждение
```

## 🔄 Жизненный цикл запроса

```
1. USER INPUT
   └─> Пользователь вводит промпт

2. HOOK INTERCEPT
   └─> UserPromptSubmit перехватывает

3. CONTEXT GATHERING
   ├─> Текущие файлы
   ├─> Рабочая директория
   └─> История диалога

4. RULE MATCHING
   ├─> Проверка keywords
   ├─> Проверка patterns
   └─> Проверка file triggers

5. SKILL LOADING
   ├─> Сортировка по priority
   ├─> Загрузка skill.md
   └─> Объединение в enhanced prompt

6. ENFORCEMENT CHECK
   ├─> BLOCK → Остановка
   ├─> WARN → Предупреждение
   └─> SUGGEST → Применение

7. CLAUDE PROCESSING
   └─> Обработка с skill контекстом

8. OUTPUT
   └─> Результат пользователю
```

## 📈 Метрики и мониторинг

### Отслеживаемые события

```typescript
interface SkillActivationEvent {
  timestamp: Date;
  prompt: string;
  matchedSkills: string[];
  enforcement: 'block' | 'warn' | 'suggest';
  success: boolean;
}
```

### Логирование (опционально)

```bash
# ~/.claude/logs/skills.log
2026-01-12 10:30:15 [INFO] Activated: fastapi-backend-guidelines
2026-01-12 10:30:15 [INFO] Match: keywords=2, patterns=1, files=0
2026-01-12 10:30:16 [SUCCESS] Skill applied successfully
```

## 🎓 Расширение системы

### Добавление нового типа триггера

```typescript
interface CustomTrigger {
  type: 'git-branch' | 'time-of-day' | 'user-role';
  config: any;
}

// Пример: Активация skill в зависимости от git ветки
if (currentBranch === 'production') {
  activateSkill('production-safety-guardrails');
}
```

### Добавление нового enforcement

```typescript
type EnforcementType =
  | 'block'        // Полная блокировка
  | 'warn'         // Предупреждение
  | 'suggest'      // Рекомендация
  | 'require'      // Требование подтверждения
  | 'audit';       // Только логирование
```

---

**Документация версии**: 1.0
**Последнее обновление**: 2026-01-12
