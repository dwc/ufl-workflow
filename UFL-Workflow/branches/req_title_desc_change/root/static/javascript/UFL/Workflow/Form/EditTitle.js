if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.EditTitle = function(url, titleid, editFlag) {
    var title;
    var titleParent;
    var edit_flag;
    var url;
    url = url;
    edit_flag = editFlag;
    
    function Load () {
        titleParent = $('#'+titleid);
        titleParent.html("<p>"+titleParent.text()+"</p><img src='/static/images/edit.png' alt='Edit'/>");
	titleParent.children().attr({style:"display:inline"});
	title = titleParent.children();
	title.addClass("edit_start").bind('click',save_start);
    }

    function save_start() {
    	// remove the click function for input box.
    	title.unbind('click',save_start);
	titleParent.html("<input name='"+titleid+"' class='edit_save' value='"+title.filter('p').text() +"' />"+
	                  "<img src='/static/images/save.png' class='edit_save' alt='Save'/>" +
			  "<a>Start Editing</a>");
	titleParent.children("input").attr({style:"display:inline"});
	title = titleParent.children();
	title.filter("a").fadeOut(3000);
	title.addClass('edit_save').removeClass('edit_start');
	title.filter('img').bind('click',save_end);
    }
    function save_end() {
        // save start
	title.filter('img').attr({src:"/static/images/i.png"});
        $.getJSON(url, title.filter("input").serialize(), function(json) {
	    // got the result
	    if (!json.return) {
	       title.filter('a').addClass('error');
	       title.filter('a').text(json.answer).show().fadeOut(3000);
    	       title.filter('img').attr({src:"/static/images/save.png"});
	       return;
	    }
	    
	    titleParent.html("<p>"+title.filter('input').val() +"</p>"+
	                  "<img src='/static/images/edit.png' class='edit_start' alt='Save'/>" +
			  "<a>Failed!</a>");
	    titleParent.children("input").attr({style:"display:inline"});
	    title = titleParent.children();

	    title.filter('a').removeClass('error');
	    title.filter('a').text(json.answer).show().fadeOut(3000);
	    title.addClass('edit_start').removeClass('edit_save');
	    title.unbind('click',save_end).bind('click',save_start);
        }); 
    }

    $(document).ready(function() {
        if (edit_flag) {
	    Load();
	}
    });

}
