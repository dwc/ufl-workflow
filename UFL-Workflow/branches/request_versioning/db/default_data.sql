INSERT INTO users (username, email) VALUES ('mhoit', 'mhoit@ufl.edu');
INSERT INTO users (username, email) VALUES ('cschoaf', 'cschoaf@ufl.edu');
INSERT INTO users (username, email) VALUES ('dwc', 'dwc@ufl.edu');
INSERT INTO users (username, email) VALUES ('spooner', 'spooner@ufl.edu');

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
  (SELECT id FROM users WHERE username = 'mhoit'),
  (SELECT id FROM groups WHERE name = 'Information Technology'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'cschoaf'),
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO user_group_roles (user_id, group_id, role_id) VALUES (
  (SELECT id FROM users WHERE username = 'spooner'),
  (SELECT id FROM groups WHERE name = 'Web Administration'),
  (SELECT id FROM roles WHERE name = 'Administrator')
);

INSERT INTO statuses (name, is_initial) VALUES ('Pending', 1);
INSERT INTO statuses (name, continues_request) VALUES ('Approved', 1);
INSERT INTO statuses (name, reassigns_request) VALUES ('Transferred', 1);
INSERT INTO statuses (name, recycles_request) VALUES ('Recycled', 1);
INSERT INTO statuses (name, finishes_request) VALUES ('Denied', 1);
INSERT INTO statuses (name) VALUES ('Tabled');

INSERT INTO processes (user_id, name, description, enabled) VALUES (
  (SELECT id FROM users WHERE username = 'dwc'),
  'Student Withdrawal',
  'A UF student may request withdrawal from all classes up to two weeks before the end of term. If you have questions, please contact your advisor or the Office of the Dean of Students (352-392-1261, www.dso.ufl.edu) Please enter your name and term you''d like to withdraw in the title area. Please add any other summary information you think would help in the description area. After entering the reqeust, add a completed "Application to Withdraw from All Courses" document.',
  1
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Student Withdrawal'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'Academic Advisor'
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Student Withdrawal'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'Financial Obligations'
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Student Withdrawal'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'Financial Aid'
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Student Withdrawal'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'Housing'
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Student Withdrawal'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'International Center'
);

INSERT INTO steps (process_id, role_id, name) VALUES (
  (SELECT id FROM processes WHERE name = 'Student Withdrawal'),
  (SELECT id FROM roles WHERE name = 'Administrator'),
  'Dean of Students'
);

UPDATE steps SET next_step_id = (SELECT id FROM steps WHERE name = 'Financial Obligations') WHERE id = (SELECT id FROM steps WHERE name = 'Academic Advisor');

UPDATE steps SET prev_step_id = (SELECT id FROM steps WHERE name = 'Academic Advisor') WHERE id = (SELECT id FROM steps WHERE name = 'Financial Obligations');
UPDATE steps SET next_step_id = (SELECT id FROM steps WHERE name = 'Financial Aid') WHERE id = (SELECT id FROM steps WHERE name = 'Financial Obligations');

UPDATE steps SET prev_step_id = (SELECT id FROM steps WHERE name = 'Financial Obligations') WHERE id = (SELECT id FROM steps WHERE name = 'Financial Aid');
UPDATE steps SET next_step_id = (SELECT id FROM steps WHERE name = 'Housing') WHERE id = (SELECT id FROM steps WHERE name = 'Financial Aid');

UPDATE steps SET prev_step_id = (SELECT id FROM steps WHERE name = 'Financial Aid') WHERE id = (SELECT id FROM steps WHERE name = 'Housing');
UPDATE steps SET next_step_id = (SELECT id FROM steps WHERE name = 'International Center') WHERE id = (SELECT id FROM steps WHERE name = 'Housing');

UPDATE steps SET prev_step_id = (SELECT id FROM steps WHERE name = 'Housing') WHERE id = (SELECT id FROM steps WHERE name = 'International Center');
UPDATE steps SET next_step_id = (SELECT id FROM steps WHERE name = 'Dean of Students') WHERE id = (SELECT id FROM steps WHERE name = 'International Center');

UPDATE steps SET prev_step_id = (SELECT id FROM steps WHERE name = 'International Center') WHERE id = (SELECT id FROM steps WHERE name = 'Dean of Students');
