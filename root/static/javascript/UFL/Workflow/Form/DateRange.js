if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.DateRange = function(selectId, startYearId, startMonthId, startDayId, endYearId, endMonthId, endDayId) {
    var me = this;
    var startYearInput;
    var startMonthInput;
    var startDayInput;
    var endYearInput;
    var endMonthInput;
    var endDayInput;

    $(document).ready(function() {
        startYearInput = $("#" + startYearId);
        startMonthInput = $("#" + startMonthId);
        startDayInput = $("#" + startDayId);
        endYearInput = $("#" + endYearId);
        endMonthInput = $("#" + endMonthId);
        endDayInput = $("#" + endDayId);

        if (startYearInput && startMonthInput && startDayInput && endYearInput && endMonthInput && endDayInput) {
            $("#" + selectId).change(function() { me.setDate(this.value) });
        }
    });

    this.setDate = function(dateRange) {
        if (dateRange) {
            var dates = dateRange.split(',', 2);
            var startDateParts = dates[0].split('-', 3);
            var endDateParts = dates[1].split('-', 3);

            startYearInput.get(0).value = parseInt(startDateParts[0], 10);
            startMonthInput.get(0).selectedIndex = parseInt(startDateParts[1], 10);
            startDayInput.get(0).value = parseInt(startDateParts[2], 10);
            endYearInput.get(0).value = parseInt(endDateParts[0], 10);
            endMonthInput.get(0).selectedIndex = parseInt(endDateParts[1], 10);
            endDayInput.get(0).value = parseInt(endDateParts[2], 10);
        }
    }
}
