if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.GroupRoleAssignment = function(url, groupId, roleId) {
    var me = this;
    var groupSelect;
    var roleSelect;

    $(document).ready(function() {
        groupSelect = $("#" + groupId);
        roleSelect = $("#" + roleId);

        if (roleSelect && roleSelect.length == 0 && groupSelect&& groupSelect.length != 0) {
            groupSelect.parent().parent().append("<label>Role:<select id='"+roleId+"' name='"+roleId+"'><option/></select></label>");
            roleSelect = $("#" + roleId);
	    roleSelect.parent().hide();
            groupSelect.change(me.getPossibleRoles);
        }
    });

    this.getPossibleRoles = function() {
        $.getJSON(url, groupSelect.serialize(), function(json) {
            roleSelect.empty();

            if (json && json.roles && json.roles.length > 0) {
                for (var i = 0; i < json.roles.length; i++) {
                    var role = json.roles[i];
                    roleSelect.get(0).options[i] = new Option(role.name, role.id);
                }
                roleSelect.parent().show();
            }
            else {
                roleSelect.parent().hide();
            }
        });
    }
}
