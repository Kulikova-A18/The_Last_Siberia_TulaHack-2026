-- =========================================================
-- SEED DATA FOR HACKATHON DATABASE
-- =========================================================

-- Insert roles
INSERT INTO roles (code, name) VALUES
('admin', 'Администратор'),
('expert', 'Эксперт'),
('team', 'Команда')
ON CONFLICT (code) DO NOTHING;

-- Insert permissions
INSERT INTO permissions (code, name, description) VALUES
('users.read', 'Просмотр пользователей', 'Чтение списка пользователей'),
('users.create', 'Создание пользователей', 'Создание учетных записей'),
('users.update', 'Редактирование пользователей', 'Изменение профилей и статусов'),
('users.delete', 'Удаление пользователей', 'Удаление учетных записей'),
('teams.read', 'Просмотр команд', 'Чтение списка команд'),
('teams.create', 'Создание команд', 'Добавление новых команд'),
('teams.update', 'Редактирование команд', 'Редактирование карточек команд'),
('teams.delete', 'Удаление команд', 'Удаление команд'),
('criteria.read', 'Просмотр критериев', 'Чтение критериев оценки'),
('criteria.manage', 'Управление критериями', 'Создание/редактирование/удаление критериев'),
('assignments.read', 'Просмотр назначений', 'Чтение назначений экспертов'),
('assignments.manage', 'Управление назначениями', 'Назначение экспертов на команды'),
('evaluations.read', 'Просмотр оценок', 'Просмотр всех оценок'),
('evaluations.submit', 'Отправка оценок', 'Отправка оценки экспертом'),
('evaluations.reopen', 'Переоткрытие оценки', 'Переоткрытие оценки администратором'),
('results.read', 'Просмотр результатов', 'Просмотр рейтинга и итогов'),
('results.publish', 'Публикация результатов', 'Публикация leaderboard'),
('results.freeze', 'Фиксация результатов', 'Блокировка изменений результатов'),
('deadlines.read', 'Просмотр дедлайнов', 'Чтение дедлайнов'),
('deadlines.manage', 'Управление дедлайнами', 'Создание и редактирование дедлайнов'),
('audit.read', 'Просмотр аудита', 'Просмотр журнала действий')
ON CONFLICT (code) DO NOTHING;

-- Assign permissions to admin role
DO $$
DECLARE
    admin_role_id UUID;
    perm_record RECORD;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE code = 'admin';
    
    FOR perm_record IN SELECT id FROM permissions LOOP
        INSERT INTO role_permissions (role_id, permission_id)
        VALUES (admin_role_id, perm_record.id)
        ON CONFLICT (role_id, permission_id) DO NOTHING;
    END LOOP;
END $$;

-- Assign permissions to expert role
DO $$
DECLARE
    expert_role_id UUID;
BEGIN
    SELECT id INTO expert_role_id FROM roles WHERE code = 'expert';
    
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT expert_role_id, id FROM permissions 
    WHERE code IN (
        'teams.read',
        'criteria.read',
        'evaluations.submit',
        'results.read',
        'deadlines.read'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;
END $$;

-- Assign permissions to team role
DO $$
DECLARE
    team_role_id UUID;
BEGIN
    SELECT id INTO team_role_id FROM roles WHERE code = 'team';
    
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT team_role_id, id FROM permissions 
    WHERE code IN (
        'teams.read',
        'results.read',
        'deadlines.read'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;
END $$;

-- Create default admin user (password: Admin123!)
DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE code = 'admin';
    
    INSERT INTO users (login, password_hash, full_name, email, role_id, is_active)
    VALUES (
        'admin',
        crypt('Admin123!', gen_salt('bf')),
        'Главный Администратор',
        'admin@hackathon.com',
        admin_role_id,
        TRUE
    )
    ON CONFLICT (login) DO NOTHING;
END $$;

-- Create function to validate criteria weights sum to 100
CREATE OR REPLACE FUNCTION fn_validate_criteria_weights()
RETURNS trigger AS $$
DECLARE
    total_weight NUMERIC(5,2);
BEGIN
    SELECT SUM(weight_percent)
    INTO total_weight
    FROM criteria
    WHERE hackathon_id = NEW.hackathon_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);
    
    total_weight := COALESCE(total_weight, 0) + NEW.weight_percent;
    
    IF total_weight != 100 THEN
        RAISE EXCEPTION 'Sum of weights must be 100%%. Current sum: %%', total_weight;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_criteria_weights
BEFORE INSERT OR UPDATE ON criteria
FOR EACH ROW
EXECUTE FUNCTION fn_validate_criteria_weights();