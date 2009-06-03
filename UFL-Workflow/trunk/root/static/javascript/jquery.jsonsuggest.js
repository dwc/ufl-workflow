(function() {

    jQuery.fn.jsonSuggest = function(optionSettings) {

	// DEFAULT SETTINGS
        var searchField = '';
        var searchResultId = '';
        var settings = '';                    

        var defaults = {
            url: '',
            suggestId: 'suggest_',
            resultName: 'name',
            resultId: 'id',
            suggestListStyle: 'none',
            suggestMargin: '0 0 5px 0',
            suggestPadding: '0',
            suggestFontSize: '12px',
            suggestPosition: 'absolute',
            suggestZIndex: '5',
            suggestBackgroundColor: '#fff',
            suggestBorder: '1px solid #000',
            suggestLiPadding: '2px 0 0 5px',
            suggestLiMargin: '0px',
            suggestSelectedClass: 'jsonSuggestSelected'
	}

		
         // RESULT BEHAVIOR
         var clearResults = function() {
	     searchResultContainer = searchResultId;
             $(searchResultContainer).hide();
             $(searchResultContainer).empty();
             $(searchField).css("margin-bottom", "10px");
	 }

         var displayResults = function(results) {
  	     searchIdWidth = $(searchField).css("width");
             $(searchResultId).css("width", searchIdWidth);

             position = $(searchField).position();
	     height = $(searchField).outerHeight(true);

             $(searchResultId).css("position", "absolute");
             $(searchResultId).css("top", (position.top + height));
             $(searchResultId).css("left", position.left);
             $(searchResultId).css("list-style", settings.suggestListStyle);
	     $(searchResultId).css("margin", settings.suggestMargin);
             $(searchResultId).css("z-index", settings.suggestZIdex);
             $(searchResultId).css("position", settings.suggestPosition);
             $(searchResultId).css("background-color", settings.suggestBackgroundColor);
             $(searchResultId).css("border", settings.suggestBorder);
            
	     if(results) {
                 if(results.roles != null && results.roles.length > 0) {
                     $(searchResultId).empty();

                     jQuery(results.roles).each(function(i, result) {
                         $(searchResultId).append("<li id='" + settings.suggestId  + result.id + "'>" + result.name + "</li>");
                     });

                     $(searchResultId + " > li").css("padding", settings.suggestLiPadding);
                     $(searchResultId + " > li").css("margin", settings.suggestLiMargin);

                     $(searchField).css("margin-bottom", "0");
                     $(searchResultId).show();
                 }
	     }

             $(searchResultId + " > li").mouseover(function() {
                 $(searchResultId + " > li").removeClass(settings.suggestSelectedClass);
                 $(this).addClass(settings.suggestSelectedClass);
             });

             $(searchResultId + " > li").click(function(e) {
		 selectItem(searchResultId, getSelectedIndex());
	         clearResults();
             });

         }

	 // replace this with the levenshtein sort
         var sortResults = function(a,b) {
             a = a[1];
             b = b[1];

             return a == b ? 0 : (a < b ? -1 : 1);
         }

	// KEYBOARD AND MOUSE BEHAVIOR
        var selectItem = function(listId, index) {
            var count = 0;
            $(listId + " > li").removeClass(settings.suggestSelectedClass);

            if(index != -1) {
                $(listId + " > li").each(function() {
                    if(index == count) {
                        $(this).addClass(settings.suggestSelectedClass);
                        $(searchField).attr("value",this.innerHTML);
                    }

                    count++;
                });
            }
            else {
                $(searchField).attr("value", query);
            }
        }

	var getSelectedIndex = function() {
            var count = 0;
            var selectedItemIndex = -1;

            $(searchResultId + " > li").each(function() {
                if($(this).hasClass(settings.suggestSelectedClass)) {
                    selectedItemIndex = count;
                }
                count++;
	    });

            return selectedItemIndex;
	}
     
        var keySwitch = function(charCode) {
            if(charCode.keyCode == 38 || charCode.keyCode == 39 || charCode.keyCode == 40) {
                var selectedIndex = getSelectedIndex();

                switch(charCode.keyCode) {
                    case 38:
                        if(selectedIndex >= 0) { selectedIndex--; }
                        selectItem(searchResultId, selectedIndex);
	                break;

                    case 39:
                        selectItem(searchResultId, selectedIndex);
                        clearResults();
                        break;

                    case 40:
                        selectedIndex++;
                        selectItem(searchResultId, selectedIndex);
                        break;
                    
	 	    case "click":
			selectItem(searchResultId, selectedIndex);
                        break;
                }           
            }
	    else {
 	        $(searchResultId).empty();
                $(searchResultId).hide();
                search(charCode);
 	    }
        }

	// SEARCH PROCESSING
        function search(charCode) {
            query = $(searchField).attr("value");

            if(query != '') {
                $.getJSON(settings.url + "?q=" + query, function(results) {
			displayResults(results);
		});
	    }
            else {
                clearResults();
            }
	}

	// INITIALIZATION
        var initialize = function() {
            settings = jQuery.extend(defaults, optionSettings);
            searchResultId = "#" + settings.suggestId;

            $(searchField).attr("autocomplete","off");

            $(searchField).keyup(function (e) { 
	        keySwitch(e); 
            });

	    $("head").append("<style type='text/css' media='screen'>.hintbox_list_container { display: block; } .jsonSuggestSelected { background-color:#D1DFFD; }</style>");

            $(searchField).click(function() {
                $(this).focus(); //select the entire value
                $(this).select();
            });

	    $(window).resize(function() {
                displayResults();
            });            

            $(searchField).after("<ul id='" + settings.suggestId + "'></ul>");
	    clearResults();
        }

        if(this.length == 1) {
            searchField = "#" + this[0].id;
            initialize();
        }
    }
})();