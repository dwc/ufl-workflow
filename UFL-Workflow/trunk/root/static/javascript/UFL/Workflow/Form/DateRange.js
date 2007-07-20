if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.DateRange = function(selectId, startYearId, startMonthId, startDayId, endYearId, endMonthId, endDayId) {
    var me = this;

    $(document).ready(function() {
        var startYear = $("#" + startYearId);
        var startMonth = $("#" + startMonthId);
        var startDay = $("#" + startDayId);
        if (startYear && startMonth && startDay) {
            $("#" + selectId).change(function() { me.setDate(this.value, startYear, startMonth, startDay) });
        }
    });
}

UFL.Workflow.Form.DateRange.prototype.setDate = function(date, year, month, day) {
    if (date) {
        var dateParts = date.split('-', 3);

        year.get(0).value = parseInt(dateParts[0], 10);
        month.get(0).value = parseInt(dateParts[1], 10);
        day.get(0).value = parseInt(dateParts[2], 10);
    }
};
