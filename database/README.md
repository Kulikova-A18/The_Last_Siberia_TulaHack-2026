Вот русифицированная версия README:

# База данных Хакатона - Настройка PostgreSQL

## Быстрый старт

```bash
# Запуск базы данных
./scripts/start.sh

# Остановка базы данных
./scripts/stop.sh

# Сброс базы данных (удаляет все данные!)
./scripts/reset.sh

# Резервное копирование базы данных
./scripts/backup.sh
```

## Переменные окружения

Создайте файл `.env` из `.env.example` и настройте параметры:

```bash
cp .env.example .env
```

## Схема базы данных

База данных включает:

- **Пользователи и роли**: RBAC с ролями (admin, expert, team)
- **Команды**: Информация о командах и участниках
- **Критерии**: Критерии оценки с весами
- **Оценки**: Экспертные оценки и баллы
- **Результаты**: Кэшированная таблица лидеров и результатов
- **Журналы аудита**: Полная история действий

## Информация для подключения

После запуска:

- **PostgreSQL**: `localhost:5432`
- **pgAdmin**: `http://localhost:5050`
- **Строка подключения**: `postgresql://hackathon_admin:SecurePass123!@localhost:5432/hackathon_db`

## Резервное копирование и восстановление

### Резервное копирование

```bash
./scripts/backup.sh
```

### Восстановление

```bash
docker exec -i hackathon_postgres psql -U hackathon_admin -d hackathon_db < backup.sql
```

## Мониторинг

### Проверка состояния базы данных

```bash
./scripts/healthcheck.sh
```

### Просмотр логов

```bash
docker-compose logs -f postgres
```

### Подключение к базе данных

```bash
docker exec -it hackathon_postgres psql -U hackathon_admin -d hackathon_db
```

## Настройка производительности

База данных настроена с параметрами:

- **Общие буферы**: 256MB
- **Эффективный кэш**: 768MB
- **Рабочая память**: 4MB
- **Лимит подключений**: 200

## Безопасность

- Пароли хранятся с использованием SCRAM-SHA-256
- Изоляция сети через Docker сети
- Журналирование аудита для всех критических операций
- Управление доступом на основе ролей (RBAC)

## Устранение неполадок

### Невозможно подключиться к базе данных

```bash
docker-compose logs postgres
docker exec hackathon_postgres pg_isready
```

### Медленные запросы

```bash
docker exec hackathon_postgres psql -U hackathon_admin -d hackathon_db -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

### Проблемы с дисковым пространством

```bash
docker system df
docker volume prune
```

## Обслуживание

### Вакуумирование базы данных

```bash
docker exec hackathon_postgres psql -U hackathon_admin -d hackathon_db -c "VACUUM ANALYZE;"
```

### Переиндексация базы данных

```bash
docker exec hackathon_postgres psql -U hackathon_admin -d hackathon_db -c "REINDEX DATABASE hackathon_db;"
```

## CI/CD

GitHub Actions автоматически:

1. Запускает тесты при каждом push
2. Собирает Docker образ в основной ветке
3. Развертывает на production при успешной сборке

## Поддержка

При возникновении проблем проверьте:

- Логи базы данных: `docker-compose logs postgres`
- Журналы аудита: `SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 50;`

## Полная настройка включает:

1. **Полноценную базу данных PostgreSQL** со всеми таблицами
2. **Автоматическую инициализацию** с тестовыми данными
3. **Bash скрипты** для удобного управления (запуск, остановка, сброс, резервное копирование, проверка состояния)
4. **Конфигурацию Docker Compose** с pgAdmin
5. **GitHub Actions** для CI/CD (тестирование, сборка, развертывание)
6. **Оптимизацию производительности** с индексами и настройками
7. **Функции безопасности** включая шифрование и RBAC
8. **Возможности мониторинга и логирования**

## Использование:

```bash
cd database
chmod +x scripts/*.sh
./scripts/start.sh
```

База данных будет полностью инициализирована со всеми таблицами, ролями, разрешениями и пользователем-администратором по умолчанию (логин: admin, пароль: Admin123!).
