if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.Expandable = function() {
    $(document).ready(function() {
        $(".expandable h4, .expandable legend").click(function() {
            // Handle checkboxes separately because the toggle animation sets display: block
            $(this).nextAll().not("label.checkbox").toggle("fast");
            $(this).nextAll("label.checkbox").toggle();
            $(this).parent().toggleClass("collapsed");
            $(this).parent().toggleClass("expanded");
        });

        $(".collapsed").children().not("h4, legend").hide("fast");
    });
}
