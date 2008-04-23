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

    function sort_groups(a, b){
      var x = a.name.toLowerCase();
      var y = b.name.toLowerCase();
      return ((x<y) ? -1 : ((x>y) ? 1 : 0));
    }

    this.getActionGroups = function() {
        $.getJSON(url, statusSelect.serialize(), function(json) {
            groupSelect.empty();

            if (json && json.groups && json.groups.length > 0) {
                json.groups.sort(sort_groups);
                var j = 0;
                if (json.prev_recycle_group){
                    var option = new Option(json.prev_recycle_group.name, json.prev_recycle_group.id);
                    option.selected = true;
                    groupSelect.get(0).options[j] = option;
                    j++;
                }
                for (var i = 0; i < json.groups.length; i++) {
                    var group = json.groups[i];

                    if (json.prev_recycle_group && group.id == json.prev_recycle_group.id){
                        continue;
                    }
                    var option = new Option(group.name, group.id);
                    if ( ! json.prev_recycle_group && json.selected_group && group.id == json.selected_group.id) {
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
