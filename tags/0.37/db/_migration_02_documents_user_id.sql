ALTER TABLE documents ALTER COLUMN name SET DATA TYPE VARCHAR(128);
ALTER TABLE documents ALTER COLUMN type SET DATA TYPE VARCHAR(128);

ALTER TABLE documents ADD COLUMN user_id INT;
UPDATE documents SET user_id = (SELECT user_id FROM requests WHERE id = documents.request_id);
