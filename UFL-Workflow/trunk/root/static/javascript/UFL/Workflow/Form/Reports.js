function setDate(dateRange) {
    if(dateRange) {
        var startDates = dateRange.split('-', 3);
        document.forms[0].start_date_year.value  = startDates[0];
        document.forms[0].start_date_month.value = startDates[1];
        document.forms[0].start_date_day.value   = startDates[2];
    }
}

$(document).ready(function(){
   $('#dateSpan').change(function(){setDate(this.value)});
});
