if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.GroupRoleAssignment = function(url, groupId, roleId, btnGroupId, btnRoleId) {
    var me = this;
    var groupSelect;
    var roleSelect;
    var btnGroupSelect;
    var btnRoleSelect;

    $(document).ready(function() {
        groupSelect = $("#" + groupId);
        roleSelect = $("#" + roleId);
        btnGroupSelect = $("#" + btnGroupId);
        btnRoleSelect = $("#" + btnRoleId);

        btnGroupSelect.hide();
        btnGroupSelect.parent().attr({method:"post"});
        groupSelect.change(me.getPossibleRoles);

    });

    this.getPossibleRoles = function() {
        $.getJSON(url, groupSelect.serialize(), function(json) {
            roleSelect.empty();

            if (json && json.roles && json.roles.length > 0) {
                for (var i = 0; i < json.roles.length; i++) {
                    var role = json.roles[i];
                    roleSelect.get(0).options[i] = new Option(role.name, role.id);
                }
                btnRoleSelect.removeAttr("disabled");
            }
            else {
                btnRoleSelect.attr("disabled","disabled");
            }
        });
    }
};
