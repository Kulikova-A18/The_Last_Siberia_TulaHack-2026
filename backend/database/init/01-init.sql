-- =========================================================
-- FULL INITIALIZATION SCRIPT FOR HACKATHON DATABASE
-- =========================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =========================================================
-- ENUM TYPES (FIXED: UPPERCASE VALUES FOR TESTS)
-- =========================================================

CREATE TYPE hackathon_status AS ENUM (
    'DRAFT',
    'ACTIVE',
    'FINISHED'
);

CREATE TYPE evaluation_status AS ENUM (
    'draft',
    'submitted'
);

CREATE TYPE deadline_kind AS ENUM (
    'registration',
    'development',
    'pitch',
    'evaluation',
    'custom'
);

CREATE TYPE result_status AS ENUM (
    'not_started',
    'in_progress',
    'completed'
);

-- =========================================================
-- COMMON FUNCTION FOR updated_at
-- =========================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- HACKATHONS TABLE
-- =========================================================

CREATE TABLE hackathons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status hackathon_status NOT NULL DEFAULT 'DRAFT',
    
    results_published BOOLEAN NOT NULL DEFAULT FALSE,
    results_published_at TIMESTAMPTZ,
    
    results_frozen BOOLEAN NOT NULL DEFAULT FALSE,
    results_frozen_at TIMESTAMPTZ,
    
    leaderboard_updated_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT hackathons_date_chk CHECK (start_at < end_at)
);

-- =========================================================
-- ROLES / PERMISSIONS / RBAC
-- =========================================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

-- =========================================================
-- TEAMS TABLE
-- =========================================================

CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hackathon_id UUID NOT NULL REFERENCES hackathons(id) ON DELETE CASCADE,
    
    name VARCHAR(150) NOT NULL,
    captain_name VARCHAR(150) NOT NULL,
    contact_email CITEXT,
    contact_phone VARCHAR(32),
    
    project_title VARCHAR(200) NOT NULL,
    description TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT teams_name_uniq UNIQUE (hackathon_id, name),
    CONSTRAINT teams_id_hackathon_uniq UNIQUE (id, hackathon_id)
);

-- =========================================================
-- USERS TABLE
-- =========================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    login CITEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    
    full_name VARCHAR(200) NOT NULL,
    email CITEXT,
    phone VARCHAR(32),
    
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT users_login_len_chk CHECK (char_length(login) >= 3)
);

CREATE UNIQUE INDEX uq_users_team_id ON users(team_id) WHERE team_id IS NOT NULL;

-- =========================================================
-- REFRESH TOKENS TABLE
-- =========================================================

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    
    user_agent TEXT,
    ip_address INET,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT refresh_tokens_expires_chk CHECK (expires_at > created_at)
);

-- Триггер для updated_at в refresh_tokens
DROP TRIGGER IF EXISTS trg_refresh_tokens_updated_at ON refresh_tokens;
CREATE TRIGGER trg_refresh_tokens_updated_at
    BEFORE UPDATE ON refresh_tokens
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- =========================================================
-- TEAM MEMBERS TABLE
-- =========================================================

CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    
    full_name VARCHAR(200) NOT NULL,
    email CITEXT,
    phone VARCHAR(32),
    organization VARCHAR(200),
    
    is_captain BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_team_members_one_captain 
    ON team_members(team_id) 
    WHERE is_captain = TRUE;

-- =========================================================
-- CRITERIA TABLE
-- =========================================================

CREATE TABLE criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hackathon_id UUID NOT NULL REFERENCES hackathons(id) ON DELETE CASCADE,
    
    title VARCHAR(150) NOT NULL,
    description TEXT,
    
    max_score NUMERIC(6,2) NOT NULL,
    weight_percent NUMERIC(5,2) NOT NULL,
    
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT criteria_max_score_chk CHECK (max_score > 0),
    CONSTRAINT criteria_weight_chk CHECK (weight_percent >= 0 AND weight_percent <= 100),
    CONSTRAINT criteria_sort_order_chk CHECK (sort_order > 0),
    CONSTRAINT criteria_title_uniq UNIQUE (hackathon_id, title),
    CONSTRAINT criteria_sort_uniq UNIQUE (hackathon_id, sort_order),
    CONSTRAINT criteria_id_hackathon_uniq UNIQUE (id, hackathon_id)
);

-- =========================================================
-- EXPERT -> TEAM ASSIGNMENTS (FIXED: added updated_at)
-- =========================================================

CREATE TABLE expert_team_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hackathon_id UUID NOT NULL REFERENCES hackathons(id) ON DELETE CASCADE,
    expert_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID NOT NULL,
    
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT assignments_team_fk
        FOREIGN KEY (team_id, hackathon_id)
        REFERENCES teams(id, hackathon_id)
        ON DELETE CASCADE,
    
    CONSTRAINT assignments_uniq UNIQUE (hackathon_id, expert_user_id, team_id)
);

-- Триггер для updated_at в expert_team_assignments
DROP TRIGGER IF EXISTS trg_expert_team_assignments_updated_at ON expert_team_assignments;
CREATE TRIGGER trg_expert_team_assignments_updated_at
    BEFORE UPDATE ON expert_team_assignments
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- =========================================================
-- EVALUATIONS TABLE
-- =========================================================

