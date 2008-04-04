if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.EditField = function(url) {
    var url;
    url = url;
    $(document).ready(function() {
        $(".edit").editable(url, { 
            type      : 'textarea',
	    width     : '40',
            cancel    : 'Cancel',
            submit    : 'Save',
            indicator : "<img src='/static/images/indicator.gif'>",
            tooltip   : 'Click to edit...',
	    callback  : function (value, settings) {
	       var resp = eval('('+value+')'); 
	       $(this).html( resp['value'] );
	       $("#field_error").removeClass("error");
	       if (resp['answer'] != "Saved!" ) {
	           $("#field_error").addClass("error");
	       }
	       $("#field_error").html(resp['answer']).show().fadeOut(5000);
	    }
       });
    });
}
