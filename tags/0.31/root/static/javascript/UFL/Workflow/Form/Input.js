if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.Input = function(inputId, defaultValue, className) {
    var me = this;
    var input;
    if (className == null) className = "inactive";

    $(document).ready(function() {
        input = $("#" + inputId);
        input.focus(me.activate);
        input.blur(me.deactivate);

        me.deactivate();
    });

    this.activate = function() {
        input.removeClass(className);

        var obj = input.get(0);
        if (obj.value == defaultValue) {
            obj.value = "";
        }
    }

    this.deactivate = function() {
        var obj = input.get(0);
        if (obj.value == "" || obj.value == defaultValue) {
            input.addClass(className);
            obj.value = defaultValue;
        }
    }
}
