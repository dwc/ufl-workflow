if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.AddAction = {

  load: function(url, statusId, groupId) {
    var me = this;
    $(document).ready(function() {

      var status = document.getElementById(statusId);
      var group = document.getElementById(groupId);

      if(group && status) {
       $(group).parent().hide();
       $(status).change(function() { me.getActionGroups(url, statusId, groupId) });
      }
    });
  },
  getActionGroups: function(url, statusSelect, groupSelect) {
    var me = this;
    var statusSelect = document.getElementById(statusSelect);
    var groupSelect = document.getElementById(groupSelect);

    $.getJSON(url,
      $(statusSelect).serialize(),
      function(req) {
       $(groupSelect).length = 0;

        var json = req;
        if (json && json.groups && json.groups.length > 0) {
          for (var i = 0; i < json.groups.length; i++) {
            var group = json.groups[i];

            var o = new Option(group.name, group.id);
            if (json.selected_group && group.id == json.selected_group.id) {
              o.selected = true;
            }
            groupSelect.options[i] = o;
          }

          $(groupSelect).parent().show();
        }
        else {
          $(groupSelect).parent().hide();
        }
    });
  }
};
