if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.SelectSearch = function(resultsId, queryId, theDefaultValue) {
    var me = this;
    var allOptions = new Array();
    var resultsSelect;
    var queryInput;
    var defaultValue = theDefaultValue;

    $(document).ready(function() {
        resultsSelect = $("#" + resultsId);
        queryInput = $("#" + queryId);

        if (resultsSelect && queryInput) {
            // XXX: Options are broken on IE with resultsSelect.children().clone().get()
            var options = resultsSelect.get(0).options;
            if (options) {
                for (var i = 0; i < options.length; i++) {
                    allOptions[i] = cloneOption(options[i]);
                }
            }

            if (queryInput.get(0).value != defaultValue) {
                me.search();
            }

            queryInput.click(me.clearQuery);
            queryInput.keyup(me.search);
        }
    });

    function cloneOption(option) {
        var clone = {
            text: option.text,
            value: option.value,
            defaultSelected: option.defaultSelected,
            selected: option.selected
        };

        return clone;
    }

    this.clearQuery = function() {
        var input = queryInput.get(0);

        if (defaultValue) {
            if (input.value == defaultValue) {
                input.value = "";
            }
        }
        else {
            input.value = "";
        }
    }

    this.search = function() {
        resultsSelect.empty();

        var options = resultsSelect.get(0).options;

        var input = queryInput.get(0).value.toLowerCase();
        for (var i = 0; i < allOptions.length; i++) {
            var option = allOptions[i];

            var name = option.text.toLowerCase();
            if (name.indexOf(input) > -1) {
                options[options.length] = new Option(option.text, option.value, option.defaultSelected, option.selected);
            }
        }
    }
}
