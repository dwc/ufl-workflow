if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.StatusGroupAssignment = function(url, statusId, groupId) {
    var me = this;
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
                var j = 0;
                if (json.prev_group) {
                    var option = new Option(json.prev_group.name, json.prev_group.id);
                    option.selected = true;
                    groupSelect.get(0).options[j++] = option;
                }

                for (var i = 0; i < json.groups.length; i++) {
                    var group = json.groups[i];
                    if (json.prev_group && group.id == json.prev_group.id) {
                        continue;
                    }

                    var option = new Option(group.name, group.id);
                    if (! json.prev_group && json.selected_group && group.id == json.selected_group.id) {
                        option.selected = true;
                    }

                    groupSelect.get(0).options[j++] = option;
                }

                groupSelect.parent().show();
            }
            else {
                groupSelect.parent().hide();
            }
        });
    }
}
