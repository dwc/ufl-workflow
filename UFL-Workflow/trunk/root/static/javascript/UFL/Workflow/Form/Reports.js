function setDate(dateRange) {
    if (dateRange) {
        var startDates = dateRange.split('-', 3);
        document.forms[0].start_date_year.value  = parseInt(startDates[0], 10);
        document.forms[0].start_date_month.value = parseInt(startDates[1], 10);
        document.forms[0].start_date_day.value   = parseInt(startDates[2], 10);
    }
}

$(document).ready(function() {
   $('#date_span').change(function() { setDate(this.value) });
});
