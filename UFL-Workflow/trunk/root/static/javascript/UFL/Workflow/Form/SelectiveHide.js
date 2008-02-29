if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.SelectiveHide = function(url,checkBoxId,resultsId) {
    var me = this;
    var processUrl = url; 
    var allOptions = new Array();
    var resultsSelect;
    var checkBox;
    $(document).ready(function() {
        resultsSelect = $("#" + resultsId);
	checkBox = $("#" + checkBoxId);       
	$("#" + checkBoxId).change(function() { me.show_inactive_processes() });
          me.show_inactive_processes() ;
	});
    
    this.show_inactive_processes = function() {
         $.getJSON(url,function(json){
	 resultsSelect.empty();
	 var j = 0;
         if (json && json.processes && json.processes.length > 0) {
             for (var i = 0; i < json.processes.length; i++) {
                  var process = json.processes[i];
                  var option = new Option(process.name, process.id);
		  if( process.enabled == '0')
		  {
		     if( checkBox.get(0).checked )
		     {
		        resultsSelect.get(0).options[j] = option;
                        j++;
	             }
                  }
		  else 
		  {
		     resultsSelect.get(0).options[j] = option;
		     j++;
		  }
		 
             }
         }
    });  
  }
 }
