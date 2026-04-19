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

### Шаг 1

```bash
-- Подключаемся к базе
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db

-- 1. Создаем команды для CyberDef хакатона
INSERT INTO teams (id, hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
VALUES
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'ZeroDay Hunters', 'Иван Петров', 'zeroday@example.com', '+79006667788', 'Threat Intelligence System', 'AI-powered cyber threat prediction platform'),
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Crypto Guardians', 'Елена Чен', 'crypto@example.com', '+79007778899', 'Post-Quantum Cryptography', 'Quantum-resistant encryption library'),
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Privacy Defenders', 'Ахмед Хасанов', 'privacy@example.com', '+79008889900', 'Anonymous Credentials', 'Zero-knowledge proof verification system');

-- 2. Проверяем созданные команды
SELECT id, name FROM teams WHERE hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- 3. Создаем назначения экспертов для команд
-- Получаем ID экспертов
SELECT id, login FROM users WHERE login IN ('expert4', 'expert5');

-- Создаем назначения (используйте реальные ID из предыдущего запроса)
-- expert4 (Анна Морозова) проверяет ZeroDay Hunters
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert4'),
    (SELECT id FROM teams WHERE name = 'ZeroDay Hunters' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    NOW();

-- expert4 и expert5 проверяют Crypto Guardians
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert4'),
    (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    NOW();

INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert5'),
    (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    NOW();

-- expert5 проверяет Privacy Defenders
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
SELECT
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert5'),
    (SELECT id FROM teams WHERE name = 'Privacy Defenders' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    NOW();

-- 4. Проверяем назначения
SELECT COUNT(*) FROM expert_team_assignments WHERE hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- 5. Создаем оценки (evaluations) для команд
-- Оценка для ZeroDay Hunters от expert4
INSERT INTO evaluations (id, hackathon_id, expert_user_id, team_id, status, overall_comment, submitted_at)
VALUES (
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert4'),
    (SELECT id FROM teams WHERE name = 'ZeroDay Hunters' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    'submitted',
    'Excellent threat detection capabilities! Very innovative approach.',
    NOW()
);

-- Оценка для Crypto Guardians от expert4
INSERT INTO evaluations (id, hackathon_id, expert_user_id, team_id, status, overall_comment, submitted_at)
VALUES (
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert4'),
    (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    'submitted',
    'Strong cryptographic implementation, good performance.',
    NOW()
);

-- Оценка для Crypto Guardians от expert5
INSERT INTO evaluations (id, hackathon_id, expert_user_id, team_id, status, overall_comment, submitted_at)
VALUES (
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert5'),
    (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    'submitted',
    'Excellent quantum-resistant algorithms, well documented.',
    NOW()
);

-- Оценка для Privacy Defenders от expert5
INSERT INTO evaluations (id, hackathon_id, expert_user_id, team_id, status, overall_comment, submitted_at)
VALUES (
    gen_random_uuid(),
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM users WHERE login = 'expert5'),
    (SELECT id FROM teams WHERE name = 'Privacy Defenders' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
    'submitted',
    'Innovative zero-knowledge proof system, great potential.',
    NOW()
);

-- 6. Добавляем баллы по критериям для оценок
-- Для ZeroDay Hunters (критерии: эффективность защиты, качество кода, удобство использования)
INSERT INTO evaluation_items (evaluation_id, criterion_id, raw_score, comment)
SELECT
    e.id,
    c.id,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 9.5
        WHEN 'Качество кода' THEN 8.5
        WHEN 'Удобство использования' THEN 9.0
    END,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 'Excellent threat detection algorithms'
        WHEN 'Качество кода' THEN 'Clean code, good structure'
        WHEN 'Удобство использования' THEN 'Easy to deploy and configure'
    END
FROM evaluations e
CROSS JOIN criteria c
WHERE e.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'
  AND e.expert_user_id = (SELECT id FROM users WHERE login = 'expert4')
  AND e.team_id = (SELECT id FROM teams WHERE name = 'ZeroDay Hunters' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44')
  AND c.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- Для Crypto Guardians от expert4
INSERT INTO evaluation_items (evaluation_id, criterion_id, raw_score, comment)
SELECT
    e.id,
    c.id,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 8.0
        WHEN 'Качество кода' THEN 9.0
        WHEN 'Удобство использования' THEN 7.5
    END,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 'Good protection level'
        WHEN 'Качество кода' THEN 'Well-structured code'
        WHEN 'Удобство использования' THEN 'Documentation could be improved'
    END
FROM evaluations e
CROSS JOIN criteria c
WHERE e.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'
  AND e.expert_user_id = (SELECT id FROM users WHERE login = 'expert4')
  AND e.team_id = (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44')
  AND c.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- Для Crypto Guardians от expert5
INSERT INTO evaluation_items (evaluation_id, criterion_id, raw_score, comment)
SELECT
    e.id,
    c.id,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 8.5
        WHEN 'Качество кода' THEN 9.5
        WHEN 'Удобство использования' THEN 8.0
    END,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 'Strong encryption'
        WHEN 'Качество кода' THEN 'Excellent implementation'
        WHEN 'Удобство использования' THEN 'Good API design'
    END
FROM evaluations e
CROSS JOIN criteria c
WHERE e.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'
  AND e.expert_user_id = (SELECT id FROM users WHERE login = 'expert5')
  AND e.team_id = (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44')
  AND c.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- Для Privacy Defenders от expert5
INSERT INTO evaluation_items (evaluation_id, criterion_id, raw_score, comment)
SELECT
    e.id,
    c.id,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 9.0
        WHEN 'Качество кода' THEN 8.0
        WHEN 'Удобство использования' THEN 9.5
    END,
    CASE c.title
        WHEN 'Эффективность защиты' THEN 'Great privacy protection'
        WHEN 'Качество кода' THEN 'Good implementation'
        WHEN 'Удобство использования' THEN 'Very user-friendly'
    END
FROM evaluations e
CROSS JOIN criteria c
WHERE e.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'
  AND e.expert_user_id = (SELECT id FROM users WHERE login = 'expert5')
  AND e.team_id = (SELECT id FROM teams WHERE name = 'Privacy Defenders' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44')
  AND c.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- 7. Создаем результаты команд (leaderboard)
INSERT INTO team_results (id, hackathon_id, team_id, final_score, place, evaluated_by_count, status, recalculated_at)
VALUES
    (
        gen_random_uuid(),
        'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
        (SELECT id FROM teams WHERE name = 'ZeroDay Hunters' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
        90.0,
        1,
        1,
        'completed'::result_status,
        NOW()
    ),
    (
        gen_random_uuid(),
        'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
        (SELECT id FROM teams WHERE name = 'Crypto Guardians' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
        85.5,
        2,
        2,
        'completed'::result_status,
        NOW()
    ),
    (
        gen_random_uuid(),
        'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
        (SELECT id FROM teams WHERE name = 'Privacy Defenders' AND hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'),
        88.0,
        3,
        1,
        'completed'::result_status,
        NOW()
    );

-- 8. Обновляем метаданные хакатона
UPDATE hackathons
SET leaderboard_updated_at = NOW(),
    results_published = TRUE
WHERE id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- 9. Финальная проверка
SELECT
    'CyberDef Teams' as metric,
    COUNT(*) as value
FROM teams
WHERE hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'

UNION ALL

SELECT
    'Expert Assignments',
    COUNT(*)
FROM expert_team_assignments
WHERE hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'

UNION ALL

SELECT
    'Evaluations',
    COUNT(*)
FROM evaluations
WHERE hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'

UNION ALL

SELECT
    'Team Results',
    COUNT(*)
FROM team_results
WHERE hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- 10. Просмотр результатов команд
SELECT t.name, tr.final_score, tr.place, tr.evaluated_by_count, tr.status
FROM team_results tr
JOIN teams t ON tr.team_id = t.id
WHERE tr.hackathon_id = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'
ORDER BY tr.place;

-- Выход
\q
```

