if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.EditDescription = function(url, descriptionid, editFlag) {
    var description;
    var descriptionParent;
    var edit_flag;
    var url;
    url = url;
    edit_flag = editFlag;
    
    function Load () {
        descriptionParent = $('#'+descriptionid);
        descriptionParent.html("<p>"+descriptionParent.text()+"</p><img src='/static/images/edit.png' alt='Edit'/>");
	descriptionParent.children().attr({style:"display:inline"});
	description = descriptionParent.children();
	description.addClass("edit_start").bind('click',save_start);
    }

    function save_start() {
    	// remove the click function for textarea box.
    	description.unbind('click',save_start);
	descriptionParent.html("<textarea name='"+descriptionid+"' cols='40' rows='10' wrap='hard' class='edit_save'>"+jQuery.trim(description.filter('p').text()) +"</textarea>"+
	                  "<img src='/static/images/save.png' class='edit_save' alt='Save'/>" +
			  "<a>Start Editing</a>");
	descriptionParent.children("textarea").attr({style:"display:inline"});
	description = descriptionParent.children();
	description.filter("a").fadeOut(3000);
	description.addClass('edit_save').removeClass('edit_start');
	description.filter('img').bind('click',save_end);
    }
    function save_end() {
        // save start
	description.filter('img').attr({src:"/static/images/i.png"});
        $.getJSON(url, description.filter("textarea").serialize(), function(json) {
	    // got the result
	    if (!json.return) {
	       description.filter('a').addClass('error');
	       description.filter('a').text(json.answer).show().fadeOut(3000);
    	       description.filter('img').attr({src:"/static/images/save.png"});
	       return;
	    }
	    
	    descriptionParent.html("<p>"+description.filter('textarea').val() +"</p>"+
	                  "<img src='/static/images/edit.png' class='edit_start' alt='Save'/>" +
			  "<a>Failed!</a>");
	    descriptionParent.children("textarea").attr({style:"display:inline"});
	    description = descriptionParent.children();

	    description.filter('a').removeClass('error');
	    description.filter('a').text(json.answer).show().fadeOut(3000);
	    description.addClass('edit_start').removeClass('edit_save');
	    description.unbind('click',save_end).bind('click',save_start);
        }); 
	//description.filter('#not_ok').show().fadeOut(3000);
    	//description.filter('img').attr({src:"/static/images/save.png"});
    }

    $(document).ready(function() {
        if (edit_flag) {
	    Load();
	}
    });

}
