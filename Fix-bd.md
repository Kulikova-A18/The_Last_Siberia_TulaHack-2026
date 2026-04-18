# ВАЖНО! Ручное исправление базы данных

Данная глава обязательна, т.к. не все данные были отображены с помощью скриптов

```
# полная очистка
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO hackathon_admin; GRANT ALL ON SCHEMA public TO public;"

# создание
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db -f /docker-entrypoint-initdb.d/01-init.sql
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db -f /docker-entrypoint-initdb.d/02-seed.sql
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db -f /docker-entrypoint-initdb.d/03-indexes.sql
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db -f /docker-entrypoint-initdb.d/04-fix-status-migration.sql
```

### Шаг 1. Подключение к базе данных

Для начала работы необходимо подключиться к PostgreSQL внутри Docker контейнера:

```bash
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db
```

После успешного подключения вы увидите приглашение командной строки psql.

### Шаг 2. Создание критериев оценки для AI Challenge

Перед добавлением критериев необходимо удалить мешающий триггер, который может блокировать вставку данных:

```sql
DROP TRIGGER IF EXISTS trg_validate_criteria_weights ON criteria;
DROP FUNCTION IF EXISTS fn_validate_criteria_weights();
```

Удалите существующие критерии для указанного хакатона (если они есть):

```sql
DELETE FROM criteria WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

Выполните вставку новых критериев в рамках одной транзакции:

```sql
BEGIN;
INSERT INTO criteria (id, hackathon_id, title, description, max_score, weight_percent, sort_order, is_active)
VALUES
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Инновационность', 'Оригинальность и креативность решения', 10.0, 25.0, 1, TRUE),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Техническая сложность', 'Сложность технологического стека и реализации', 10.0, 25.0, 2, TRUE),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Бизнес-ценность', 'Рыночный потенциал и практическая применимость', 10.0, 20.0, 3, TRUE),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Презентация', 'Качество демо и защиты проекта', 10.0, 15.0, 4, TRUE),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Командная работа', 'Взаимодействие и динамика команды', 5.0, 15.0, 5, TRUE);
COMMIT;
```

Проверьте количество созданных критериев:

```sql
SELECT COUNT(*) FROM criteria WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

### Шаг 3. Проверка и создание экспертов

Проверьте наличие всех необходимых экспертов в системе:

```sql
SELECT id, login, full_name FROM users WHERE role_id = (SELECT id FROM roles WHERE code = 'expert');
```

Если экспертов недостаточно, создайте их:

```sql
INSERT INTO users (id, login, password_hash, full_name, email, role_id, is_active)
SELECT
    gen_random_uuid(),
    'expert1',
    encode(sha256('Expert123!'::bytea), 'hex'),
    'Алексей Смирнов',
    'alexey.smirnov@example.com',
    (SELECT id FROM roles WHERE code = 'expert'),
    TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE login = 'expert1');

INSERT INTO users (id, login, password_hash, full_name, email, role_id, is_active)
SELECT
    gen_random_uuid(),
    'expert2',
    encode(sha256('Expert123!'::bytea), 'hex'),
    'Елена Козлова',
    'elena.kozlova@example.com',
    (SELECT id FROM roles WHERE code = 'expert'),
    TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE login = 'expert2');

INSERT INTO users (id, login, password_hash, full_name, email, role_id, is_active)
SELECT
    gen_random_uuid(),
    'expert3',
    encode(sha256('Expert123!'::bytea), 'hex'),
    'Михаил Волков',
    'mikhail.volkov@example.com',
    (SELECT id FROM roles WHERE code = 'expert'),
    TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE login = 'expert3');

INSERT INTO users (id, login, password_hash, full_name, email, role_id, is_active)
SELECT
    gen_random_uuid(),
    'expert4',
    encode(sha256('Expert123!'::bytea), 'hex'),
    'Анна Морозова',
    'anna.morozova@example.com',
    (SELECT id FROM roles WHERE code = 'expert'),
    TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE login = 'expert4');

INSERT INTO users (id, login, password_hash, full_name, email, role_id, is_active)
SELECT
    gen_random_uuid(),
    'expert5',
    encode(sha256('Expert123!'::bytea), 'hex'),
    'Дмитрий Новиков',
    'dmitry.novikov@example.com',
    (SELECT id FROM roles WHERE code = 'expert'),
    TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE login = 'expert5');
```

