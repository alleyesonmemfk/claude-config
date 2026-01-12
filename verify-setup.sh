#!/bin/bash

# Скрипт проверки установки Claude Code конфигурации

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

echo "═══════════════════════════════════════"
echo "  Claude Code Configuration Verifier"
echo "═══════════════════════════════════════"
echo ""

ERRORS=0

# Проверка основной структуры
echo "Проверка структуры..."
for dir in .claude .claude/agents .claude/commands .claude/hooks .claude/skills; do
  if [ -d "$dir" ]; then
    print_success "Директория $dir"
  else
    print_error "Отсутствует $dir"
    ((ERRORS++))
  fi
done

# Проверка settings.json
echo ""
echo "Проверка конфигурации..."
if [ -f ".claude/settings.json" ]; then
  print_success "settings.json найден"
  if command -v python3 &> /dev/null; then
    if python3 -m json.tool .claude/settings.json > /dev/null 2>&1; then
      print_success "settings.json валиден"
    else
      print_error "settings.json невалиден"
      ((ERRORS++))
    fi
  fi
else
  print_error "settings.json отсутствует"
  ((ERRORS++))
fi

# Проверка skill-rules.json
if [ -f ".claude/skills/skill-rules.json" ]; then
  print_success "skill-rules.json найден"
  if command -v python3 &> /dev/null; then
    if python3 -m json.tool .claude/skills/skill-rules.json > /dev/null 2>&1; then
      print_success "skill-rules.json валиден"
    else
      print_error "skill-rules.json невалиден"
      ((ERRORS++))
    fi
  fi
else
  print_error "skill-rules.json отсутствует"
  ((ERRORS++))
fi

# Проверка исполняемых прав
echo ""
echo "Проверка прав доступа..."
if [ -x ".claude/hooks/skill-activation-prompt.sh" ]; then
  print_success "Hook исполняемый"
else
  print_error "Hook не исполняемый"
  print_info "Исправление: chmod +x .claude/hooks/*.sh"
  ((ERRORS++))
fi

# Подсчёт файлов
echo ""
echo "Статистика..."
AGENTS=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
COMMANDS=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
SKILLS=$(find .claude/skills -type d -depth 1 2>/dev/null | wc -l | tr -d ' ')

print_info "Agents: $AGENTS"
print_info "Commands: $COMMANDS"
print_info "Skills: $SKILLS"

# Проверка документации
echo ""
echo "Проверка документации..."
for doc in README.md INSTALL.md CHEATSHEET.md ARCHITECTURE.md; do
  if [ -f "$doc" ]; then
    print_success "$doc"
  else
    print_error "Отсутствует $doc"
    ((ERRORS++))
  fi
done

# Итоговый результат
echo ""
echo "═══════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
  print_success "Все проверки пройдены успешно!"
  echo ""
  print_info "Конфигурация готова к использованию"
  echo ""
  echo "Запустите Claude Code:"
  echo "  claude"
  exit 0
else
  print_error "Обнаружено ошибок: $ERRORS"
  echo ""
  print_info "Исправьте ошибки и запустите проверку снова"
  exit 1
fi
