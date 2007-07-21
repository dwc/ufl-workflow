if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.DateRange = function(selectId, startYearId, startMonthId, startDayId, endYearId, endMonthId, endDayId) {
    var me = this;
    var startYearInput;
    var startMonthInput;
    var startDayInput;

    $(document).ready(function() {
        startYearInput = $("#" + startYearId);
        startMonthInput = $("#" + startMonthId);
        startDayInput = $("#" + startDayId);

        if (startYearInput && startMonthInput && startDayInput) {
            $("#" + selectId).change(function() { me.setDate(this.value) });
        }
    });

    this.setDate = function(date) {
        if (date) {
            var dateParts = date.split('-', 3);

            startYearInput.get(0).value = parseInt(dateParts[0], 10);
            startMonthInput.get(0).value = parseInt(dateParts[1], 10);
            startDayInput.get(0).value = parseInt(dateParts[2], 10);
        }
    }
}