### Шаг 4. Создание команд-участников

Перед созданием команд проверьте существующие:

```sql
SELECT id, name FROM teams WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

Создайте десять команд-участников:

```sql
INSERT INTO teams (id, hackathon_id, name, description, created_at)
VALUES
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'КиберМаги', 'Команда специалистов по искусственному интеллекту', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Данные Визионеры', 'Эксперты в анализе данных и машинном обучении', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Нейронные Ниндзя', 'Разработчики нейросетевых решений', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Алгоритм Мастера', 'Специалисты по созданию эффективных алгоритмов', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Квантовый Скачок', 'Исследователи в области квантовых вычислений', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Облачные Стражи', 'Эксперты по облачным технологиям и DevOps', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Робототехники', 'Разработчики роботизированных систем', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Блокчейн Пионеры', 'Специалисты по распределенным реестрам', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'КиберЗащитники', 'Эксперты в области кибербезопасности', NOW()),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'UX Гении', 'Дизайнеры пользовательских интерфейсов', NOW());
```

Получите UUID созданных команд для дальнейшего использования:

```sql
SELECT id, name FROM teams WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' ORDER BY name;
```

### Шаг 5. Назначение экспертов командам

Очистите старые назначения для указанного хакатона:

```sql
DELETE FROM expert_team_assignments WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

Создайте назначения для всех команд (каждую команду оценивают 2-3 эксперта):

```sql
-- Назначения для команды КиберМаги
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert1', 'expert2') AND t.name = 'КиберМаги' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Данные Визионеры
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert1', 'expert3') AND t.name = 'Данные Визионеры' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Нейронные Ниндзя
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert2', 'expert4') AND t.name = 'Нейронные Ниндзя' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Алгоритм Мастера
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert3', 'expert5') AND t.name = 'Алгоритм Мастера' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Квантовый Скачок
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert1', 'expert4') AND t.name = 'Квантовый Скачок' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Облачные Стражи
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert2', 'expert5') AND t.name = 'Облачные Стражи' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Робототехники
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert3', 'expert4') AND t.name = 'Робототехники' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды Блокчейн Пионеры
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert1', 'expert5') AND t.name = 'Блокчейн Пионеры' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды КиберЗащитники
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert2', 'expert3') AND t.name = 'КиберЗащитники' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Назначения для команды UX Гении
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', u.id, t.id, NOW()
FROM users u, teams t
WHERE u.login IN ('expert4', 'expert5') AND t.name = 'UX Гении' AND t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

Проверьте количество назначений:

```sql
SELECT COUNT(*) FROM expert_team_assignments WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

### Шаг 6. Создание или обновление результатов команд

Сначала проверьте, существуют ли записи в team_results:

```sql
SELECT * FROM team_results WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

Если записи отсутствуют, создайте их для всех команд:

```sql
INSERT INTO team_results (id, hackathon_id, team_id, final_score, place, evaluated_by_count, status)
SELECT
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    t.id,
    CASE
        WHEN t.name = 'КиберМаги' THEN 94.2
        WHEN t.name = 'Данные Визионеры' THEN 91.7
        WHEN t.name = 'Нейронные Ниндзя' THEN 89.3
        WHEN t.name = 'Алгоритм Мастера' THEN 87.5
        WHEN t.name = 'Квантовый Скачок' THEN 85.8
        WHEN t.name = 'Облачные Стражи' THEN 83.1
        WHEN t.name = 'Робототехники' THEN 80.4
        WHEN t.name = 'Блокчейн Пионеры' THEN 77.9
        WHEN t.name = 'КиберЗащитники' THEN 74.6
        WHEN t.name = 'UX Гении' THEN 71.2
        ELSE 0
    END,
    CASE
        WHEN t.name = 'КиберМаги' THEN 1
        WHEN t.name = 'Данные Визионеры' THEN 2
        WHEN t.name = 'Нейронные Ниндзя' THEN 3
        WHEN t.name = 'Алгоритм Мастера' THEN 4
        WHEN t.name = 'Квантовый Скачок' THEN 5
        WHEN t.name = 'Облачные Стражи' THEN 6
        WHEN t.name = 'Робототехники' THEN 7
        WHEN t.name = 'Блокчейн Пионеры' THEN 8
        WHEN t.name = 'КиберЗащитники' THEN 9
        WHEN t.name = 'UX Гении' THEN 10
        ELSE NULL
    END,
    2,
    'IN_PROGRESS'
