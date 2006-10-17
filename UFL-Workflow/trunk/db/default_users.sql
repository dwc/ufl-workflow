INSERT INTO users (username) VALUES ('dwc');

INSERT INTO groups (name) VALUES ('Web Administration');

INSERT INTO roles (name) VALUES ('Administrator');

INSERT INTO group_roles (group_id, role_id) VALUES (
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);
