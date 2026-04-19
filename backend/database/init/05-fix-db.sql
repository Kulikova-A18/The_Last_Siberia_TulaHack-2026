-- =========================================================
-- COMPLETE FIX SCRIPT FOR HACKATHON DATABASE
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'STARTING DATABASE FIX';
    RAISE NOTICE '========================================';
END $$;

-- =========================================================
-- 1. Удаляем мешающие триггеры
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE 'Step 1: Removing conflicting triggers...';
    DROP TRIGGER IF EXISTS trg_validate_criteria_weights ON criteria;
    DROP FUNCTION IF EXISTS fn_validate_criteria_weights();
    RAISE NOTICE 'Conflicting triggers removed';
END $$;

-- =========================================================
-- 2. Проверяем и создаем enum result_status если нужно
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE 'Step 2: Checking result_status enum...';
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'result_status') THEN
        CREATE TYPE result_status AS ENUM ('not_started', 'in_progress', 'completed');
        RAISE NOTICE 'Created result_status enum';
    ELSE
        RAISE NOTICE 'result_status enum already exists';
    END IF;
END $$;

-- =========================================================
-- 3. Исправляем статусы team_results (используем правильные значения)
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE 'Step 3: Fixing team_results status values...';
    
    -- Обновляем существующие статусы на правильные значения enum
    UPDATE team_results SET status = 'not_started'::result_status WHERE status::text = 'NOT_STARTED';
    UPDATE team_results SET status = 'in_progress'::result_status WHERE status::text = 'IN_PROGRESS';
    UPDATE team_results SET status = 'completed'::result_status WHERE status::text = 'COMPLETED';
    UPDATE team_results SET status = 'not_started'::result_status WHERE status::text = 'not_started';
    UPDATE team_results SET status = 'in_progress'::result_status WHERE status::text = 'in_progress';
    UPDATE team_results SET status = 'completed'::result_status WHERE status::text = 'completed';
    
    RAISE NOTICE 'Status values fixed';
END $$;

-- =========================================================
-- 4. Создаем команды для AI Challenge (10 команд)
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    v_team_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 4: Creating teams for AI Challenge...';
    
    -- Удаляем старые команды
    DELETE FROM teams WHERE hackathon_id = v_hackathon_id;
    
    -- Создаем 10 команд
    INSERT INTO teams (id, hackathon_id, name, captain_name, contact_email, contact_phone, project_title, description)
    VALUES 
        (gen_random_uuid(), v_hackathon_id, 'Code Wizards', 'Alex Johnson', 'code.wizards@example.com', '+1234567890', 'AI Code Assistant', 'Intelligent code review tool using GPT'),
        (gen_random_uuid(), v_hackathon_id, 'Data Dynamos', 'Maria Garcia', 'data.dynamos@example.com', '+1234567891', 'Fraud Detection System', 'Real-time ML fraud detection'),
        (gen_random_uuid(), v_hackathon_id, 'Neural Ninjas', 'David Kim', 'neural.ninjas@example.com', '+1234567892', 'Medical Diagnosis AI', 'AI for medical diagnostics'),
        (gen_random_uuid(), v_hackathon_id, 'Algorithm Masters', 'Sarah Chen', 'algorithm.masters@example.com', '+1234567893', 'Supply Chain Optimizer', 'ML for logistics optimization'),
        (gen_random_uuid(), v_hackathon_id, 'Quantum Leap', 'James Wilson', 'quantum.leap@example.com', '+1234567894', 'Quantum Simulator', 'Quantum computing simulation'),
        (gen_random_uuid(), v_hackathon_id, 'Cloud Guardians', 'Lisa Brown', 'cloud.guardians@example.com', '+1234567895', 'Cloud Monitoring', 'Cloud service monitoring platform'),
        (gen_random_uuid(), v_hackathon_id, 'Robo Coders', 'Tom Lee', 'robo.coders@example.com', '+1234567896', 'Robot Navigation', 'Intelligent robot navigation'),
        (gen_random_uuid(), v_hackathon_id, 'Blockchain Pioneers', 'Anna Taylor', 'blockchain.pioneers@example.com', '+1234567897', 'Decentralized Storage', 'Blockchain storage platform'),
        (gen_random_uuid(), v_hackathon_id, 'Cyber Defenders', 'Mike Ross', 'cyber.defenders@example.com', '+1234567898', 'Network Traffic Analyzer', 'Network anomaly detection'),
        (gen_random_uuid(), v_hackathon_id, 'UX Geniuses', 'Emma Davis', 'ux.geniuses@example.com', '+1234567899', 'UI Personalizer', 'Adaptive user interface');
    
    SELECT COUNT(*) INTO v_team_count FROM teams WHERE hackathon_id = v_hackathon_id;
    RAISE NOTICE 'Teams created: %', v_team_count;