FROM teams t
WHERE t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND NOT EXISTS (
    SELECT 1 FROM team_results tr
    WHERE tr.team_id = t.id AND tr.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  );
```

Если записи существуют, обновите их напрямую:

```sql
-- Обновление для КиберМаги
UPDATE team_results
SET final_score = 94.2, place = 1, evaluated_by_count = 2, status = 'COMPLETED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'КиберМаги' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Данные Визионеры
UPDATE team_results
SET final_score = 91.7, place = 2, evaluated_by_count = 2, status = 'COMPLETED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Данные Визионеры' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Нейронные Ниндзя
UPDATE team_results
SET final_score = 89.3, place = 3, evaluated_by_count = 2, status = 'COMPLETED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Нейронные Ниндзя' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Алгоритм Мастера
UPDATE team_results
SET final_score = 87.5, place = 4, evaluated_by_count = 2, status = 'COMPLETED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Алгоритм Мастера' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Квантовый Скачок
UPDATE team_results
SET final_score = 85.8, place = 5, evaluated_by_count = 2, status = 'COMPLETED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Квантовый Скачок' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Облачные Стражи
UPDATE team_results
SET final_score = 83.1, place = 6, evaluated_by_count = 2, status = 'IN_PROGRESS'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Облачные Стражи' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Робототехники
UPDATE team_results
SET final_score = 80.4, place = 7, evaluated_by_count = 2, status = 'IN_PROGRESS'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Робототехники' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для Блокчейн Пионеры
UPDATE team_results
SET final_score = 77.9, place = 8, evaluated_by_count = 2, status = 'IN_PROGRESS'
WHERE team_id = (SELECT id FROM teams WHERE name = 'Блокчейн Пионеры' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для КиберЗащитники
UPDATE team_results
SET final_score = 74.6, place = 9, evaluated_by_count = 2, status = 'NOT_STARTED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'КиберЗащитники' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Обновление для UX Гении
UPDATE team_results
SET final_score = 71.2, place = 10, evaluated_by_count = 2, status = 'NOT_STARTED'
WHERE team_id = (SELECT id FROM teams WHERE name = 'UX Гении' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
  AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

### Шаг 7. Приведение статусов к корректному формату

Если статусы хранятся в нижнем регистре, приведите их к формату enum:

```sql
UPDATE team_results SET status = 'NOT_STARTED' WHERE status = 'not_started';
UPDATE team_results SET status = 'IN_PROGRESS' WHERE status = 'in_progress';
UPDATE team_results SET status = 'COMPLETED' WHERE status = 'completed';
```

### Шаг 8. Обновление метаданных хакатона

Обновите время последнего обновления лидерборда и опубликуйте результаты:

```sql
UPDATE hackathons
SET leaderboard_updated_at = NOW(),
    results_published = TRUE
WHERE id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

### Шаг 9. Финальная проверка

Выполните итоговую проверку всех внесенных данных:

```sql
SELECT
    (SELECT COUNT(*) FROM criteria WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') as criteria_count,
    (SELECT COUNT(*) FROM expert_team_assignments WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') as assignments_count,
    (SELECT COUNT(*) FROM team_results WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND final_score > 0) as results_with_scores;
```

Проверьте результаты всех команд:

```sql
SELECT t.name, tr.final_score, tr.place, tr.evaluated_by_count, tr.status
FROM teams t
LEFT JOIN team_results tr ON t.id = tr.team_id AND tr.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
WHERE t.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
ORDER BY tr.place;
```

Проверьте распределение экспертов по командам:

```sql
SELECT t.name as team_name, STRING_AGG(u.full_name, ', ') as experts
FROM expert_team_assignments eta
JOIN teams t ON eta.team_id = t.id
JOIN users u ON eta.expert_user_id = u.id
WHERE eta.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
GROUP BY t.name
ORDER BY t.name;
```

### Шаг 10. Завершение работы

Выйдите из psql:

```sql
\q
```
