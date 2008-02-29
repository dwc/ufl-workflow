if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.ToggleInactiveProcesses = function(url, processesId, showInactiveProcessesId) {
    var me = this;
    var processesSelect;
    var checkBox;

    $(document).ready(function() {
        processesSelect = $("#" + processesId);
        showInactiveProcessesCheckbox = $("#" + showInactiveProcessesId);

        if (processesSelect && showInactiveProcessesCheckbox) {
            showInactiveProcessesCheckbox.change(function() { me.loadProcesses() });
            me.loadProcesses();
        }
    });

    this.loadProcesses = function() {
        $.getJSON(url, function(json) {
            processesSelect.empty();

            var j = 0;
            if (json && json.processes && json.processes.length > 0) {
                for (var i = 0; i < json.processes.length; i++) {
                    var process = json.processes[i];

                    var option = new Option(process.name, process.id);
                    if (process.enabled || (showInactiveProcessesCheckbox.get(0).checked)) {
                        processesSelect.get(0).options[j++] = option;
                    }
                }
            }
        });
    }
}
