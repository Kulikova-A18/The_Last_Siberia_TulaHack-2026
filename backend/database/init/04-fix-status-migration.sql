-- =========================================================
-- MIGRATION SCRIPT: Fix hackathon_status enum to UPPERCASE
-- =========================================================
-- Run this script if you already have an existing database
-- with lowercase status values
-- =========================================================

DO $$
BEGIN
    -- Check if the enum exists and has lowercase values
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
        RAISE NOTICE 'hackathon_status enum does not exist, nothing to migrate';
    END IF;
END $$;

-- Verify the migration
SELECT 
    enumlabel,
    enumsortorder
FROM 
    pg_enum 
WHERE 
    enumtypid = 'hackathon_status'::regtype
ORDER BY 
    enumsortorder;