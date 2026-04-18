# Инструкция по использованию

1.  **Сохраните скрипт** как `test_api.sh` в корне вашего проекта (рядом с `docker-compose.yml`).
2.  **Сделайте его исполняемым**:
    ```bash
    chmod +x test_api.sh
    ```
3.  **Убедитесь, что все контейнеры запущены**:
    ```bash
    sudo docker-compose up -d
    ```
4.  **Запустите тест**:
    ```bash
    ./test_api.sh
    ```
    Или, если ваш бэкенд слушает на другом порту/хосте:
    ```bash
    API_HOST=192.168.5.47 API_PORT=8000 ./test_api.sh
    ```

5.  **Результаты**:
    *   Полный лог выполнения появится в файле `api_test_2026_04_18_143022.log`.
    *   Токены для дебага сохранятся в `tokens_2026_04_18_143022.json`.

## Что делает скрипт по шагам (согласно ТЗ)

| Шаг | Модуль ТЗ | Эндпоинты |
|-----|-----------|-----------|
| 1 | Аутентификация | `/auth/login`, `/auth/me` |
| 2 | Роли и права | `/roles`, `/permissions` |
| 3 | Хакатоны | `GET /hackathons`, `POST /hackathons`, `GET /hackathons/active` |
| 4 | Дашборды | `/dashboard/admin`, `/dashboard/expert`, `/dashboard/team` |
| 5 | Пользователи | `GET /users`, `POST /users` (создаем эксперта и аккаунт команды) |
| 6 | Команды | `GET /teams`, `POST /teams`, `GET /teams/{id}`, `POST /teams/{id}/members` |
| 7 | Критерии | `GET /criteria`, `POST /criteria` (создаем 3 критерия с весами 40/30/30) |
| 8 | Назначения | `GET /assignments`, `POST /assignments` |
| 9 | Дедлайны | `GET /deadlines`, `POST /deadlines`, `GET /timer` |
| 10 | Оценивание (Эксперт) | `/my/assigned-teams`, `/my-evaluation/draft`, `/my-evaluation/submit` |
| 11 | Оценки (Админ) | `/evaluations`, `/teams/{id}/evaluations` |
| 12 | Результаты | `/results/recalculate`, `/results/leaderboard`, `/results/publish`, `/winners` |
| 13 | Кабинет команды | `/my/team`, `/my/team/members`, `/my/team/result` |
| 14 | Публичные API | `/public/hackathons/active`, `/public/leaderboard`, `/public/timer`, `/public/winners` |
| 15 | Аудит | `/audit-logs` |
| 16 | Выход | `/auth/logout` |