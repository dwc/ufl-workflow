INSERT INTO users (SELECT * FROM wwwuf.users);
INSERT INTO groups (SELECT * FROM wwwuf.groups);
INSERT INTO roles (SELECT * FROM wwwuf.roles);
INSERT INTO group_roles (SELECT * FROM wwwuf.group_roles);
INSERT INTO user_group_roles (SELECT * FROM wwwuf.user_group_roles);

INSERT INTO statuses (SELECT * FROM wwwuf.statuses);
INSERT INTO processes (SELECT * FROM wwwuf.processes);
INSERT INTO steps (SELECT * FROM wwwuf.steps);

INSERT INTO requests (SELECT * FROM wwwuf.requests);
INSERT INTO documents (SELECT * FROM wwwuf.documents);
INSERT INTO actions (SELECT * FROM wwwuf.actions);
INSERT INTO action_groups (SELECT * FROM wwwuf.action_groups);
