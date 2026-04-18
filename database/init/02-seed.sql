-- =========================================================
-- SEED DATA FOR HACKATHON DATABASE
-- =========================================================

-- Insert roles
INSERT INTO roles (code, name) VALUES
('admin', 'Administrator'),
('expert', 'Expert'),
('team', 'Team')
ON CONFLICT (code) DO NOTHING;

-- Insert permissions
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
        'Main Administrator',
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
        RAISE EXCEPTION 'Sum of weights must be 100%%. Current sum: %', total_weight;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE none;

DROP TRIGGER IF EXISTS trg_validate_criteria_weights ON criteria;
CREATE TRIGGER trg_validate_criteria_weights
BEFORE INSERT OR UPDATE ON criteria
FOR EACH ROW
EXECUTE FUNCTION fn_validate_criteria_weights();