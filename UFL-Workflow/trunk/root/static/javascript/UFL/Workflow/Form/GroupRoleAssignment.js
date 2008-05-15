if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.GroupRoleAssignment = function(url, groupId, roleId, groupButtonId, roleButtonId) {
    var me = this;
    var groupSelect;
    var roleSelect;
    var groupButton;
    var roleButton;

    $(document).ready(function() {
        groupSelect = $("#" + groupId);
        roleSelect = $("#" + roleId);
        groupButton = $("#" + groupButtonId);
        roleButton = $("#" + roleButtonId);

        groupButton.hide();
        groupButton.parent().attr("method", "post");
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

                roleSelect.removeAttr("disabled");
                roleButton.removeAttr("disabled");
            }
            else {
                roleSelect.attr("disabled", "disabled");
                roleButton.attr("disabled", "disabled");
            }
        });
    }
};
