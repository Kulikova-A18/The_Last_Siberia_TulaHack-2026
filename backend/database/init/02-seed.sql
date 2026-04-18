-- =========================================================
-- SEED DATA FOR HACKATHON DATABASE (FIXED VERSION WITH RUSSIAN NAMES)
-- =========================================================

-- Enable pgcrypto for SHA256 function
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- ROLES
-- =========================================================
INSERT INTO roles (code, name) VALUES
('admin', 'Administrator'),
('expert', 'Expert'),
('team', 'Team')
ON CONFLICT (code) DO NOTHING;

-- =========================================================
-- PERMISSIONS
-- =========================================================
INSERT INTO permissions (code, name, description) VALUES
('users.read', 'View users', 'Read user list'),
('users.create', 'Create users', 'Create user accounts'),
('users.update', 'Edit users', 'Edit profiles and statuses'),
('users.delete', 'Delete users', 'Delete user accounts'),
('teams.read', 'View teams', 'Read team list'),
('teams.create', 'Create teams', 'Add new teams'),
('teams.update', 'Edit teams', 'Edit team cards'),
('teams.delete', 'Delete teams', 'Delete teams'),
('criteria.read', 'View criteria', 'Read evaluation criteria'),
('criteria.manage', 'Manage criteria', 'Create/edit/delete criteria'),
('assignments.read', 'View assignments', 'Read expert assignments'),
('assignments.manage', 'Manage assignments', 'Assign experts to teams'),
('evaluations.read', 'View evaluations', 'View all evaluations'),
('evaluations.submit', 'Submit evaluations', 'Submit evaluation by expert'),
('evaluations.reopen', 'Reopen evaluation', 'Reopen evaluation by admin'),
('results.read', 'View results', 'View leaderboard and results'),
('results.publish', 'Publish results', 'Publish leaderboard'),
('results.freeze', 'Freeze results', 'Lock result changes'),
('deadlines.read', 'View deadlines', 'Read deadlines'),
('deadlines.manage', 'Manage deadlines', 'Create and edit deadlines'),
('audit.read', 'View audit', 'View action log')
ON CONFLICT (code) DO NOTHING;