END $$;

-- =========================================================
-- 5. Создаем критерии для AI Challenge (5 критериев)
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    v_criteria_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 5: Creating criteria for AI Challenge...';
    
    -- Удаляем старые критерии
    DELETE FROM criteria WHERE hackathon_id = v_hackathon_id;
    
    -- Создаем 5 критериев
    INSERT INTO criteria (id, hackathon_id, title, description, max_score, weight_percent, sort_order, is_active)
    VALUES 
        (gen_random_uuid(), v_hackathon_id, 'Innovation', 'Originality and creativity of the solution', 10.0, 25.0, 1, TRUE),
        (gen_random_uuid(), v_hackathon_id, 'Technical Complexity', 'Sophistication of technology stack and implementation', 10.0, 25.0, 2, TRUE),
        (gen_random_uuid(), v_hackathon_id, 'Business Value', 'Market potential and practical applicability', 10.0, 20.0, 3, TRUE),
        (gen_random_uuid(), v_hackathon_id, 'Presentation', 'Quality of demo and pitch delivery', 10.0, 15.0, 4, TRUE),
        (gen_random_uuid(), v_hackathon_id, 'Teamwork', 'Collaboration and team dynamics', 5.0, 15.0, 5, TRUE);
    
    SELECT COUNT(*) INTO v_criteria_count FROM criteria WHERE hackathon_id = v_hackathon_id;
    RAISE NOTICE 'Criteria created: %', v_criteria_count;
END $$;

-- =========================================================
-- 6. Создаем назначения экспертов (каждую команду проверяют 2 эксперта)
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    v_expert_ids UUID[];
    v_team_ids UUID[];
    v_i INTEGER;
    v_j INTEGER;
    v_team_id UUID;
    v_expert_id UUID;
    v_assignment_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 6: Creating expert assignments...';
    
    -- Получаем ID экспертов
    SELECT ARRAY(
        SELECT id FROM users 
        WHERE role_id = (SELECT id FROM roles WHERE code = 'expert')
        AND login IN ('expert1', 'expert2', 'expert3', 'expert4', 'expert5')
        ORDER BY login
    ) INTO v_expert_ids;
    
    -- Получаем ID команд
    SELECT ARRAY(
        SELECT id FROM teams 
        WHERE hackathon_id = v_hackathon_id 
        ORDER BY name
    ) INTO v_team_ids;
    
    -- Удаляем старые назначения
    DELETE FROM expert_team_assignments WHERE hackathon_id = v_hackathon_id;
    
    -- Создаем назначения (каждой команде - 2 эксперта)
    FOR v_i IN 1..array_length(v_team_ids, 1) LOOP
        v_team_id := v_team_ids[v_i];
        
        -- Первый эксперт
        v_j := ((v_i - 1) * 2) % array_length(v_expert_ids, 1) + 1;
        v_expert_id := v_expert_ids[v_j];
        
        INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
        VALUES (gen_random_uuid(), v_hackathon_id, v_expert_id, v_team_id, NOW());
        
        -- Второй эксперт
        v_j := ((v_i - 1) * 2 + 1) % array_length(v_expert_ids, 1) + 1;
        v_expert_id := v_expert_ids[v_j];
        
        INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
        VALUES (gen_random_uuid(), v_hackathon_id, v_expert_id, v_team_id, NOW());
    END LOOP;
    
    SELECT COUNT(*) INTO v_assignment_count FROM expert_team_assignments WHERE hackathon_id = v_hackathon_id;
    RAISE NOTICE 'Expert assignments created: %', v_assignment_count;
END $$;

