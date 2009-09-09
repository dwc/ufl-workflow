DROP TABLE request_versions;

CREATE TABLE request_versions (
  request_id INTEGER NOT NULL,
  num INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  title VARCHAR(64) NOT NULL,
  description VARCHAR(8192) NOT NULL,
  insert_time TIMESTAMP NOT NULL DEFAULT CURRENT TIMESTAMP,
  update_time TIMESTAMP NOT NULL DEFAULT CURRENT TIMESTAMP,
  PRIMARY KEY (request_id, num)
);

ALTER TABLE request_versions ADD CONSTRAINT request_versions_fk_process_id FOREIGN KEY (process_id) REFERENCES processes(id);

ALTER TABLE request_versions ADD CONSTRAINT request_versions_fk_request_id FOREIGN KEY (request_id) REFERENCES requests(id);

ALTER TABLE request_versions ADD CONSTRAINT request_versions_fk_user_id FOREIGN KEY (user_id) REFERENCES users(id);

CREATE INDEX request_versions_idx_process_id ON request_versions ( process_id );

CREATE INDEX request_versions_idx_request_id ON request_versions ( request_id );

CREATE INDEX request_versions_idx_user_id ON request_versions ( user_id );

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE request_versions
TO USER dbzwap02;

CREATE TRIGGER request_versions_u
NO CASCADE BEFORE UPDATE ON request_versions
REFERENCING NEW AS n
FOR EACH ROW MODE DB2SQL
SET n.update_time = CURRENT TIMESTAMP;
