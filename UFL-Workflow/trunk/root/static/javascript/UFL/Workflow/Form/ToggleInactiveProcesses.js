if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.ToggleInactiveProcesses = function(url, processesId, showInactiveProcessesId) {
    var me = this;
    var processesSelect;
    var showInactiveProcessesCheckbox;

    $(document).ready(function() {
        processesSelect = $("#" + processesId);
        showInactiveProcessesCheckbox = $("#" + showInactiveProcessesId);

        if (processesSelect && showInactiveProcessesCheckbox) {
            showInactiveProcessesCheckbox.click(function() { me.loadProcesses() });
            me.loadProcesses();
        }
    });

    this.loadProcesses = function() {
        $.getJSON(url, processesSelect.serialize(), function(json) {
            processesSelect.empty();

            var j = 0;
            if (json && json.processes && json.processes.length > 0) {
                for (var i = 0; i < json.processes.length; i++) {
                    var process = json.processes[i];

                    if (process.enabled || (showInactiveProcessesCheckbox.get(0).checked)) {
                        var option = new Option(process.name, process.id);
                        if (json.selected_processes && json.selected_processes[process.id]) {
                            option.selected = true;
                        }

                        processesSelect.get(0).options[j++] = option;
                    }
                }
            }
        });
    }
}
