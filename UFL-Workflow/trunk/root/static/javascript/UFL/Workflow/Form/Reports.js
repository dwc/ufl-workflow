function setDate(dateRange) {
    console.log("Date Range Selected: " + dateRange);
}

$(document).ready(function(){
   console.log("Document Ready");
   $('#dateSpan').change(function(){setDate(this.value)});
   console.log("Change Event Inserted");
});
