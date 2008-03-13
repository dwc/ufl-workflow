if (typeof UFL == 'undefined') UFL = {};
if (typeof UFL.Workflow == 'undefined') UFL.Workflow = {};
if (typeof UFL.Workflow.Form == 'undefined') UFL.Workflow.Form = {};

UFL.Workflow.Form.Expand = function(advOptId,  advDivId,  advImgId, initFlag) {
    var me = this;
    var advOptIn;
    var advDivIn;
    var advImgIn;
    
    $(document).ready(function() {
       init_params( advOptId, advDivId, advImgId, advOptIn, advDivIn, advImgIn, initFlag);
    });

    function init_params( OptId, DivId, ImgId, OptIn, DivIn, ImgIn, initFlag){
        OptIn = $('#' + OptId);
	DivIn = $('#' + DivId);
	ImgIn = $('#' + ImgId);
	/* If 0 means hide else show. */
	if ( initFlag == 0 ) {
	    DivIn.hide();
	    ImgIn.attr({ src: "/static/images/plus.png" });
	}
	else {
	    ImgIn.attr({ src: "/static/images/minus.png" });
	}
	OptIn.click(function(){ me.menuexpand(ImgIn, DivIn) });
    }

    this.menuexpand = function( img, div ) {
        if ( div.is(':visible') ) {
            img.attr({src : "/static/images/plus.png"});
            div.hide(500);
        }
        else {
            div.show(500);
            img.attr({src : "/static/images/minus.png"});
        }
	return false;
    }
}


