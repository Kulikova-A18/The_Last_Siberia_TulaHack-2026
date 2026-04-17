-- =========================================================
-- PERFORMANCE INDEXES
-- =========================================================

-- Users indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_login ON users(login);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);

-- Teams indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_hackathon_id ON teams(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_name ON teams(name);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_status ON teams(project_title);

-- Team members indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_members_email ON team_members(email);

-- Criteria indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_criteria_hackathon_id ON criteria(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_criteria_is_active ON criteria(is_active);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_criteria_sort_order ON criteria(sort_order);

-- Assignments indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_assignments_hackathon_id ON expert_team_assignments(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_assignments_expert_user_id ON expert_team_assignments(expert_user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_assignments_team_id ON expert_team_assignments(team_id);

-- Evaluations indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluations_hackathon_id ON evaluations(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluations_expert_user_id ON evaluations(expert_user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluations_team_id ON evaluations(team_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluations_status ON evaluations(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluations_submitted_at ON evaluations(submitted_at);

-- Evaluation items indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluation_items_evaluation_id ON evaluation_items(evaluation_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluation_items_criterion_id ON evaluation_items(criterion_id);

-- Deadlines indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_deadlines_hackathon_id ON deadlines(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_deadlines_deadline_at ON deadlines(deadline_at);

-- Team results indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_results_hackathon_id ON team_results(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_results_final_score ON team_results(final_score DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_results_place ON team_results(place);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_results_status ON team_results(status);

-- Team result items indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_result_items_team_result_id ON team_result_items(team_result_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_result_items_criterion_id ON team_result_items(criterion_id);

-- Audit logs indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_hackathon_id ON audit_logs(hackathon_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_actor_user_id ON audit_logs(actor_user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

-- Refresh tokens indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_refresh_tokens_revoked_at ON refresh_tokens(revoked_at);

-- Composite indexes for common queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evaluations_composite 
    ON evaluations(hackathon_id, expert_user_id, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_results_composite 
    ON team_results(hackathon_id, final_score DESC, place);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_assignments_composite 
    ON expert_team_assignments(hackathon_id, expert_user_id);

-- Partial indexes for active records
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_active 
    ON users(id) WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_criteria_active 
    ON criteria(id, hackathon_id) WHERE is_active = true;

-- Full-text search indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_search 
    ON teams USING gin(to_tsvector('russian', name || ' ' || COALESCE(project_title, '')));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_search 
    ON users USING gin(to_tsvector('russian', full_name || ' ' || login));