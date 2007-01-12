INSERT INTO users (username) VALUES ('cschoaf');
INSERT INTO users (username) VALUES ('mhoit');
INSERT INTO users (username) VALUES ('dwc');

INSERT INTO groups (name) VALUES ('Information Technology');
INSERT INTO groups (parent_group_id, name) VALUES (
  (SELECT id FROM groups WHERE name = 'Information Technology'),
  'Web Administration'
);

INSERT INTO roles (name) VALUES ('Administrator');

INSERT INTO group_roles (group_id, role_id) VALUES (
  (SELECT id FROM groups WHERE name = 'Information Technology'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO group_roles (group_id, role_id) VALUES (
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'cschoaf'),
  (SELECT id FROM groups WHERE name = 'Information Technology'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'mhoit'),
  (SELECT id FROM groups WHERE name = 'Information Technology'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO statuses (name, is_initial) VALUES ('Pending', 1);
INSERT INTO statuses (name, continues_request) VALUES ('Approved', 1);
INSERT INTO statuses (name, finishes_request) VALUES ('Denied', 1);
INSERT INTO statuses (name) VALUES ('Tabled');

INSERT INTO processes (user_id, name) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  'Test'
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Test'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'First'
);
INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Test'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'Second'
);

UPDATE steps SET next_step_id = (SELECT id FROM steps WHERE name = 'Second') WHERE id = (SELECT id FROM steps WHERE name = 'First');
UPDATE steps SET prev_step_id = (SELECT id FROM steps WHERE name = 'First') WHERE id = (SELECT id FROM steps WHERE name = 'Second');