-- =========================================================
-- 7. Создаем результаты команд (leaderboard) с правильными статусами
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    v_team_record RECORD;
    v_place INTEGER := 1;
    v_result_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 7: Creating team results...';
    
    -- Удаляем старые результаты
    DELETE FROM team_results WHERE hackathon_id = v_hackathon_id;
    
    -- Создаем результаты для каждой команды
    FOR v_team_record IN 
        SELECT id, name FROM teams 
        WHERE hackathon_id = v_hackathon_id 
        ORDER BY name
    LOOP
        INSERT INTO team_results (id, hackathon_id, team_id, final_score, place, evaluated_by_count, status, recalculated_at)
        VALUES (
            gen_random_uuid(),
            v_hackathon_id,
            v_team_record.id,
            CASE v_place
                WHEN 1 THEN 94.5
                WHEN 2 THEN 91.2
                WHEN 3 THEN 88.7
                WHEN 4 THEN 86.3
                WHEN 5 THEN 84.1
                WHEN 6 THEN 81.8
                WHEN 7 THEN 79.2
                WHEN 8 THEN 76.5
                WHEN 9 THEN 73.8
                WHEN 10 THEN 71.0
                ELSE 70.0
            END,
            v_place,
            2,
            CASE 
                WHEN v_place <= 3 THEN 'completed'::result_status
                WHEN v_place <= 6 THEN 'in_progress'::result_status
                ELSE 'not_started'::result_status
            END,
            NOW()
        );
        
        v_place := v_place + 1;
    END LOOP;
    
    SELECT COUNT(*) INTO v_result_count FROM team_results WHERE hackathon_id = v_hackathon_id;
    RAISE NOTICE 'Team results created: %', v_result_count;
END $$;

-- =========================================================
-- 8. Обновляем метаданные хакатона
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
BEGIN
    RAISE NOTICE 'Step 8: Updating hackathon metadata...';
    
    UPDATE hackathons 
    SET leaderboard_updated_at = NOW(),
        results_published = TRUE,
        updated_at = NOW()
    WHERE id = v_hackathon_id;
    
    RAISE NOTICE 'Hackathon metadata updated';
END $$;

-- =========================================================
-- 9. Создаем аккаунты для команд
-- =========================================================

DO $$
DECLARE
    v_team_role_id UUID;
    v_team_record RECORD;
    v_login TEXT;
    v_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Step 9: Creating team user accounts...';
    
    SELECT id INTO v_team_role_id FROM roles WHERE code = 'team';
    
    FOR v_team_record IN SELECT id, name FROM teams LOOP
        v_login := 'team_' || lower(regexp_replace(v_team_record.name, '[^a-zA-Z0-9]', '_', 'g'));
        
        INSERT INTO users (login, password_hash, full_name, email, role_id, team_id, is_active)
        VALUES (
            v_login,
            encode(sha256('Team123!'::bytea), 'hex'),
            v_team_record.name || ' Team Account',
            v_login || '@example.com',
            v_team_role_id,
            v_team_record.id,
            TRUE
        )
        ON CONFLICT (login) DO UPDATE SET
            team_id = EXCLUDED.team_id,
            is_active = TRUE;
        
        v_count := v_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Created/updated % team user accounts', v_count;
END $$;

-- =========================================================
-- 10. Создаем назначения экспертов для CyberDef
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';
    v_expert1_id UUID;
    v_expert2_id UUID;
    v_team_ids UUID[];
    v_team_record RECORD;
    v_assignment_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 10: Creating expert assignments for CyberDef...';
    
    -- Получаем ID экспертов
    SELECT id INTO v_expert1_id FROM users WHERE login = 'expert4';
    SELECT id INTO v_expert2_id FROM users WHERE login = 'expert5';
    
    -- Получаем ID команд
    SELECT ARRAY(
        SELECT id FROM teams 
        WHERE hackathon_id = v_hackathon_id 
        ORDER BY name
    ) INTO v_team_ids;
    
    -- Удаляем старые назначения
    DELETE FROM expert_team_assignments WHERE hackathon_id = v_hackathon_id;
    
    -- Создаем назначения
    IF array_length(v_team_ids, 1) >= 3 THEN
        -- ZeroDay Hunters (expert4)
        INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
        VALUES (gen_random_uuid(), v_hackathon_id, v_expert1_id, v_team_ids[1], NOW());
        
        -- Crypto Guardians (expert4 и expert5)
        INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
        VALUES (gen_random_uuid(), v_hackathon_id, v_expert1_id, v_team_ids[2], NOW()),
               (gen_random_uuid(), v_hackathon_id, v_expert2_id, v_team_ids[2], NOW());
        
        -- Privacy Defenders (expert5)
        INSERT INTO expert_team_assignments (id, hackathon_id, expert_user_id, team_id, assigned_at)
        VALUES (gen_random_uuid(), v_hackathon_id, v_expert2_id, v_team_ids[3], NOW());
    END IF;
    
    SELECT COUNT(*) INTO v_assignment_count FROM expert_team_assignments WHERE hackathon_id = v_hackathon_id;
    RAISE NOTICE 'CyberDef assignments created: %', v_assignment_count;
END $$;

-- =========================================================
-- 11. Создаем результаты для CyberDef
-- =========================================================

