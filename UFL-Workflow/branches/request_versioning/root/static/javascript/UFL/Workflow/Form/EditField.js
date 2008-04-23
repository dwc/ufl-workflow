if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.EditField = function(url, edit_field_form) {
    var url = url;
    var field_error_id      = '#field_error';
    var edit_field_form_id  = '#'+edit_field_form;
    $(document).ready(function() {
        for (i=0;i<$(".edit").length;i++) {
            each = $(".edit").eq(i);
            each.editable(url, {
                id        : each.attr('id'),
                name      : each.attr('id').substring(2),
                type      : 'textarea',
                width     : '40',
                cancel    : 'Cancel',
                submit    : 'Validate',
                indicator : "<img src='/static/images/indicator.gif'>",
                tooltip   : 'Click to edit...',
                callback  : function (value, settings) {
                    var resp = eval('('+value+')'); 
                    $(this).html( resp['value'] );
                    $(field_error_id).removeClass("error");
                    $(field_error_id).html(resp['answer']).show();
                    if (resp['answer'] != "Success!" ) {
                        $(field_error_id).addClass("error");
                    }
                    else {
                        // enabled the save button now for saving finally.
                        $(field_error_id).html("Validation "+resp['answer']).fadeOut(5000);
                        $('#submit_data').show();
                        $("#h_"+$(this).attr('id').substring(2)).val(resp['value']);
                    }
                }
           });
           each.parent().append("<span class='hidden'><input type='hidden'id='h_"+each.attr('id').substring(2)+"' name='"+each.attr('id').substring(2)+"' value='"+each.text()+"' /></span>");
        }

       $(".edit_status").append("<ul><li class='hidden' id='field_error'></li><ul><button class='hidden' id='submit_data'>Save Changes</button>");
       $(".hidden").hide();
       $('#submit_data').click(function() {
           $(edit_field_form_id).submit();
       });
    });
}
