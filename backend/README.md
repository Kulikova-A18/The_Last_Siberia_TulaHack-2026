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

docker-compose up -d

```

```

```
