if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.ExpandCollapse = function() {

    function Load()
    {
        $(".expanded legend,.collapsed legend").click(function () {
	    if ( $(this).nextAll().filter(".checkbox").is(':visible') ) {
	        $(this).nextAll().filter(".checkbox").attr({style:"display:none"});
	    }
	    else {
	        $(this).nextAll().filter(".checkbox").attr({style:"display:inline"});
	    }
            $(this).nextAll().not(".checkbox").toggle("fast");
	    $(this).parent().toggleClass("collapsed");
	    $(this).parent().toggleClass("expanded");
        });
    }

    $(document).ready(function() { 
        Load();
	$(".collapsed legend").nextAll().toggle("fast");
    });

}


