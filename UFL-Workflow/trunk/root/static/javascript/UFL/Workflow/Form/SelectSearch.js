if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.SelectSearch = function(resultsId, queryId, defaultValue) {
    var me = this;
    var values = new Array();

    $(document).ready(function() {
        var results = $("#" + resultsId);
        var query = $("#" + queryId);

        if (results && query) {
            var options = results.get(0).options;
            if (options) {
                for (var i = 0; i < options.length; i++) {
                    var option = options[i];
                    if (option.value != undefined) {
                        values[option.value] = option.text;
                    }
                }
            }

            query.click(function() { me.clearQuery(query, defaultValue); });
            query.keyup(function() { me.search(results, query) });
        }
    });

    this.clearQuery = function(query, defaultValue) {
        var object = query.get(0);

        if (defaultValue) {
            if (object.value == defaultValue) {
                object.value = "";
            }
        }
        else {
            object.value = "";
        }
    };

    this.search = function(results, query) {
        results.empty();

        var input = query.get(0).value.toLowerCase();
        for (value in values) {
            var name = values[value].toLowerCase();
            if (name.indexOf(input) > -1) {
                var option = new Option(values[value], value);

                var options = results.get(0).options;
                options[options.length] = option;
            }
        }
    };
}
