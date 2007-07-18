var groups = new Array();

function setDate(dateRange) {
    if (dateRange) {
        var startDates = dateRange.split('-', 3);
        document.forms[0].start_date_year.value  = parseInt(startDates[0], 10);
        document.forms[0].start_date_month.value = parseInt(startDates[1], 10);
        document.forms[0].start_date_day.value   = parseInt(startDates[2], 10);
    }
}

function click(object, option, condition) {
    if (option && object) {
        switch(option) {
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
}

function keyupGroupSearch(object) {
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
}

function clickGroupListAll(object) {
    var groupSelect = $("#group_id").empty();

    for (group in groups) {
        var option = new Option(groups[group], group);

        var options = groupSelect.get(0).options;
        options[options.length] = option;
    }
}

function initialize(url) {
    $.getJSON(url, function(json) {
        if (json && json.groups && json.groups.length > 0) {
            for (group in json.groups) {
                groups[group] = json.groups[group].name;
            }
        }
    });
}

$(document).ready(function() {
    $('#date_span').change(function() { setDate(this.value) });
    $("#group_name").click(function() { click(this, 'clear', 'Search for group'); });
    $("#group_name").keyup(function() { keyupGroupSearch(this) });
    $("#group_list_all").click(function() { clickGroupListAll(this) });
});
