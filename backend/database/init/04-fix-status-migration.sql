-- =========================================================
-- COMPLETE MIGRATION SCRIPT FOR EXISTING DATABASE
-- =========================================================
-- Этот скрипт применяет все необходимые изменения:
-- 1. Исправляет hackathon_status на UPPERCASE
-- 2. Добавляет updated_at в expert_team_assignments
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'STARTING DATABASE MIGRATION';
    RAISE NOTICE '========================================';
END $$;

-- =========================================================
-- PART 1: Fix hackathon_status enum to UPPERCASE
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE 'Part 1: Fixing hackathon_status enum...';
    
    -- Check if the enum exists
    IF EXISTS (
        SELECT 1 FROM pg_type 
        WHERE typname = 'hackathon_status'
    ) THEN
        -- Temporarily alter column to text
        ALTER TABLE hackathons ALTER COLUMN status TYPE text;
        
        -- Drop the old enum
        DROP TYPE IF EXISTS hackathon_status CASCADE;
        
        -- Create new enum with UPPERCASE values
        CREATE TYPE hackathon_status AS ENUM ('DRAFT', 'ACTIVE', 'FINISHED');
        
        -- Update data to uppercase
        UPDATE hackathons SET status = 'ACTIVE' WHERE status = 'active';
        UPDATE hackathons SET status = 'DRAFT' WHERE status = 'draft';
        UPDATE hackathons SET status = 'FINISHED' WHERE status = 'finished';
        
        -- Convert column back to enum
        ALTER TABLE hackathons 
            ALTER COLUMN status TYPE hackathon_status 
            USING status::hackathon_status;
        
        -- Update default value
        ALTER TABLE hackathons 
            ALTER COLUMN status SET DEFAULT 'DRAFT'::hackathon_status;
        
        RAISE NOTICE 'Successfully migrated hackathon_status enum to UPPERCASE';
    ELSE
        RAISE NOTICE 'hackathon_status enum does not exist, skipping...';
    END IF;
END $$;

-- =========================================================
-- PART 2: Add updated_at to expert_team_assignments
-- =========================================================

DO $$
BEGIN
    RAISE NOTICE 'Part 2: Adding updated_at to expert_team_assignments...';
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'expert_team_assignments' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE expert_team_assignments 
        ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
        
        RAISE NOTICE 'Added updated_at column to expert_team_assignments';
    ELSE
        RAISE NOTICE 'updated_at column already exists, skipping...';
    END IF;
END $$;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS trg_expert_team_assignments_updated_at ON expert_team_assignments;

CREATE TRIGGER trg_expert_team_assignments_updated_at
    BEFORE UPDATE ON expert_team_assignments
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

RAISE NOTICE 'Created trigger trg_expert_team_assignments_updated_at';

-- =========================================================
-- VERIFICATION
-- =========================================================

DO $$
DECLARE
    enum_labels TEXT;
    has_updated_at BOOLEAN;
    has_trigger BOOLEAN;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'VERIFICATION RESULTS';
    RAISE NOTICE '========================================';
    
    -- Check enum values
    SELECT string_agg(enumlabel, ', ' ORDER BY enumsortorder)
    INTO enum_labels
    FROM pg_enum 
    WHERE enumtypid = 'hackathon_status'::regtype;
    
    RAISE NOTICE 'hackathon_status enum values: %', enum_labels;
    
    -- Check updated_at column
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'expert_team_assignments' 
        AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    RAISE NOTICE 'expert_team_assignments.updated_at exists: %', has_updated_at;
    
    -- Check trigger
    SELECT EXISTS (
        SELECT 1 
        FROM pg_trigger 
        WHERE tgrelid = 'expert_team_assignments'::regclass 
        AND tgname = 'trg_expert_team_assignments_updated_at'
        AND NOT tgisinternal
    ) INTO has_trigger;
    
    RAISE NOTICE 'Trigger exists: %', has_trigger;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'MIGRATION COMPLETED SUCCESSFULLY';
    RAISE NOTICE '========================================';
END $$;

-- Verify the migration
SELECT 
    'hackathon_status enum' as item,
    enumlabel as value
FROM 
    pg_enum 
WHERE 
    enumtypid = 'hackathon_status'::regtype
ORDER BY 
    enumsortorder

UNION ALL

SELECT 
    'expert_team_assignments.updated_at' as item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expert_team_assignments' 
            AND column_name = 'updated_at'
        ) THEN 'EXISTS'
        ELSE 'MISSING'
    END as value

UNION ALL

SELECT 
    'trigger trg_expert_team_assignments_updated_at' as item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgrelid = 'expert_team_assignments'::regclass 
            AND tgname = 'trg_expert_team_assignments_updated_at'
        ) THEN 'EXISTS'
        ELSE 'MISSING'
    END as value;