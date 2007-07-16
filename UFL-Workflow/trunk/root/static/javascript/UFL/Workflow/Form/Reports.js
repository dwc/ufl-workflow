var groups = new Array();

function setDate(dateRange) {
    if (dateRange) {
        var startDates = dateRange.split('-', 3);
        document.forms[0].start_date_year.value  = parseInt(startDates[0], 10);
        document.forms[0].start_date_month.value = parseInt(startDates[1], 10);
        document.forms[0].start_date_day.value   = parseInt(startDates[2], 10);
    }
}

function click(object,option,condition) {
    if(option && object) {
        switch(option) {
            case "clear":
                if(condition) {
                    if(object.value == condition) {
                        object.value = '';
                    }
                }
                else {
                    object.value = '';
                }	    
            break;	
        }
    }
}

function keyupGroupSearch(object) {
    var input = object.value.toLowerCase();
    var results = Array();
    groupResult = document.getElementById("group_id");	
    options = groupResult.options;	
    options.length = 0;
	
    for(group in groups){
        groupName = groups[group].toLowerCase();
        
        if(groupName.indexOf(input) > -1){
            var option = new Option(groups[group], group);
            options[options.length] = option;
        }
    }
}
				
function clickGroupListAll(object) {
    groupResult = document.getElementById("group_id");	
    options = groupResult.options;
    options.length = 0;
	
    for(group in groups){
        var option = new Option(groups[group], group);
        options[options.length] = option;
    }
}

function initialize(url) {
    // groups = jquery json request and array load [json_id][json_value] 
    $.getJSON(url, 
        function(req) {
            
            var json = req;
            if(json && json.groups && json.groups.length > 0) {
                for(group in json.groups){
                    groups[group] = json.groups[group].name;
                }
            }
        });
}

$(document).ready(function() {
   $('#date_span').change(function() { setDate(this.value) });
   $("#group_search").click(function(){ click(this,'clear','Search for group name');});
   $("#group_search").keyup(function(){ keyupGroupSearch(this); });
   $("#group_list_all").click(function(){ clickGroupListAll(this);});
});
