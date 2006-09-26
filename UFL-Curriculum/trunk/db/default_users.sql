INSERT INTO users (username) VALUES ('dwc');

INSERT INTO groups (user_id, name) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  'Web Administration'
);

INSERT INTO roles (group_id, name) VALUES (
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  'administrator'
);

INSERT INTO user_roles (user_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  (SELECT id FROM roles WHERE name = 'administrator')
);
