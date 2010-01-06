-- barks => llombard
UPDATE actions SET user_id = 6121 WHERE user_id = 2021;
UPDATE documents SET user_id = 6121 WHERE user_id = 2021;
UPDATE requests SET user_id = 6121 WHERE user_id = 2021;
UPDATE request_versions SET user_id = 6121 WHERE user_id = 2021;
DELETE FROM user_group_roles WHERE user_id = 2021;
DELETE FROM users WHERE id = 2021;

-- chas => courtneych
UPDATE actions SET user_id = 8397 WHERE user_id = 1028;
UPDATE documents SET user_id = 8397 WHERE user_id = 1028;
UPDATE requests SET user_id = 8397 WHERE user_id = 1028;
UPDATE request_versions SET user_id = 8397 WHERE user_id = 1028;
DELETE FROM user_group_roles WHERE user_id = 1028;
DELETE FROM users WHERE id = 1028;

-- colinb => burrowsc
UPDATE actions SET user_id = 8176 WHERE user_id = 352;
UPDATE documents SET user_id = 8176 WHERE user_id = 352;
UPDATE requests SET user_id = 8176 WHERE user_id = 352;
UPDATE request_versions SET user_id = 8176 WHERE user_id = 352;
DELETE FROM user_group_roles WHERE user_id = 352;
DELETE FROM users WHERE id = 352;

-- danaya => wrightdc
UPDATE actions SET user_id = 8402 WHERE user_id = 6344;
UPDATE documents SET user_id = 8402 WHERE user_id = 6344;
UPDATE requests SET user_id = 8402 WHERE user_id = 6344;
UPDATE request_versions SET user_id = 8402 WHERE user_id = 6344;
DELETE FROM user_group_roles WHERE user_id = 6344;
DELETE FROM users WHERE id = 6344;

-- dhanssen => dlrhodes
UPDATE actions SET user_id = 6711 WHERE user_id = 701;
UPDATE documents SET user_id = 6711 WHERE user_id = 701;
UPDATE requests SET user_id = 6711 WHERE user_id = 701;
UPDATE request_versions SET user_id = 6711 WHERE user_id = 701;
DELETE FROM user_group_roles WHERE user_id = 701;
DELETE FROM users WHERE id = 701;

-- dorothye => mccolskeyd
UPDATE actions SET user_id = 8174 WHERE user_id = 6223;
UPDATE documents SET user_id = 8174 WHERE user_id = 6223;
UPDATE requests SET user_id = 8174 WHERE user_id = 6223;
UPDATE request_versions SET user_id = 8174 WHERE user_id = 6223;
DELETE FROM user_group_roles WHERE user_id = 6223;
DELETE FROM users WHERE id = 6223;

-- hjb54 => hjb
UPDATE actions SET user_id = 8403 WHERE user_id = 5461;
UPDATE documents SET user_id = 8403 WHERE user_id = 5461;
UPDATE requests SET user_id = 8403 WHERE user_id = 5461;
UPDATE request_versions SET user_id = 8403 WHERE user_id = 5461;
DELETE FROM user_group_roles WHERE user_id = 5461;
DELETE FROM users WHERE id = 5461;

-- leedy => tleedy
UPDATE actions SET user_id = 7349 WHERE user_id = 6602;
UPDATE documents SET user_id = 7349 WHERE user_id = 6602;
UPDATE requests SET user_id = 7349 WHERE user_id = 6602;
UPDATE request_versions SET user_id = 7349 WHERE user_id = 6602;
DELETE FROM user_group_roles WHERE user_id = 6602;
DELETE FROM users WHERE id = 6602;

-- leprell => ccarrion
UPDATE actions SET user_id = 6101 WHERE user_id = 1982;
UPDATE documents SET user_id = 6101 WHERE user_id = 1982;
UPDATE requests SET user_id = 6101 WHERE user_id = 1982;
UPDATE request_versions SET user_id = 6101 WHERE user_id = 1982;
DELETE FROM user_group_roles WHERE user_id = 1982;
DELETE FROM users WHERE id = 1982;

-- oconnell => oconnells
UPDATE actions SET user_id = 8404 WHERE user_id = 2462;
UPDATE documents SET user_id = 8404 WHERE user_id = 2462;
UPDATE requests SET user_id = 8404 WHERE user_id = 2462;
UPDATE request_versions SET user_id = 8404 WHERE user_id = 2462;
DELETE FROM user_group_roles WHERE user_id = 2462;
DELETE FROM users WHERE id = 2462;

-- pmglyuf => pamueller
UPDATE actions SET user_id = 8405 WHERE user_id = 290;
UPDATE documents SET user_id = 8405 WHERE user_id = 290;
UPDATE requests SET user_id = 8405 WHERE user_id = 290;
UPDATE request_versions SET user_id = 8405 WHERE user_id = 290;
DELETE FROM user_group_roles WHERE user_id = 290;
DELETE FROM users WHERE id = 290;

-- Users not in directory, could not find replacement:
-- cush311
-- kkafouse
-- talopez

-- Add the active flag to distinguish between users we can convert and users we can't
ALTER TABLE users ADD COLUMN active SMALLINT NOT NULL DEFAULT 1;

-- Add the display name field, because displaying UFIDs would be confusing
ALTER TABLE users ADD COLUMN display_name VARCHAR(256) NOT NULL DEFAULT '';