После успешного подключения вы увидите приглашение командной строки psql.

### Шаг 2

```sql
-- Подключаемся к базе
sudo docker-compose exec postgres psql -U hackathon_admin -d hackathon_db

-- 1. Проверяем текущие значения ENUM
SELECT enumlabel FROM pg_enum WHERE enumtypid = 'result_status'::regtype ORDER BY enumsortorder;

-- 2. Если enum имеет значения в нижнем регистре, пересоздаем его
-- Сначала временно меняем тип колонки на text
ALTER TABLE team_results ALTER COLUMN status TYPE text;

-- Удаляем старый enum
DROP TYPE IF EXISTS result_status CASCADE;

-- Создаем новый enum с правильными значениями (UPPERCASE)
CREATE TYPE result_status AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED');

-- Обновляем данные в таблице
UPDATE team_results SET status = 'NOT_STARTED' WHERE status = 'not_started' OR status = 'NOT_STARTED';
UPDATE team_results SET status = 'IN_PROGRESS' WHERE status = 'in_progress' OR status = 'IN_PROGRESS';
UPDATE team_results SET status = 'COMPLETED' WHERE status = 'completed' OR status = 'COMPLETED';

-- Возвращаем тип колонке
ALTER TABLE team_results ALTER COLUMN status TYPE result_status USING status::result_status;

-- 3. Проверяем результат
SELECT DISTINCT status FROM team_results;

-- 4. Исправляем deadline_kind enum
-- Проверяем текущие значения
SELECT enumlabel FROM pg_enum WHERE enumtypid = 'deadline_kind'::regtype ORDER BY enumsortorder;

-- Временно меняем тип колонки
ALTER TABLE deadlines ALTER COLUMN kind TYPE text;

-- Удаляем старый enum
DROP TYPE IF EXISTS deadline_kind CASCADE;

-- Создаем новый enum с правильными значениями (UPPERCASE)
CREATE TYPE deadline_kind AS ENUM ('REGISTRATION', 'DEVELOPMENT', 'PITCH', 'EVALUATION', 'CUSTOM');

-- Обновляем данные
UPDATE deadlines SET kind = 'REGISTRATION' WHERE kind = 'registration' OR kind = 'REGISTRATION';
UPDATE deadlines SET kind = 'DEVELOPMENT' WHERE kind = 'development' OR kind = 'DEVELOPMENT';
UPDATE deadlines SET kind = 'PITCH' WHERE kind = 'pitch' OR kind = 'PITCH';
UPDATE deadlines SET kind = 'EVALUATION' WHERE kind = 'evaluation' OR kind = 'EVALUATION';
UPDATE deadlines SET kind = 'CUSTOM' WHERE kind = 'custom' OR kind = 'CUSTOM';

-- Возвращаем тип колонке
ALTER TABLE deadlines ALTER COLUMN kind TYPE deadline_kind USING kind::deadline_kind;

-- 5. Проверяем результаты
SELECT
    'result_status enum' as enum_name,
    string_agg(enumlabel, ', ') as values
FROM pg_enum
WHERE enumtypid = 'result_status'::regtype
GROUP BY enumtypid;

SELECT
    'deadline_kind enum' as enum_name,
    string_agg(enumlabel, ', ') as values
FROM pg_enum
WHERE enumtypid = 'deadline_kind'::regtype
GROUP BY enumtypid;

-- 6. Проверяем данные в таблицах
SELECT COUNT(*) FROM team_results WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
SELECT COUNT(*) FROM deadlines WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- 7. Создаем дедлайны для AI Challenge если их нет
INSERT INTO deadlines (id, hackathon_id, kind, title, description, deadline_at, notify_before_minutes)
SELECT
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'REGISTRATION',
    'Registration Deadline',
    'Team registration closes',
    NOW() + INTERVAL '1 day',
    60
WHERE NOT EXISTS (
    SELECT 1 FROM deadlines WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
);

INSERT INTO deadlines (id, hackathon_id, kind, title, description, deadline_at, notify_before_minutes)
SELECT
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'DEVELOPMENT',
    'Development Phase',
    'Code development period ends',
    NOW() + INTERVAL '3 days',
    120
WHERE NOT EXISTS (
    SELECT 1 FROM deadlines WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND kind = 'DEVELOPMENT'
);

INSERT INTO deadlines (id, hackathon_id, kind, title, description, deadline_at, notify_before_minutes)
SELECT
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'PITCH',
    'Pitch Submission',
    'Project presentation submission deadline',
    NOW() + INTERVAL '5 days',
    180
WHERE NOT EXISTS (
    SELECT 1 FROM deadlines WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND kind = 'PITCH'
);

-- 8. Обновляем статусы team_results для AI Challenge
UPDATE team_results
SET status = 'COMPLETED'::result_status
WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
AND place <= 3;

UPDATE team_results
SET status = 'IN_PROGRESS'::result_status
WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
AND place BETWEEN 4 AND 6;

UPDATE team_results
SET status = 'NOT_STARTED'::result_status
WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
AND place > 6;

-- 9. Проверяем финальные результаты
SELECT t.name, tr.final_score, tr.place, tr.status::text
FROM team_results tr
JOIN teams t ON tr.team_id = t.id
WHERE tr.hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
ORDER BY tr.place;

-- 10. Обновляем метаданные хакатонов
UPDATE hackathons
SET leaderboard_updated_at = NOW(),
    results_published = TRUE
WHERE id IN ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44');

-- 11. Проверяем все ENUM значения
SELECT
    'hackathon_status' as enum_name,
    string_agg(enumlabel, ', ') as values
FROM pg_enum
WHERE enumtypid = 'hackathon_status'::regtype
UNION ALL
SELECT
    'result_status',
    string_agg(enumlabel, ', ')
FROM pg_enum
WHERE enumtypid = 'result_status'::regtype
UNION ALL
SELECT
    'deadline_kind',
    string_agg(enumlabel, ', ')
FROM pg_enum
WHERE enumtypid = 'deadline_kind'::regtype
UNION ALL
SELECT
    'evaluation_status',
    string_agg(enumlabel, ', ')
FROM pg_enum
WHERE enumtypid = 'evaluation_status'::regtype;

-- Выход
\q
```
