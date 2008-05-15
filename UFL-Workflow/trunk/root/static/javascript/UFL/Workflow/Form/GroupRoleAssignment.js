if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.GroupRoleAssignment = function(url, groupId, roleId) {
    var me = this;
    var groupSelect;
    var roleSelect;
    var submitSelect;

    $(document).ready(function() {
        groupSelect = $("#" + groupId);
        roleSelect = $("#" + roleId);

        if (roleSelect && roleSelect.length == 0 && groupSelect&& groupSelect.length != 0) {
            groupSelect.parent().parent().html("<label>"+groupSelect.parent().html() + "</label><label>Role:<select id='"+roleId+"' name='"+roleId+"'><option/></select></label><input id='submit_role' class='submit' type='submit' value='Select Group'>");
            groupSelect = $("#" + groupId);
            roleSelect = $("#" + roleId);
            submitSelect = $("#submit_role");
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
                submitSelect.val("Select Role");
                submitSelect.parent().attr({method:"post"});
            }
            else {
                roleSelect.parent().hide();
                submitSelect.val("Select Group");
                submitSelect.parent().attr({method:"get"});
            }
        });
    }
}
