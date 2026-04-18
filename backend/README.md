# Запуск

# 1. Запуск базы данных (из папки database)

```
cd database
chmod +x scripts/\*.sh
./scripts/start.sh
```

# 2. Запуск backend (из папки backend)

```

cd ../backend
chmod +x scripts/\*.sh
./scripts/start.sh

```

# Или запуск всего вместе из корня проекта:

```

cd backend && docker-compose up -d

```

# Запуск из корня проекта

```
# Остановить все контейнеры
sudo docker-compose down -v

# Очистить кэш Docker
sudo docker system prune -a -f
sudo docker builder prune -a -f

# Удалить все тома (ВНИМАНИЕ! Удалит данные всех проектов)
sudo docker volume prune -f

# Запустите 
sudo  docker-compose up -d

```

