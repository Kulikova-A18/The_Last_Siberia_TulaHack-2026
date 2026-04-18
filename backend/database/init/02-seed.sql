-- =========================================================
-- SEED DATA FOR HACKATHON DATABASE
-- =========================================================

-- Enable pgcrypto for SHA256 function
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

-- =========================================================
-- USERS (using SHA256 for password hashing)
-- =========================================================

-- Admin user (password: Admin123!)
DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE code = 'admin';
    
    INSERT INTO users (login, password_hash, full_name, email, role_id, is_active)
    VALUES (
        'admin',
        encode(sha256('Admin123!'::bytea), 'hex'),
        'Main Administrator',
        'admin@hackathon.com',
        admin_role_id,
        TRUE
    )
    ON CONFLICT (login) DO NOTHING;
END $$;

-- Expert users (password: Expert123!)
DO $$
DECLARE
    expert_role_id UUID;
BEGIN
    SELECT id INTO expert_role_id FROM roles WHERE code = 'expert';
    
    INSERT INTO users (login, password_hash, full_name, email, phone, role_id, is_active)
    VALUES 
        ('expert1', encode(sha256('Expert123!'::bytea), 'hex'), 'Dr. Sarah Chen', 'sarah.chen@example.com', '+79001234567', expert_role_id, TRUE),
        ('expert2', encode(sha256('Expert123!'::bytea), 'hex'), 'Prof. Michael Roberts', 'michael.roberts@example.com', '+79002345678', expert_role_id, TRUE),
        ('expert3', encode(sha256('Expert123!'::bytea), 'hex'), 'Anna Kowalski', 'anna.kowalski@example.com', '+79003456789', expert_role_id, TRUE),
        ('expert4', encode(sha256('Expert123!'::bytea), 'hex'), 'Dr. James Wilson', 'james.wilson@example.com', '+79004567890', expert_role_id, TRUE),
        ('expert5', encode(sha256('Expert123!'::bytea), 'hex'), 'Elena Petrova', 'elena.petrova@example.com', '+79005678901', expert_role_id, TRUE)
    ON CONFLICT (login) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        is_active = EXCLUDED.is_active;
END $$;

-- =========================================================
-- HACKATHON (FIXED: Using UPPERCASE status)
-- =========================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM hackathons WHERE id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') THEN
        UPDATE hackathons 
        SET status = 'ACTIVE'::hackathon_status,
            start_at = NOW(),
            end_at = NOW() + INTERVAL '7 days'
        WHERE id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    ELSE
        INSERT INTO hackathons (id, title, description, start_at, end_at, status)
        VALUES (
            'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
            'HackRank AI Challenge 2024',
            'Annual hackathon focused on artificial intelligence and machine learning solutions. Teams will compete to build innovative AI applications over 48 hours.',
            NOW(),
            NOW() + INTERVAL '7 days',
            'ACTIVE'::hackathon_status
        );
    END IF;
END $$;

-- =========================================================
-- CRITERIA (total weight = 100%)
-- =========================================================

INSERT INTO criteria (hackathon_id, title, description, max_score, weight_percent, sort_order, is_active)
VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Innovation', 'Originality and creativity of the solution', 10.0, 25.0, 1, TRUE),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Technical Complexity', 'Sophistication of technology stack and implementation', 10.0, 25.0, 2, TRUE),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Business Value', 'Market potential and practical applicability', 10.0, 20.0, 3, TRUE),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Presentation', 'Quality of demo and pitch delivery', 10.0, 15.0, 4, TRUE),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Teamwork', 'Collaboration and team dynamics', 5.0, 15.0, 5, TRUE)
ON CONFLICT (hackathon_id, title) DO NOTHING;

-- =========================================================
-- TEAMS AND TEAM MEMBERS
-- =========================================================

