# Introduction #

The UFL-Workflow application centers around processes. The processes describe one or more steps that a request can follow. For example, undergraduate course proposals might need to be approved at a number of levels before being taught:

  1. Department
  1. College
  1. Registrar
  1. State

At each step, UFL-Workflow knows who can approve or deny a request based on their role and group. For example, a request approved by the computer engineering department would proceed to the college of engineering. Additionally, only users who have college-level access can act on the request.

# Acting on a request #

The actions allowed at each step are also flexible. UFL-Workflow uses a configurable set of statuses, which can do one (or none) of the following:

  * Continue the request on to the next step (or finish it if the request is at the last step)
  * Reassign the request to a different group, keeping it at the same step
  * Send the request to the previous step ("recycle")
  * Finish the request, allowing no further action (typically used for denying)

There is also at least one initial status, often named "Pending".