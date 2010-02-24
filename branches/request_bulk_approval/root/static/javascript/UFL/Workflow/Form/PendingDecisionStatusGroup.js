if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.PendingDecisionStatusGroup = function(url, statusId, groupId) {
    var me = this;
    var statusSelect;
    var groupSelect;

    $(document).ready(function() {
        statusSelect = $("#" + statusId);
	groupSelect = $("#" + groupId);
        if (groupSelect && statusSelect) {
            //groupSelect.parent().hide();
            statusSelect.change(me.getActionGroups);
	    me.getActionGroups();
        }
    });

    this.getActionGroups = function() {
        $.getJSON(url, statusSelect.serialize(), function(json) {
            groupSelect.empty();
	    if( statusSelect.length > 0){
	    var index = statusSelect.get(0).selectedIndex;
	    if( index == -1 )
	    {
               index = 0;
	    }
	    var options = statusSelect.get(0).options;
	    var selectedStatus = options[index].text;
	    if( selectedStatus == 'Transferred' )
	    {
	     if (json && json.groups && json.groups.length > 0) {
	       var blankOption = new Option("","");
	       var j = 0;
	       blankOption.selected = true;
	       groupSelect.get(0).options[j] = blankOption;
               j++;
	     for (i = 0; i < json.groups.length; i++,j++) {
	       var group = json.groups[i];
               var option = new Option(group.name, group.id);
               groupSelect.get(0).options[j] = option;						
	     }
	      groupSelect.parent().show();
	     }
	    }
	    
	    else
	    {
	      groupSelect.parent().hide();
	    }
	    }
        });
}
}
