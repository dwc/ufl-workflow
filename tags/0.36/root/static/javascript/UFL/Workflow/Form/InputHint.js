if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.InputHint = function(jsonURL, input) {
    $(document).ready(function() {
        $(input).jsonSuggest({
		url: jsonURL
	});
    });
}