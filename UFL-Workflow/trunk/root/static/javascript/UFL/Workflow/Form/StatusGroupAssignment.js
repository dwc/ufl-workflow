if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.StatusGroupAssignment = function(theUrl, statusId, groupId) {
    var me = this;
    var url = theUrl;
    var statusSelect;
    var groupSelect;

    $(document).ready(function() {
        statusSelect = $("#" + statusId);
        groupSelect = $("#" + groupId);

        if (groupSelect && statusSelect) {
            groupSelect.parent().hide();
            statusSelect.change(me.getActionGroups);
        }
    });

    this.getActionGroups = function() {
        $.getJSON(url, statusSelect.serialize(), function(json) {
            groupSelect.empty();

            if (json && json.groups && json.groups.length > 0) {
                for (var i = 0; i < json.groups.length; i++) {
                    var group = json.groups[i];

                    var option = new Option(group.name, group.id);
                    if (json.selected_group && group.id == json.selected_group.id) {
                        option.selected = true;
                    }

                    groupSelect.get(0).options[i] = option;
                }

                groupSelect.parent().show();
            }
            else {
                groupSelect.parent().hide();
            }
        });
    }
}
