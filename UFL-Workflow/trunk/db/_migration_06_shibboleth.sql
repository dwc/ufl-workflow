-- Add the active flag to distinguish between users we can convert and users we can't
ALTER TABLE users ADD COLUMN active SMALLINT NOT NULL DEFAULT 1;

-- Add the display name field, because displaying UFIDs would be confusing
ALTER TABLE users ADD COLUMN display_name VARCHAR(256) NOT NULL DEFAULT '(Unknown)';
