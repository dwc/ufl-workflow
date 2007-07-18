if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.AddAction = function(url, statusId, groupId) {
    var me = this;

    $(document).ready(function() {
        var statusSelect = $("#" + statusId);
        var groupSelect = $("#" + groupId);
        if (groupSelect && statusSelect) {
            groupSelect.parent().hide();
            statusSelect.change(function() { me.getActionGroups(url, statusSelect, groupSelect) });
        }
    });
};

UFL.Workflow.Form.AddAction.prototype.getActionGroups = function(url, statusSelect, groupSelect) {
    $.getJSON(url, statusSelect.serialize(), function(json) {
        groupSelect.empty();

        if (json && json.groups && json.groups.length > 0) {
            for (var i = 0; i < json.groups.length; i++) {
                var group = json.groups[i];

                var o = new Option(group.name, group.id);
                if (json.selected_group && group.id == json.selected_group.id) {
                    o.selected = true;
                }

                groupSelect.get(0).options[i] = o;
            }

            groupSelect.parent().show();
        }
        else {
            groupSelect.parent().hide();
        }
    });
};
