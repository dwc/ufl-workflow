INSERT INTO users (username) VALUES ('dwc');

INSERT INTO roles (name) VALUES ('admin');

INSERT INTO user_roles (user_id, role_id) VALUES ((SELECT id FROM users WHERE username = 'dwc'), (SELECT id FROM roles WHERE name = 'admin'));
