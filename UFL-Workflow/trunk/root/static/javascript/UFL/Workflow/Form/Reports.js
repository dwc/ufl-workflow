if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.Reports = function() {
    var me = this;
    var groups = new Array();

    $(document).ready(function() {
        $("#start_date").change(function() { me.setDate(this.value) });
        $("#group_name").click(function() { me.click(this, 'clear', 'Search for group'); });
        $("#group_name").keyup(function() { me.keyupGroupSearch(this) });

        var groupSelect  = document.getElementById("group_id").options;
        if(groupSelect && groupSelect.length > 0) {
            for (group in groupSelect) {
                if(groupSelect[group].value != undefined) {
                    groups[groupSelect[group].value] = groupSelect[group].text;
                }
            }
        }

    });

    this.setDate = function(date) {
        if (date) {
            var dateParts = date.split('-', 3);
            document.forms[0].start_date_year.value  = parseInt(dateParts[0], 10);
            document.forms[0].start_date_month.value = parseInt(dateParts[1], 10);
            document.forms[0].start_date_day.value   = parseInt(dateParts[2], 10);
        }
    };

    this.click = function(object, option, condition) {
        if (option && object) {
            switch (option) {
                case "clear":
                    if (condition) {
                        if (object.value == condition) {
                            object.value = "";
                        }
                    }
                    else {
                        object.value = "";
                    }
                break;
            }
        }
    };

    this.keyupGroupSearch = function(object) {
        var groupSelect = $("#group_id").empty();

        var input = object.value.toLowerCase();
        for (group in groups) {
            var groupName = groups[group].toLowerCase();

                if (groupName.indexOf(input) > -1) {
                var option = new Option(groups[group], group);

                var options = groupSelect.get(0).options;
                options[options.length] = option;
            }
        }
    };

    this.clickGroupListAll = function(object) {
        var groupSelect = $("#group_id").empty();

        for (group in groups) {
            var option = new Option(groups[group], group);

            var options = groupSelect.get(0).options;
            options[options.length] = option;
        }
    };
}