WITH team1 AS (
    INSERT INTO teams (hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
    VALUES (
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Code Wizards',
        'Alex Johnson',
        'alex.j@example.com',
        '+79001112233',
        'AI-Powered Code Review Assistant',
        'An intelligent tool that automatically reviews code quality, suggests improvements, and detects potential bugs using machine learning.'
    )
    ON CONFLICT (hackathon_id, name) DO NOTHING
    RETURNING id
),
team2 AS (
    INSERT INTO teams (hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
    VALUES (
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Data Dynamos',
        'Maria Garcia',
        'maria.g@example.com',
        '+79002223344',
        'Real-Time Fraud Detection System',
        'Machine learning system for detecting fraudulent transactions in real-time using ensemble methods and anomaly detection.'
    )
    ON CONFLICT (hackathon_id, name) DO NOTHING
    RETURNING id
),
team3 AS (
    INSERT INTO teams (hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
    VALUES (
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Neural Ninjas',
        'David Kim',
        'david.k@example.com',
        '+79003334455',
        'Healthcare Diagnosis Assistant',
        'AI assistant that helps doctors diagnose diseases from medical images using deep learning and computer vision.'
    )
    ON CONFLICT (hackathon_id, name) DO NOTHING
    RETURNING id
)
-- Add team members
INSERT INTO team_members (team_id, full_name, email, phone, organization, is_captain)
SELECT id, 'Alex Johnson', 'alex.j@example.com', '+79001112233', 'TechCorp', TRUE FROM team1
UNION ALL SELECT id, 'Nina Patel', 'nina.p@example.com', '+79001112234', 'TechCorp', FALSE FROM team1
UNION ALL SELECT id, 'Tom Wilson', 'tom.w@example.com', '+79001112235', 'Freelance', FALSE FROM team1
UNION ALL SELECT id, 'Maria Garcia', 'maria.g@example.com', '+79002223344', 'DataCo', TRUE FROM team2
UNION ALL SELECT id, 'Lucas Silva', 'lucas.s@example.com', '+79002223345', 'DataCo', FALSE FROM team2
UNION ALL SELECT id, 'Anna Zhang', 'anna.z@example.com', '+79002223346', 'AI Labs', FALSE FROM team2
UNION ALL SELECT id, 'David Kim', 'david.k@example.com', '+79003334455', 'HealthTech', TRUE FROM team3
UNION ALL SELECT id, 'Sarah Chen', 'sarah.chen@example.com', '+79003334456', 'HealthTech', FALSE FROM team3
UNION ALL SELECT id, 'James Wilson', 'james.wilson@example.com', '+79003334457', 'MedAI', FALSE FROM team3;

-- =========================================================
-- CREATE TEAM ACCOUNTS
-- =========================================================

DO $$
DECLARE
    team_role_id UUID;
    team_record RECORD;
BEGIN
    SELECT id INTO team_role_id FROM roles WHERE code = 'team';
    
    FOR team_record IN SELECT id, name FROM teams WHERE hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' LOOP
        INSERT INTO users (login, password_hash, full_name, email, role_id, team_id, is_active)
        VALUES (
            'team_' || regexp_replace(lower(team_record.name), '[^a-z0-9]', '_', 'g'),
            encode(sha256('Team123!'::bytea), 'hex'),
            team_record.name || ' Team Account',
            'contact@' || regexp_replace(lower(team_record.name), '[^a-z0-9]', '', 'g') || '.example.com',
            team_role_id,
            team_record.id,
            TRUE
        )
        ON CONFLICT (login) DO UPDATE SET
            password_hash = EXCLUDED.password_hash,
            team_id = EXCLUDED.team_id,
            is_active = EXCLUDED.is_active;
    END LOOP;
END $$;

-- =========================================================
-- EXPERT ASSIGNMENTS
-- =========================================================

DO $$
DECLARE
    expert1_id UUID;
    expert2_id UUID;
    expert3_id UUID;
    team1_id UUID;
    team2_id UUID;
    team3_id UUID;
BEGIN
    SELECT id INTO expert1_id FROM users WHERE login = 'expert1';
    SELECT id INTO expert2_id FROM users WHERE login = 'expert2';
    SELECT id INTO expert3_id FROM users WHERE login = 'expert3';
    
    SELECT id INTO team1_id FROM teams WHERE name = 'Code Wizards' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    SELECT id INTO team2_id FROM teams WHERE name = 'Data Dynamos' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    SELECT id INTO team3_id FROM teams WHERE name = 'Neural Ninjas' AND hackathon_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    
    INSERT INTO expert_team_assignments (hackathon_id, expert_user_id, team_id)
    VALUES 
        ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', expert1_id, team1_id),
        ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', expert1_id, team2_id),
        ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', expert2_id, team2_id),
        ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', expert2_id, team3_id),
        ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', expert3_id, team1_id),
        ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', expert3_id, team3_id)
    ON CONFLICT (hackathon_id, expert_user_id, team_id) DO NOTHING;
END $$;

-- =========================================================
-- DEADLINES
-- =========================================================

INSERT INTO deadlines (hackathon_id, kind, title, description, deadline_at, notify_before_minutes)
VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'registration', 'Team Registration Deadline', 'All teams must complete registration', NOW() + INTERVAL '1 day', 60),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'development', 'Development Phase', 'Coding and development period', NOW() + INTERVAL '3 days', 120),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'pitch', 'Final Pitch Submission', 'Submit pitch deck and demo video', NOW() + INTERVAL '5 days', 180),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'evaluation', 'Expert Evaluation Deadline', 'All expert evaluations must be submitted', NOW() + INTERVAL '6 days', 240)
ON CONFLICT (hackathon_id, kind, title) DO NOTHING;

-- =========================================================
-- SUMMARY
-- =========================================================

DO $$
DECLARE
    user_count INTEGER;
    team_count INTEGER;
    expert_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO team_count FROM teams;
    SELECT COUNT(*) INTO expert_count FROM users u JOIN roles r ON u.role_id = r.id WHERE r.code = 'expert';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DATABASE SEED COMPLETED SUCCESSFULLY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Users created: %', user_count;
    RAISE NOTICE 'Teams created: %', team_count;
    RAISE NOTICE 'Experts: %', expert_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Login credentials (SHA256 hashed):';
    RAISE NOTICE '  Admin:  admin / Admin123!';
    RAISE NOTICE '  Expert: expert1 / Expert123!';
    RAISE NOTICE '  Team:   team_code_wizards / Team123!';
    RAISE NOTICE '========================================';
END $$;