CREATE TABLE evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hackathon_id UUID NOT NULL REFERENCES hackathons(id) ON DELETE CASCADE,
    expert_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    team_id UUID NOT NULL,
    
    status evaluation_status NOT NULL DEFAULT 'draft',
    overall_comment TEXT,
    submitted_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT evaluations_team_fk
        FOREIGN KEY (team_id, hackathon_id)
        REFERENCES teams(id, hackathon_id)
        ON DELETE CASCADE,
    
    CONSTRAINT evaluations_assignment_fk
        FOREIGN KEY (hackathon_id, expert_user_id, team_id)
        REFERENCES expert_team_assignments(hackathon_id, expert_user_id, team_id)
        ON DELETE RESTRICT,
    
    CONSTRAINT evaluations_uniq UNIQUE (hackathon_id, expert_user_id, team_id),
    
    CONSTRAINT evaluations_status_chk CHECK (
        (status = 'draft' AND submitted_at IS NULL)
        OR
        (status = 'submitted' AND submitted_at IS NOT NULL)
    )
);

-- =========================================================
-- EVALUATION ITEMS TABLE
-- =========================================================

CREATE TABLE evaluation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id UUID NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
    criterion_id UUID NOT NULL REFERENCES criteria(id) ON DELETE RESTRICT,
    
    raw_score NUMERIC(6,2) NOT NULL,
    comment TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT evaluation_items_raw_score_chk CHECK (raw_score >= 0),
    CONSTRAINT evaluation_items_uniq UNIQUE (evaluation_id, criterion_id)
);

-- =========================================================
-- DEADLINES TABLE
-- =========================================================

CREATE TABLE deadlines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hackathon_id UUID NOT NULL REFERENCES hackathons(id) ON DELETE CASCADE,
    
    kind deadline_kind NOT NULL DEFAULT 'custom',
    title VARCHAR(150) NOT NULL,
    description TEXT,
    deadline_at TIMESTAMPTZ NOT NULL,
    notify_before_minutes INTEGER NOT NULL DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT deadlines_notify_before_chk CHECK (notify_before_minutes >= 0)
);

-- =========================================================
-- TEAM RESULTS (cached leaderboard data)
-- =========================================================

CREATE TABLE team_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hackathon_id UUID NOT NULL REFERENCES hackathons(id) ON DELETE CASCADE,
    team_id UUID NOT NULL,
    
    final_score NUMERIC(7,3) NOT NULL DEFAULT 0,
    place INTEGER,
    evaluated_by_count INTEGER NOT NULL DEFAULT 0,
    status result_status NOT NULL DEFAULT 'not_started',
    
    recalculated_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT team_results_team_fk
        FOREIGN KEY (team_id, hackathon_id)
        REFERENCES teams(id, hackathon_id)
        ON DELETE CASCADE,
    
    CONSTRAINT team_results_uniq UNIQUE (hackathon_id, team_id),
    CONSTRAINT team_results_score_chk CHECK (final_score >= 0 AND final_score <= 100),
    CONSTRAINT team_results_place_chk CHECK (place IS NULL OR place > 0),
    CONSTRAINT team_results_evaluated_by_chk CHECK (evaluated_by_count >= 0)
);

CREATE TABLE team_result_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_result_id UUID NOT NULL REFERENCES team_results(id) ON DELETE CASCADE,
    criterion_id UUID NOT NULL REFERENCES criteria(id) ON DELETE RESTRICT,
    
    avg_raw_score NUMERIC(6,2) NOT NULL DEFAULT 0,
    avg_normalized_score NUMERIC(7,4) NOT NULL DEFAULT 0,
    weighted_score NUMERIC(7,3) NOT NULL DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT team_result_items_avg_raw_chk CHECK (avg_raw_score >= 0),
    CONSTRAINT team_result_items_avg_norm_chk CHECK (avg_normalized_score >= 0 AND avg_normalized_score <= 1),
    CONSTRAINT team_result_items_weighted_chk CHECK (weighted_score >= 0 AND weighted_score <= 100),
    CONSTRAINT team_result_items_uniq UNIQUE (team_result_id, criterion_id)
);

-- =========================================================
-- AUDIT LOGS TABLE
-- =========================================================

CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    
    hackathon_id UUID REFERENCES hackathons(id) ON DELETE CASCADE,
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- BUSINESS VALIDATION TRIGGER
-- =========================================================

CREATE OR REPLACE FUNCTION fn_check_evaluation_item()
RETURNS trigger AS $$
DECLARE
    v_max_score NUMERIC(6,2);
    v_criterion_hackathon UUID;
    v_evaluation_hackathon UUID;
BEGIN
    SELECT c.max_score, c.hackathon_id
      INTO v_max_score, v_criterion_hackathon
    FROM criteria c
    WHERE c.id = NEW.criterion_id;
    
    IF v_max_score IS NULL THEN
        RAISE EXCEPTION 'Criterion % not found', NEW.criterion_id;
    END IF;
    
    SELECT e.hackathon_id
      INTO v_evaluation_hackathon
    FROM evaluations e
    WHERE e.id = NEW.evaluation_id;
    
    IF v_evaluation_hackathon IS NULL THEN
        RAISE EXCEPTION 'Evaluation % not found', NEW.evaluation_id;
    END IF;
    
    IF NEW.raw_score > v_max_score THEN
        RAISE EXCEPTION 'raw_score % exceeds max_score % for criterion %',
            NEW.raw_score, v_max_score, NEW.criterion_id;
    END IF;
    
    IF v_criterion_hackathon <> v_evaluation_hackathon THEN
        RAISE EXCEPTION 'Criterion and evaluation belong to different hackathons';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evaluation_items_check
BEFORE INSERT OR UPDATE ON evaluation_items
FOR EACH ROW
EXECUTE FUNCTION fn_check_evaluation_item();