-- =========================================================
-- ROLE PERMISSIONS
-- =========================================================
DO $$
DECLARE
    admin_role_id UUID;
    expert_role_id UUID;
    team_role_id UUID;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE code = 'admin';
    SELECT id INTO expert_role_id FROM roles WHERE code = 'expert';
    SELECT id INTO team_role_id FROM roles WHERE code = 'team';
    
    -- Admin gets all permissions
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT admin_role_id, id FROM permissions
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    
    -- Expert permissions
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT expert_role_id, id FROM permissions 
    WHERE code IN (
        'teams.read', 'criteria.read', 'evaluations.submit', 
        'results.read', 'deadlines.read'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    
    -- Team permissions
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT team_role_id, id FROM permissions 
    WHERE code IN ('teams.read', 'results.read', 'deadlines.read')
    ON CONFLICT (role_id, permission_id) DO NOTHING;
END $$;

-- =========================================================
-- USERS
-- =========================================================
DO $$
DECLARE
    admin_role_id UUID;
    expert_role_id UUID;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE code = 'admin';
    SELECT id INTO expert_role_id FROM roles WHERE code = 'expert';
    
    -- Admin
    INSERT INTO users (id, login, password_hash, full_name, email, role_id, is_active)
    VALUES (
        '11111111-1111-1111-1111-111111111111',
        'admin',
        encode(sha256('Admin123!'::bytea), 'hex'),
        'Главный Администратор',
        'admin@hackathon.com',
        admin_role_id,
        TRUE
    ) ON CONFLICT (login) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        is_active = TRUE;
    
    -- Experts with Russian names
    INSERT INTO users (id, login, password_hash, full_name, email, phone, role_id, is_active)
    VALUES 
        ('22222222-2222-2222-2222-222222222221', 'expert1', encode(sha256('Expert123!'::bytea), 'hex'), 'Алексей Смирнов', 'alexey.smirnov@example.com', '+79001234567', expert_role_id, TRUE),
        ('22222222-2222-2222-2222-222222222222', 'expert2', encode(sha256('Expert123!'::bytea), 'hex'), 'Елена Козлова', 'elena.kozlova@example.com', '+79002345678', expert_role_id, TRUE),
        ('22222222-2222-2222-2222-222222222223', 'expert3', encode(sha256('Expert123!'::bytea), 'hex'), 'Михаил Волков', 'mikhail.volkov@example.com', '+79003456789', expert_role_id, TRUE),
        ('22222222-2222-2222-2222-222222222224', 'expert4', encode(sha256('Expert123!'::bytea), 'hex'), 'Анна Морозова', 'anna.morozova@example.com', '+79004567890', expert_role_id, TRUE),
        ('22222222-2222-2222-2222-222222222225', 'expert5', encode(sha256('Expert123!'::bytea), 'hex'), 'Дмитрий Новиков', 'dmitry.novikov@example.com', '+79005678901', expert_role_id, TRUE)
    ON CONFLICT (login) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        is_active = TRUE;
END $$;

-- =========================================================
-- HACKATHONS
-- =========================================================
INSERT INTO hackathons (id, title, description, start_at, end_at, status)
VALUES 
    (
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'HackRank AI Challenge 2024',
        'Ежегодный хакатон, посвященный решениям в области искусственного интеллекта и машинного обучения.',
        NOW(),
        NOW() + INTERVAL '7 days',
        'ACTIVE'
    ),
    (
        'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
        'Web3 Frontier Хакатон',
        'Создание децентрализованных приложений. Фокус на DeFi, NFT и DAO.',
        NOW() + INTERVAL '14 days',
        NOW() + INTERVAL '21 days',
        'DRAFT'
    ),
    (
        'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
        'Эко Инновационный Марафон',
        'Технологии устойчивого развития для борьбы с изменением климата.',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '23 days',
        'FINISHED'
    ),
    (
        'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
        'КиберЗащита 2024',
        '24-часовой спринт по созданию инновационных инструментов безопасности.',
        NOW() - INTERVAL '2 days',
        NOW() + INTERVAL '5 days',
        'ACTIVE'
    )
ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    start_at = EXCLUDED.start_at,
    end_at = EXCLUDED.end_at;

-- =========================================================
-- CRITERIA FOR AI CHALLENGE (Russian)
-- =========================================================
INSERT INTO criteria (id, hackathon_id, title, description, max_score, weight_percent, sort_order, is_active)
VALUES
    ('c1111111-1111-1111-1111-111111111111', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Инновационность', 'Оригинальность и креативность решения', 10.0, 25.0, 1, TRUE),
    ('c1111111-1111-1111-1111-111111111112', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Техническая сложность', 'Сложность технологического стека и реализации', 10.0, 25.0, 2, TRUE),
    ('c1111111-1111-1111-1111-111111111113', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Бизнес-ценность', 'Рыночный потенциал и практическая применимость', 10.0, 20.0, 3, TRUE),
    ('c1111111-1111-1111-1111-111111111114', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Презентация', 'Качество демо и защиты проекта', 10.0, 15.0, 4, TRUE),
    ('c1111111-1111-1111-1111-111111111115', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Командная работа', 'Взаимодействие и динамика команды', 5.0, 15.0, 5, TRUE)
ON CONFLICT (hackathon_id, title) DO UPDATE SET
    max_score = EXCLUDED.max_score,
    weight_percent = EXCLUDED.weight_percent,
    is_active = TRUE;

-- =========================================================
-- CRITERIA FOR CYBERDEF (Russian)
-- =========================================================
INSERT INTO criteria (id, hackathon_id, title, description, max_score, weight_percent, sort_order, is_active)
VALUES
    ('c2222222-2222-2222-2222-222222222221', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Эффективность защиты', 'Действенность против угроз', 10.0, 40.0, 1, TRUE),
    ('c2222222-2222-2222-2222-222222222222', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Качество кода', 'Практики безопасного программирования', 10.0, 30.0, 2, TRUE),
    ('c2222222-2222-2222-2222-222222222223', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Удобство использования', 'Простота развертывания', 10.0, 30.0, 3, TRUE)
ON CONFLICT (hackathon_id, title) DO UPDATE SET
    max_score = EXCLUDED.max_score,
    weight_percent = EXCLUDED.weight_percent,
    is_active = TRUE;

-- =========================================================
-- TEAMS FOR AI CHALLENGE (Russian names)
-- =========================================================
INSERT INTO teams (id, hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
VALUES
    ('t1111111-1111-1111-1111-111111111111', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'КиберМаги', 'Алексей Иванов', 'alexey.i@example.com', '+79001112233', 'AI-помощник для ревью кода', 'Интеллектуальный инструмент для проверки кода'),
    ('t1111111-1111-1111-1111-111111111112', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Данные Визионеры', 'Мария Соколова', 'maria.s@example.com', '+79002223344', 'Система обнаружения мошенничества', 'ML система для выявления мошенничества в реальном времени'),
    ('t1111111-1111-1111-1111-111111111113', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Нейронные Ниндзя', 'Дмитрий Ким', 'dmitry.k@example.com', '+79003334455', 'Ассистент медицинской диагностики', 'ИИ для диагностики в медицине'),
    ('t1111111-1111-1111-1111-111111111114', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Алгоритм Мастера', 'Сергей Петров', 'sergey.p@example.com', '+79004445566', 'Оптимизатор цепочек поставок', 'Алгоритмы для оптимизации логистики'),
    ('t1111111-1111-1111-1111-111111111115', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Квантовый Скачок', 'Екатерина Лебедева', 'ekaterina.l@example.com', '+79005556677', 'Квантовый симулятор', 'Симуляция квантовых вычислений'),
    ('t1111111-1111-1111-1111-111111111116', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Облачные Стражи', 'Павел Морозов', 'pavel.m@example.com', '+79006667788', 'Платформа мониторинга облака', 'Система мониторинга облачных сервисов'),
    ('t1111111-1111-1111-1111-111111111117', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Робототехники', 'Ольга Степанова', 'olga.s@example.com', '+79007778899', 'Алгоритм навигации роботов', 'Интеллектуальная навигация для роботов'),
    ('t1111111-1111-1111-1111-111111111118', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Блокчейн Пионеры', 'Андрей Федоров', 'andrey.f@example.com', '+79008889900', 'Децентрализованное хранилище', 'Блокчейн платформа для хранения данных'),
    ('t1111111-1111-1111-1111-111111111119', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'КиберЗащитники', 'Татьяна Орлова', 'tatiana.o@example.com', '+79009990011', 'Анализатор сетевого трафика', 'Обнаружение аномалий в сети'),
    ('t1111111-1111-1111-1111-111111111110', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'UX Гении', 'Владимир Кузнецов', 'vladimir.k@example.com', '+79001001122', 'Персонализатор интерфейсов', 'Адаптивный пользовательский интерфейс')
ON CONFLICT (hackathon_id, name) DO UPDATE SET
    project_title = EXCLUDED.project_title,
    description = EXCLUDED.description;

-- =========================================================
-- TEAMS FOR CYBERDEF (Russian names)
-- =========================================================
INSERT INTO teams (id, hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
VALUES
    ('t2222222-2222-2222-2222-222222222221', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'ZeroDay Исследователи', 'Иван Петров', 'ivan.p@example.com', '+79006667788', 'Автоматическая разведка угроз', 'ИИ-прогнозирование киберугроз'),
    ('t2222222-2222-2222-2222-222222222222', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'КриптоЗащитники', 'Елена Чен', 'elena.chen@example.com', '+79007778899', 'Постквантовое шифрование', 'Библиотека квантово-устойчивого шифрования'),
    ('t2222222-2222-2222-2222-222222222223', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Защитники Приватности', 'Ахмед Хасанов', 'ahmed.h@example.com', '+79008889900', 'Система анонимных учетных данных', 'Верификация с нулевым разглашением')
ON CONFLICT (hackathon_id, name) DO UPDATE SET
    project_title = EXCLUDED.project_title,
    description = EXCLUDED.description;

-- =========================================================
-- TEAM MEMBERS (Russian names)
-- =========================================================
INSERT INTO team_members (id, team_id, full_name, email, phone, organization, is_captain)
VALUES
    -- КиберМаги
    ('m1111111-1111-1111-1111-111111111111', 't1111111-1111-1111-1111-111111111111', 'Алексей Иванов', 'alexey.i@example.com', '+79001112233', 'ТехКорп', TRUE),
    ('m1111111-1111-1111-1111-111111111112', 't1111111-1111-1111-1111-111111111111', 'Нина Патель', 'nina.p@example.com', '+79001112234', 'ТехКорп', FALSE),
    ('m1111111-1111-1111-1111-111111111113', 't1111111-1111-1111-1111-111111111111', 'Том Уилсон', 'tom.w@example.com', '+79001112235', 'Фриланс', FALSE),
    -- Данные Визионеры
    ('m1111111-1111-1111-1111-111111111114', 't1111111-1111-1111-1111-111111111112', 'Мария Соколова', 'maria.s@example.com', '+79002223344', 'ДанныеКо', TRUE),
    ('m1111111-1111-1111-1111-111111111115', 't1111111-1111-1111-1111-111111111112', 'Лукас Сильва', 'lucas.s@example.com', '+79002223345', 'ДанныеКо', FALSE),
    ('m1111111-1111-1111-1111-111111111116', 't1111111-1111-1111-1111-111111111112', 'Анна Чжан', 'anna.z@example.com', '+79002223346', 'ИИ Лабс', FALSE),
    -- Нейронные Ниндзя
    ('m1111111-1111-1111-1111-111111111117', 't1111111-1111-1111-1111-111111111113', 'Дмитрий Ким', 'dmitry.k@example.com', '+79003334455', 'ХелсТех', TRUE),
    ('m1111111-1111-1111-1111-111111111118', 't1111111-1111-1111-1111-111111111113', 'Сара Чен', 'sarah.chen@example.com', '+79003334456', 'ХелсТех', FALSE),
    -- Алгоритм Мастера
    ('m1111111-1111-1111-1111-111111111119', 't1111111-1111-1111-1111-111111111114', 'Сергей Петров', 'sergey.p@example.com', '+79004445566', 'ЛогистПро', TRUE),
    ('m1111111-1111-1111-1111-111111111120', 't1111111-1111-1111-1111-111111111114', 'Игорь Смирнов', 'igor.s@example.com', '+79004445567', 'ЛогистПро', FALSE),
    -- Квантовый Скачок
    ('m1111111-1111-1111-1111-111111111121', 't1111111-1111-1111-1111-111111111115', 'Екатерина Лебедева', 'ekaterina.l@example.com', '+79005556677', 'КвантЛаб', TRUE),
    ('m1111111-1111-1111-1111-111111111122', 't1111111-1111-1111-1111-111111111115', 'Михаил Козлов', 'mikhail.k@example.com', '+79005556678', 'КвантЛаб', FALSE),
    -- Облачные Стражи
    ('m1111111-1111-1111-1111-111111111123', 't1111111-1111-1111-1111-111111111116', 'Павел Морозов', 'pavel.m@example.com', '+79006667788', 'ОблакоТех', TRUE),
    ('m1111111-1111-1111-1111-111111111124', 't1111111-1111-1111-1111-111111111116', 'Анна Ветрова', 'anna.v@example.com', '+79006667789', 'ОблакоТех', FALSE),
    -- Робототехники
    ('m1111111-1111-1111-1111-111111111125', 't1111111-1111-1111-1111-111111111117', 'Ольга Степанова', 'olga.s@example.com', '+79007778899', 'РобоТех', TRUE),
    ('m1111111-1111-1111-1111-111111111126', 't1111111-1111-1111-1111-111111111117', 'Денис Федоров', 'denis.f@example.com', '+79007778900', 'РобоТех', FALSE),
    -- Блокчейн Пионеры
    ('m1111111-1111-1111-1111-111111111127', 't1111111-1111-1111-1111-111111111118', 'Андрей Федоров', 'andrey.f@example.com', '+79008889900', 'БлокИнно', TRUE),
    ('m1111111-1111-1111-1111-111111111128', 't1111111-1111-1111-1111-111111111118', 'Кристина Павлова', 'kristina.p@example.com', '+79008889901', 'БлокИнно', FALSE),
    -- КиберЗащитники
    ('m1111111-1111-1111-1111-111111111129', 't1111111-1111-1111-1111-111111111119', 'Татьяна Орлова', 'tatiana.o@example.com', '+79009990011', 'СекурНет', TRUE),
    ('m1111111-1111-1111-1111-111111111130', 't1111111-1111-1111-1111-111111111119', 'Максим Соловьев', 'maksim.s@example.com', '+79009990012', 'СекурНет', FALSE),
    -- UX Гении
    ('m1111111-1111-1111-1111-111111111131', 't1111111-1111-1111-1111-111111111110', 'Владимир Кузнецов', 'vladimir.k@example.com', '+79001001122', 'ДизайнЛаб', TRUE),
    ('m1111111-1111-1111-1111-111111111132', 't1111111-1111-1111-1111-111111111110', 'Елена Архипова', 'elena.a@example.com', '+79001001123', 'ДизайнЛаб', FALSE),
    -- ZeroDay Исследователи
    ('m2222222-2222-2222-2222-222222222221', 't2222222-2222-2222-2222-222222222221', 'Иван Петров', 'ivan.p@example.com', '+79006667788', 'СекурИТ', TRUE),
    ('m2222222-2222-2222-2222-222222222222', 't2222222-2222-2222-2222-222222222221', 'Дмитрий Волков', 'dmitry.v@example.com', '+79006667789', 'СекурИТ', FALSE),
    -- КриптоЗащитники
    ('m2222222-2222-2222-2222-222222222223', 't2222222-2222-2222-2222-222222222222', 'Елена Чен', 'elena.chen@example.com', '+79007778899', 'КриптоЛаб', TRUE),
    ('m2222222-2222-2222-2222-222222222224', 't2222222-2222-2222-2222-222222222222', 'Вэй Чжан', 'wei.z@example.com', '+79007778900', 'КриптоЛаб', FALSE),
    -- Защитники Приватности
    ('m2222222-2222-2222-2222-222222222225', 't2222222-2222-2222-2222-222222222223', 'Ахмед Хасанов', 'ahmed.h@example.com', '+79008889900', 'ПривНет', TRUE)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- TEAM ACCOUNTS (Users with team role)
-- =========================================================
DO $$
DECLARE
    team_role_id UUID;
    team_record RECORD;
BEGIN
    SELECT id INTO team_role_id FROM roles WHERE code = 'team';
    
    FOR team_record IN SELECT id, name FROM teams LOOP
        INSERT INTO users (id, login, password_hash, full_name, email, role_id, team_id, is_active)
        VALUES (
            gen_random_uuid(),
            'team_' || regexp_replace(lower(team_record.name), '[^a-z0-9]', '_', 'g'),
            encode(sha256('Team123!'::bytea), 'hex'),
            team_record.name || ' Аккаунт Команды',
            'contact@' || regexp_replace(lower(team_record.name), '[^a-z0-9]', '', 'g') || '.example.com',
            team_role_id,
            team_record.id,
            TRUE
        )
        ON CONFLICT (login) DO UPDATE SET
            team_id = EXCLUDED.team_id,
            is_active = TRUE;
    END LOOP;
END $$;

-- =========================================================
-- EXPERT ASSIGNMENTS FOR AI CHALLENGE
-- =========================================================
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id)
VALUES
    -- Алексей Смирнов (expert1) проверяет команды
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222221', 't1111111-1111-1111-1111-111111111111'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222221', 't1111111-1111-1111-1111-111111111112'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222221', 't1111111-1111-1111-1111-111111111116'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222221', 't1111111-1111-1111-1111-111111111119'),
    -- Елена Козлова (expert2) проверяет команды
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222222', 't1111111-1111-1111-1111-111111111112'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222222', 't1111111-1111-1111-1111-111111111113'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222222', 't1111111-1111-1111-1111-111111111117'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222222', 't1111111-1111-1111-1111-111111111110'),
    -- Михаил Волков (expert3) проверяет команды
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222223', 't1111111-1111-1111-1111-111111111111'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222223', 't1111111-1111-1111-1111-111111111113'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222223', 't1111111-1111-1111-1111-111111111114'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222223', 't1111111-1111-1111-1111-111111111118'),
    -- Анна Морозова (expert4) проверяет команды
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222224', 't1111111-1111-1111-1111-111111111114'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222224', 't1111111-1111-1111-1111-111111111115'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222224', 't1111111-1111-1111-1111-111111111118'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222224', 't1111111-1111-1111-1111-111111111119'),
    -- Дмитрий Новиков (expert5) проверяет команды
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222225', 't1111111-1111-1111-1111-111111111115'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222225', 't1111111-1111-1111-1111-111111111116'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222225', 't1111111-1111-1111-1111-111111111117'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '22222222-2222-2222-2222-222222222225', 't1111111-1111-1111-1111-111111111110')
ON CONFLICT (hackathon_id, expert_user_id, team_id) DO NOTHING;

-- =========================================================
-- EXPERT ASSIGNMENTS FOR CYBERDEF
-- =========================================================
INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id)
VALUES
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', '22222222-2222-2222-2222-222222222224', 't2222222-2222-2222-2222-222222222221'),
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', '22222222-2222-2222-2222-222222222224', 't2222222-2222-2222-2222-222222222222'),
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', '22222222-2222-2222-2222-222222222225', 't2222222-2222-2222-2222-222222222222'),
    (gen_random_uuid(), 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', '22222222-2222-2222-2222-222222222225', 't2222222-2222-2222-2222-222222222223')
ON CONFLICT (hackathon_id, expert_user_id, team_id) DO NOTHING;

-- =========================================================
-- TEAM RESULTS FOR AI CHALLENGE
-- =========================================================
INSERT INTO team_results (id, hackathon_id, team_id, final_score, place, evaluated_by_count, status)
VALUES
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111111', 94.2, 1, 2, 'COMPLETED'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111112', 91.7, 2, 2, 'COMPLETED'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111113', 89.3, 3, 2, 'COMPLETED'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111114', 87.5, 4, 2, 'COMPLETED'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111115', 85.8, 5, 2, 'IN_PROGRESS'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111116', 83.1, 6, 2, 'IN_PROGRESS'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111117', 80.4, 7, 2, 'IN_PROGRESS'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111118', 77.9, 8, 2, 'NOT_STARTED'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111119', 74.6, 9, 2, 'NOT_STARTED'),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 't1111111-1111-1111-1111-111111111110', 71.2, 10, 2, 'NOT_STARTED')
ON CONFLICT (hackathon_id, team_id) DO UPDATE SET
    final_score = EXCLUDED.final_score,
    place = EXCLUDED.place,
    evaluated_by_count = EXCLUDED.evaluated_by_count,
    status = EXCLUDED.status;

-- =========================================================
-- DEADLINES FOR AI CHALLENGE
-- =========================================================
INSERT INTO deadlines (id, hackathon_id, kind, title, description, deadline_at, notify_before_minutes)
VALUES
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'registration', 'Дедлайн регистрации', 'Регистрация команд закрывается', NOW() + INTERVAL '1 day', 60),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'development', 'Фаза разработки', 'Период написания кода', NOW() + INTERVAL '3 days', 120),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'pitch', 'Подача презентации', 'Отправить презентацию проекта', NOW() + INTERVAL '5 days', 180),
    (gen_random_uuid(), 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'evaluation', 'Дедлайн оценки', 'Срок сдачи оценок экспертов', NOW() + INTERVAL '6 days', 240)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- VERIFICATION QUERY
-- =========================================================
DO $$
DECLARE
    hackathon_count INTEGER;
    team_count INTEGER;
    criteria_count INTEGER;
    assignment_count INTEGER;
    result_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO hackathon_count FROM hackathons;
    SELECT COUNT(*) INTO team_count FROM teams;
    SELECT COUNT(*) INTO criteria_count FROM criteria;
    SELECT COUNT(*) INTO assignment_count FROM expert_team_assignments;
    SELECT COUNT(*) INTO result_count FROM team_results;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'НАПОЛНЕНИЕ БАЗЫ ДАННЫХ ЗАВЕРШЕНО';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Хакатонов: %', hackathon_count;
    RAISE NOTICE 'Команд: %', team_count;
    RAISE NOTICE 'Критериев: %', criteria_count;
    RAISE NOTICE 'Назначений экспертов: %', assignment_count;
    RAISE NOTICE 'Результатов команд: %', result_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Учетные данные для входа:';
    RAISE NOTICE '  Администратор: admin / Admin123!';
    RAISE NOTICE '  Эксперт: expert1 / Expert123!';
    RAISE NOTICE '  Команда: team_кибермаги / Team123!';
    RAISE NOTICE '========================================';
END $$;