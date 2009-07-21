YAHOO.util.Event.addListener(window, "load", function() {
    YAHOO.example.Basic = function() {

		var cur_query = "";
    
        var myColumnDefs = [ // sortable:true enables sorting
	        {key:"id", label:"ID", sortable:false, hidden:true},
	        {key:"serverid", label:"Server ID", sortable:false, hidden:true},
	        {key:"title", label:"Title", sortable:true},
	        {key:"album", label:"Album", sortable:true},
	        {key:"artist", label:"Artist", sortable:true}
    	];

        // DataSource instance
	    var myDataSource = new YAHOO.util.DataSource("/json_query?");
	    myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
	    myDataSource.responseSchema = {
	        resultsList: "records",
	        fields: [
	            {key:"id", parser:"number"},
	            {key:"serverid", parser:"number"},
	            {key:"title"},
	            {key:"album"},
	            {key:"artist"}
	        ],
	        metaFields: {
	            totalRecords: "totalRecords", // Access to value in the server response
	            sort: "sort",
	            dir: "dir"
	        }
	    };
	    myDataSource.maxCacheEntries = 0;
	    
    	var myRequestBuilder = function(oState, oSelf) {
    		// Get states or use defaults
    		oState = oState //|| {pagination:null, sortedBy:null};
    		/*var sort = (oState.sortedBy) ? oState.sortedBy.key : "myDefaultColumnKey";
    		var dir = (oState.sortedBy && oState.sortedBy.dir === YAHOO.widget.DataTable.CLASS_DESC) ? "false" : "true";
    		var startIndex = (oState.pagination) ? oState.pagination.recordOffset : 0;
    		var results = (oState.pagination) ? oState.pagination.rowsPerPage : 100;*/
	    	
	    	// Build custom request
		    return  "sort=" + oState.sortedBy.key +
    	        "&dir=" + ((oState.sortedBy.dir === YAHOO.widget.DataTable.CLASS_DESC) ? "desc" : "asc") +
            	"&results=" + oState.pagination.rowsPerPage +
            	"&startIndex=" + oState.pagination.recordOffset +
            	"&query=" + cur_query;
		};
		
	    var myConfigs = {
        	initialRequest: "sort=artist&dir=asc&startIndex=0&results=100", // Initial request for first page of data
        	dynamicData: true, // Enables dynamic server-driven data
        	sortedBy : {key:"artist", dir:YAHOO.widget.DataTable.CLASS_ASC}, // Sets UI initial sort arrow
        	paginator: new YAHOO.widget.Paginator({ rowsPerPage:100,
        											 template : "{PreviousPageLink} <strong>{CurrentPageReport}</strong> {NextPageLink}" }), // Enables pagination 
        	generateRequest : myRequestBuilder
    	};
    	
		
	    var myDataTable = new YAHOO.widget.DataTable("dynamicdata", myColumnDefs, myDataSource, myConfigs);
		myDataTable.handleDataReturnPayload = function(oRequest, oResponse, oPayload) {
			oPayload.sortedBy.key = oResponse.meta.sort;
			if(oResponse.meta.dir == 'asc')
				oPayload.sortedBy.dir = YAHOO.widget.DataTable.CLASS_ASC;
			else if(oResponse.meta.dir == 'desc')
				oPayload.sortedBy.dir = YAHOO.widget.DataTable.CLASS_DESC;
							
			oPayload.totalRecords = oResponse.meta.totalRecords;
			
	        return oPayload;
	    }
	
		//RowSelection
		myDataTable.onEventSelectRow = function(e){
		 	elTarget = e.target;
			oRecord = this.getRecord(elTarget);
			addToQueueFromRecord(oRecord)
			myDataTable.clearTextSelection()
			return true
		}
		myDataTable.subscribe("rowClickEvent", myDataTable.onEventSelectRow); 
		
		var callback = { 
			success : myDataTable.onDataReturnInitializeTable, 
 			scope : myDataTable, 
 			argument : myDataTable.getState() 
		}; 
		
		var getTerms = function(query) {
			cur_query = query;
			
			var dir;
			if(myDataTable.getState().sortedBy.dir == YAHOO.widget.DataTable.CLASS_ASC)
				dir = "asc";
			else if(myDataTable.getState().sortedBy.dir == YAHOO.widget.DataTable.CLASS_DESC)
				dir = "desc";
						
			myDataSource.sendRequest('query=' + query + '&results=100&startIndex=0&sort=' + myDataTable.getState().sortedBy.key + '&dir=' + dir, callback);
    	};
    	
    	var oACDS = new YAHOO.util.FunctionDataSource(getTerms);
        oACDS.queryMatchContains = true;
        var oAutoComp = new YAHOO.widget.AutoComplete("dt_input","dt_ac_container", oACDS);
        oAutoComp.minQueryLength = 0;

        
        return {
            oDS: myDataSource,
            oDT: myDataTable
        };
    }();
    
    YAHOO.example.PlaylistTable = function() {
    	YAHOO.example.Playlist = {
  		  tracks: [
		        //{id:23, serverid:42, title:"d", album:"sad", artist:"fsa"}
    		]
		}
		//YAHOO.example.Playlist.tracks.push({id:23, serverid:42, title:"d", album:"sad", artist:"fsa"})
		
		this.customActionFormat = function(elLiner, oRecord, oColumn, oData) {
			elLiner.innerHTML = oData + '<span class="actions"><img onClick="delete_from_playlist(\'' + oRecord.getId() + '\')" src="/html/clutter/icons/delete.png" /><img onClick="" src="/html/clutter/icons/up.png" /><img onClick="" src="/html/clutter/icons/down.png" /></span>';
		};
		YAHOO.widget.DataTable.Formatter.customActionFormat = this.customActionFormat;
		
    	
    	var myColumnDefs = [
        	{key:"id", label:"ID", sortable:false, hidden:true},
        	{key:"serverid", label:"Server ID", sortable:false, hidden:true},
        	{key:"title", label:"Title", sortable:true},
        	{key:"album", label:"Album", sortable:true},
        	{key:"artist", label:"Artist", sortable:true, formatter:"customActionFormat"}
        ];
        
        var myDataSource = new YAHOO.util.DataSource(YAHOO.example.Playlist.tracks);
        	myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSARRAY;
        	myDataSource.responseSchema = {
	            fields: ["id","serverid","album","artist","title"]
        };
        
        
		var myDataTable = new YAHOO.widget.DataTable("playlist",
                myColumnDefs, myDataSource);
        
		return {
            oDS: myDataSource,
            oDT: myDataTable
        };

	}();
	
	YAHOO.example.Slider = function() {
	    var Event = YAHOO.util.Event,
	        Dom   = YAHOO.util.Dom,
	        lang  = YAHOO.lang,
	        slider, 
	        bg="slider-bg", thumb="slider-thumb", 
	        valuearea="slider-value", textfield="slider-converted-value"
	
	    // The slider can move 0 pixels up
	    var topConstraint = 0;
	    // The slider can move 200 pixels down
	    var bottomConstraint = 100;
	    // Custom scale factor for converting the pixel offset into a real value
	    var scaleFactor = 1;
	    // The amount the slider moves when the value is changed with the arrow keys
	    var keyIncrement = 20;
	    var tickSize = 10;
		
        slider = YAHOO.widget.Slider.getHorizSlider(bg, 
                         thumb, topConstraint, bottomConstraint, tickSize);
        slider.setValue(200);  

        // Sliders with ticks can be animated without YAHOO.util.Anim
        slider.animate = true;

        slider.getRealValue = function() {
            return (this.getValue() * scaleFactor);
        }

        slider.subscribe("slideEnd", function() {
			setVolume1(slider.getRealValue());
        });
	}();

});

