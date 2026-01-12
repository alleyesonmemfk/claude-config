#!/bin/bash

# Claude Code Configuration Installer
# Автоматическая установка конфигурации Claude Code в проект

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция вывода с цветом
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Claude Code Configuration Installer${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"
}

# Проверка наличия .claude в текущей директории
check_source() {
    if [ ! -d ".claude" ]; then
        print_error "Папка .claude не найдена в текущей директории"
        print_info "Пожалуйста, запустите скрипт из папки конфиг-клод-кода"
        exit 1
    fi
    print_success "Найдена исходная конфигурация .claude"
}

# Интерактивный выбор целевой директории
choose_target() {
    print_header
    echo "Выберите вариант установки:"
    echo ""
    echo "1) Установить в существующий проект (укажите путь)"
    echo "2) Установить в домашнюю директорию (~/.claude) - глобально"
    echo "3) Использовать текущую директорию (уже установлено)"
    echo "4) Выход"
    echo ""
    read -p "Выберите вариант [1-4]: " choice

    case $choice in
        1)
            read -p "Введите полный путь к проекту: " TARGET_DIR
            if [ ! -d "$TARGET_DIR" ]; then
                print_error "Директория $TARGET_DIR не существует"
                exit 1
            fi
            TARGET_PATH="$TARGET_DIR/.claude"
            ;;
        2)
            TARGET_PATH="$HOME/.claude"
            TARGET_DIR="$HOME"
            print_info "Установка глобальной конфигурации в $TARGET_PATH"
            ;;
        3)
            print_success "Конфигурация уже в текущей директории"
            print_info "Проверяю целостность установки..."
            verify_installation "."
            exit 0
            ;;
        4)
            print_info "Установка отменена"
            exit 0
            ;;
        *)
            print_error "Неверный выбор"
            exit 1
            ;;
    esac
}

# Резервное копирование существующей конфигурации
backup_existing() {
    if [ -d "$1" ]; then
        BACKUP_DIR="${1}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Обнаружена существующая конфигурация"
        read -p "Создать резервную копию? [Y/n]: " backup_choice
        if [ "$backup_choice" != "n" ] && [ "$backup_choice" != "N" ]; then
            mv "$1" "$BACKUP_DIR"
            print_success "Резервная копия создана: $BACKUP_DIR"
        else
            print_warning "Существующая конфигурация будет перезаписана"
            rm -rf "$1"
        fi
    fi
}

# Копирование файлов
install_config() {
    print_info "Копирую конфигурацию в $TARGET_PATH..."

    # Создаём целевую директорию
    mkdir -p "$TARGET_PATH"

    # Копируем структуру
    cp -r .claude/agents "$TARGET_PATH/"
    print_success "Скопированы agents"

    cp -r .claude/commands "$TARGET_PATH/"
    print_success "Скопированы commands"

    cp -r .claude/skills "$TARGET_PATH/"
    print_success "Скопированы skills"

    cp -r .claude/hooks "$TARGET_PATH/"
    print_success "Скопированы hooks"

    cp .claude/settings.json "$TARGET_PATH/"
    print_success "Скопирован settings.json"

    if [ -f ".claude/README.md" ]; then
        cp .claude/README.md "$TARGET_PATH/"
        print_success "Скопирован README.md"
    fi
}

# Настройка прав доступа
setup_permissions() {
    print_info "Настройка прав доступа..."
    chmod +x "$TARGET_PATH"/hooks/*.sh 2>/dev/null || true
    print_success "Hooks сделаны исполняемыми"
}

# Проверка зависимостей Node.js
check_node_deps() {
    if [ -d "$TARGET_PATH/hooks/node_modules" ]; then
        print_success "Node.js зависимости найдены"
    else
        print_warning "Node.js зависимости отсутствуют"
        read -p "Установить зависимости? (требуется npm) [Y/n]: " install_deps
        if [ "$install_deps" != "n" ] && [ "$install_deps" != "N" ]; then
            if command -v npm &> /dev/null; then
                print_info "Установка @types/node..."
                cd "$TARGET_PATH/hooks"
                npm install @types/node --silent
                cd - > /dev/null
                print_success "Зависимости установлены"
            else
                print_warning "npm не найден. Установите Node.js для полной функциональности"
            fi
        fi
    fi
}

# Проверка установки
verify_installation() {
    local check_dir="$1/.claude"
    print_info "Проверка установки..."

    local errors=0

    # Проверка основных директорий
    for dir in agents commands hooks skills; do
        if [ -d "$check_dir/$dir" ]; then
            print_success "Директория $dir найдена"
        else
            print_error "Директория $dir отсутствует"
            ((errors++))
        fi
    done

    # Проверка settings.json
    if [ -f "$check_dir/settings.json" ]; then
        print_success "Файл settings.json найден"
        # Проверка валидности JSON
        if command -v python3 &> /dev/null; then
            if python3 -m json.tool "$check_dir/settings.json" > /dev/null 2>&1; then
                print_success "settings.json валиден"
            else
                print_error "settings.json содержит ошибки"
                ((errors++))
            fi
        fi
    else
        print_error "Файл settings.json отсутствует"
        ((errors++))
    fi

    # Проверка skill-rules.json
    if [ -f "$check_dir/skills/skill-rules.json" ]; then
        print_success "Файл skill-rules.json найден"
        if command -v python3 &> /dev/null; then
            if python3 -m json.tool "$check_dir/skills/skill-rules.json" > /dev/null 2>&1; then
                print_success "skill-rules.json валиден"
            else
                print_error "skill-rules.json содержит ошибки"
                ((errors++))
            fi
        fi
    else
        print_error "Файл skill-rules.json отсутствует"
        ((errors++))
    fi

    # Проверка исполняемых прав на hooks
    if [ -x "$check_dir/hooks/skill-activation-prompt.sh" ]; then
        print_success "Hook исполняемый"
    else
        print_warning "Hook не исполняемый (будет исправлено)"
        chmod +x "$check_dir/hooks"/*.sh 2>/dev/null
    fi

    echo ""
    if [ $errors -eq 0 ]; then
        print_success "Установка прошла успешно!"
        return 0
    else
        print_error "Обнаружено ошибок: $errors"
        return 1
    fi
}

# Вывод информации об использовании
print_usage_info() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Установка завершена успешно!              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_info "Конфигурация установлена в: $TARGET_PATH"
    echo ""
    echo "Следующие шаги:"
    echo ""
    echo "1. Перейдите в директорию проекта:"
    echo -e "   ${YELLOW}cd $TARGET_DIR${NC}"
    echo ""
    echo "2. Запустите Claude Code:"
    echo -e "   ${YELLOW}claude${NC}"
    echo ""
    echo "3. Протестируйте конфигурацию:"
    echo -e "   ${YELLOW}Создай новый FastAPI endpoint${NC}"
    echo ""
    echo "Доступные команды:"
    echo "  /verify              - Глубокий аудит кода"
    echo "  /build-and-fix       - Автосборка с исправлением ошибок"
    echo "  /dev-docs            - Создание тех-плана"
    echo "  /test-auth-endpoint  - Тестирование JWT эндпоинтов"
    echo ""
    echo "Документация: $TARGET_PATH/README.md"
    echo ""
}

# Основная функция
main() {
    print_header
    check_source
    choose_target
    backup_existing "$TARGET_PATH"
    install_config
    setup_permissions
    check_node_deps

    echo ""
    verify_installation "$TARGET_DIR"

    if [ $? -eq 0 ]; then
        print_usage_info
    else
        print_error "Установка завершена с ошибками"
        exit 1
    fi
}

# Запуск
main
