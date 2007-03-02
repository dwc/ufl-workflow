if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.AddAction = Class.create();
UFL.Workflow.Form.AddAction.prototype = {
  initialize: function(url, statusId, groupId) {
    var me = this;
    Event.observe(window, 'load', function() {
      if ($(groupId) && $(statusId)) {
        Element.hide($(groupId).parentNode);
        new Form.Element.EventObserver(statusId, function() { me.getActionGroups(url, $(statusId), $(groupId)) });
      }
    });
  },
  getActionGroups: function(url, statusSelect, groupSelect) {
    var me = this;
    new Ajax.Request(url, {
      parameters: Form.Element.serialize(statusSelect),
      onSuccess: function(req) {
        groupSelect.options.length = 0;

        var json = me.evalJSON(req);
        if (json && json.groups && json.groups.length > 0) {
          for (var i = 0; i < json.groups.length; i++) {
            var group = json.groups[i];
            groupSelect.options[i] = new Option(group.name, group.id);
          }

          Element.show(groupSelect.parentNode);
        }
        else {
          Element.hide(groupSelect.parentNode);
        }
      },
      onFailure: function(req) {
        alert('Error loading groups: ' + req.responseText);
      }
    });
  },
  evalJSON: function(req) {
    try {
      return eval('(' + req.responseText + ')');
    }
    catch (e) {}
  }
};