DO $$
DECLARE
    v_hackathon_id UUID := 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';
    v_team_record RECORD;
    v_place INTEGER := 1;
    v_result_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 11: Creating team results for CyberDef...';
    
    -- Удаляем старые результаты
    DELETE FROM team_results WHERE hackathon_id = v_hackathon_id;
    
    FOR v_team_record IN 
        SELECT id, name FROM teams 
        WHERE hackathon_id = v_hackathon_id 
        ORDER BY name
    LOOP
        INSERT INTO team_results (id, hackathon_id, team_id, final_score, place, evaluated_by_count, status, recalculated_at)
        VALUES (
            gen_random_uuid(),
            v_hackathon_id,
            v_team_record.id,
            CASE v_place
                WHEN 1 THEN 90.0
                WHEN 2 THEN 85.5
                WHEN 3 THEN 88.0
                ELSE 80.0
            END,
            v_place,
            CASE v_place
                WHEN 2 THEN 2
                ELSE 1
            END,
            'completed'::result_status,
            NOW()
        );
        
        v_place := v_place + 1;
    END LOOP;
    
    SELECT COUNT(*) INTO v_result_count FROM team_results WHERE hackathon_id = v_hackathon_id;
    RAISE NOTICE 'CyberDef results created: %', v_result_count;
END $$;

-- =========================================================
-- 12. Финальная проверка
-- =========================================================

DO $$
DECLARE
    v_ai_hackathon_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    v_cyber_hackathon_id UUID := 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';
    v_ai_teams INTEGER;
    v_ai_criteria INTEGER;
    v_ai_assignments INTEGER;
    v_ai_results INTEGER;
    v_cyber_teams INTEGER;
    v_cyber_criteria INTEGER;
    v_cyber_assignments INTEGER;
    v_cyber_results INTEGER;
BEGIN
    -- AI Challenge данные
    SELECT COUNT(*) INTO v_ai_teams FROM teams WHERE hackathon_id = v_ai_hackathon_id;
    SELECT COUNT(*) INTO v_ai_criteria FROM criteria WHERE hackathon_id = v_ai_hackathon_id;
    SELECT COUNT(*) INTO v_ai_assignments FROM expert_team_assignments WHERE hackathon_id = v_ai_hackathon_id;
    SELECT COUNT(*) INTO v_ai_results FROM team_results WHERE hackathon_id = v_ai_hackathon_id;
    
    -- CyberDef данные
    SELECT COUNT(*) INTO v_cyber_teams FROM teams WHERE hackathon_id = v_cyber_hackathon_id;
    SELECT COUNT(*) INTO v_cyber_criteria FROM criteria WHERE hackathon_id = v_cyber_hackathon_id;
    SELECT COUNT(*) INTO v_cyber_assignments FROM expert_team_assignments WHERE hackathon_id = v_cyber_hackathon_id;
    SELECT COUNT(*) INTO v_cyber_results FROM team_results WHERE hackathon_id = v_cyber_hackathon_id;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'FINAL VERIFICATION RESULTS';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'AI Challenge Hackathon:';
    RAISE NOTICE '  Teams:       %', v_ai_teams;
    RAISE NOTICE '  Criteria:    %', v_ai_criteria;
    RAISE NOTICE '  Assignments: %', v_ai_assignments;
    RAISE NOTICE '  Results:     %', v_ai_results;
    RAISE NOTICE '';
    RAISE NOTICE 'CyberDef Hackathon:';
    RAISE NOTICE '  Teams:       %', v_cyber_teams;
    RAISE NOTICE '  Criteria:    %', v_cyber_criteria;
    RAISE NOTICE '  Assignments: %', v_cyber_assignments;
    RAISE NOTICE '  Results:     %', v_cyber_results;
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DATABASE FIX COMPLETED SUCCESSFULLY';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Test Credentials:';
    RAISE NOTICE '  Admin:  admin / Admin123!';
    RAISE NOTICE '  Expert: expert1 / Expert123!';
    RAISE NOTICE '  Expert: expert2 / Expert123!';
    RAISE NOTICE '  Expert: expert3 / Expert123!';
    RAISE NOTICE '  Expert: expert4 / Expert123!';
    RAISE NOTICE '  Expert: expert5 / Expert123!';
    RAISE NOTICE '  Team:   team_Code_Wizards / Team123!';
    RAISE NOTICE '  Team:   team_Data_Dynamos / Team123!';
    RAISE NOTICE '  Team:   team_Neural_Ninjas / Team123!';
    RAISE NOTICE '========================================';
END $$;