YAHOO.widget.DataTable.prototype.requery = function(newRequest) {
	var ds = this.getDataSource();
	if (ds instanceof YAHOO.util.LocalDataSource) {
		ds.liveData = newRequest;
		ds.sendRequest("",
			{
				success: this.onDataReturnInitializeTable,
				failure: this.onDataReturnInitializeTable,
				scope: this
			}
		);
	} else {
		var arg = this.getState();
		if(arg.pagination)
			arg.pagination.recordOffset = 0;
		ds.sendRequest(
			(newRequest === undefined?this.get('initialRequest'):newRequest),
			{
				success: this.onDataReturnInitializeTable,
				failure: this.onDataReturnInitializeTable,
				scope: this,
				argument: arg
			}
		);
	}
};

var cur_query = "";
var initial_page_size = 50;

YAHOO.util.Event.addListener(window, "load", function() {
    YAHOO.example.Basic = function() {

    
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
		var p =  new YAHOO.widget.Paginator({rowsPerPageOptions : [ 10, 25, 50, 100 ], rowsPerPage:initial_page_size, nextPageLinkLabel:"&raquo;", previousPageLinkLabel:"&laquo;",
        											 template : "{PreviousPageLink} <strong>{CurrentPageReport}</strong> {NextPageLink} {RowsPerPageDropdown}", containers:['paginator','paginator2']})
	    var myConfigs = {
        	initialRequest: ("sort=artist&dir=asc&startIndex=0&results=" + initial_page_size), // Initial request for first page of data
        	dynamicData: true, // Enables dynamic server-driven data
        	sortedBy : {key:"artist", dir:YAHOO.widget.DataTable.CLASS_ASC}, // Sets UI initial sort arrow
        	paginator:p, // Enables pagination 
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
			//oPayload.startIndex = oResponse.meta.startIndex;
			//oPayload.recordOffset = oResponse.meta.startIndex;
			
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
		
	
		var getTerms = function(query) {
			cur_query = query;
			
			var dir;
			if(myDataTable.getState().sortedBy.dir == YAHOO.widget.DataTable.CLASS_ASC)
				dir = "asc";
			else if(myDataTable.getState().sortedBy.dir == YAHOO.widget.DataTable.CLASS_DESC)
				dir = "desc";
			
			/*var arg = myDataTable.getState();
			arg.pagination.recordOffset = 0;
			var callback = { 
				success : myDataTable.onDataReturnInitializeTable, 
 				scope : myDataTable, 
 				argument : arg
			}; */
			
			myDataTable.requery('query=' + query + '&results=' + p.getRowsPerPage() + '&startIndex=0&sort=' + myDataTable.getState().sortedBy.key + '&dir=' + dir);
    	};
    	
    	var oACDS = new YAHOO.util.FunctionDataSource(getTerms);
        oACDS.queryMatchContains = true;
        var oAutoComp = new YAHOO.widget.AutoComplete("dt_input","dt_ac_container", oACDS);
        oAutoComp.minQueryLength = 0;
        oAutoComp.queryDelay = 0.3;

        
        return {
            oDS: myDataSource,
            oDT: myDataTable,
            oAC: oAutoComp,
            p: p
        };
    }();
    
    YAHOO.example.PlaylistTable = function() {
    	YAHOO.example.Playlist = {
  		  tracks: [
		        //{id:23, serverid:42, title:"d", album:"sad", artist:"fsa"}
    		]
		}
		//YAHOO.example.Playlist.tracks.push({id:23, serverid:42, title:"d", album:"sad", artist:"fsa"})
		
		
    	
    	var myColumnDefs = [
        	{key:"id", label:"ID", sortable:false, hidden:true},
        	{key:"serverid", label:"Server ID", sortable:false, hidden:true},
        	{key:"title", label:"Title", sortable:true},
        	{key:"album", label:"Album", sortable:true},
        	{key:"artist", label:"Artist", sortable:true}
        ];
        
        var myDataSource = new YAHOO.util.DataSource(YAHOO.example.Playlist.tracks);
        	myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSARRAY;
        	myDataSource.responseSchema = {
	            fields: ["id","serverid","album","artist","title"]
        };
        
        
		var myDataTable = new YAHOO.widget.DataTable("playlist",
                myColumnDefs, myDataSource, {selectionMode:"single"});
                
       myDataTable.subscribe("rowMouseoverEvent",myDataTable.onEventHighlightRow);   
       myDataTable.subscribe("rowMouseoutEvent", myDataTable.onEventUnhighlightRow);   
       myDataTable.subscribe("rowClickEvent", myDataTable.onEventSelectRow);
       myDataTable.subscribe("rowSelectEvent", function(e, r) {
       		loadAndPlay();
   		});
       

		var onContextMenuClick = function(p_sType, p_aArgs, p_myDataTable) { 
			var task = p_aArgs[1]; 
			if(task) { 
				// Extract which TR element triggered the context menu 
				var elRow = this.contextEventTarget; 
				elRow = p_myDataTable.getTrEl(elRow); 
				if(elRow) { 
					id =  p_myDataTable.getRecord(elRow).getId()
					
					switch(task.index) { 
						case 0: //Up
							move(id,1)
							return
						case 1: //Down
							move(id,0)
							return
						case 2: // Delete 
							delete_from_playlist(id)
							return
					} 
				} 
			} 
		}; 
		
		var myContextMenu = new YAHOO.widget.ContextMenu("mycontextmenu", 
		{trigger:myDataTable.getTbodyEl()}); 
		myContextMenu.addItem("<img src='/html/clutter/icons/up.png' alt='Up' />"); 
		myContextMenu.addItem("<img src='/html/clutter/icons/down.png' alt='Down' />"); 
		myContextMenu.addItem("<img src='/html/clutter/icons/delete.png' alt='Delete' />"); 
		// Render the ContextMenu instance to the parent container of the DataTable 
		myContextMenu.render("playlist"); 
		myContextMenu.clickEvent.subscribe(onContextMenuClick, myDataTable);
        
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
	    var tickSize = 5;
		
        slider = YAHOO.widget.Slider.getHorizSlider(bg, 
                         thumb, topConstraint, bottomConstraint, tickSize);
        slider.setValue(bottomConstraint);  

        // Sliders with ticks can be animated without YAHOO.util.Anim
        slider.animate = true;

        slider.getRealValue = function() {
            return (this.getValue() * scaleFactor);
        }

        slider.subscribe("change", function(offset) {
			setVolume1(slider.getRealValue());
        });
	}();
	
	YAHOO.example.SongPositionSlider = function() {
		var Event = YAHOO.util.Event,
	        Dom   = YAHOO.util.Dom,
	        lang  = YAHOO.lang,
	        slider, 
	        bg="songPosition-slider-bg", posThumb="songPosition-slider-position-thumb";
		
	    var draglock = false;
	        
        var songPositionSlider = YAHOO.widget.Slider.getHorizSlider(bg, posThumb, 100, 0, 1);
        songPositionSlider.autoSetValue = function(no) {
			no = no*document.getElementById('songPosition-slider-bg').offsetWidth/100
        	if(draglock == false)
        		songPositionSlider.setValue(no, true, false, true);
        };
                
        songPositionSlider.autoSetMax = function(no) { //
        	//alert(YAHOO.util.Dom.get("songPosition-highlight"));
			no = no*document.getElementById('songPosition-slider-bg').offsetWidth/100
        	YAHOO.util.Dom.setStyle(YAHOO.util.Dom.get("songPosition-highlight"), 'width', (no) +'px');
        	
        	songPositionSlider.getThumb().setXConstraint(0,no,1);
        }
				
	    /*var Event = YAHOO.util.Event,
	        Dom   = YAHOO.util.Dom,
	        lang  = YAHOO.lang,
	        slider, 
	        bg="songPosition-slider-bg", posThumb="songPosition-slider-position-thumb", maxThumb=("songPosition-slider-max-thumb"),
	        valuearea="songPosition-value", textfield="songPosition-slider-converted-value"
	
        var songPositionSlider = YAHOO.widget.Slider.getHorizDualSlider(bg, posThumb, maxThumb, 100, 1, [0,0]);*/

        // Sliders with ticks can be animated without YAHOO.util.Anim

    	songPositionSlider.getThumb().subscribe("mouseDownEvent", function() {
			draglock = true;
    	});

		/*songPositionSlider.subscribe("change", function(offset) {
				setPositionAsPercent(songPositionSlider.minVal());
	    	});*/
        	
        songPositionSlider.getThumb().subscribe("mouseUpEvent", function() {
        	draglock = false;
        	setPositionAsPercent(songPositionSlider.getValue());
			//songSound.resume();
        });

		return songPositionSlider;
	}();
	
	YAHOO.example.Servers = function() {
		var state_increment = -1;
		
		var myCustomFormatter = function(elLiner, oRecord, oColumn, oData) {
			//alert('"' + oData + '"');
			if(oData == true) { 
				var id = YAHOO.example.Servers.oDT.getRecordIndex(oRecord);
			
				elLiner.innerHTML = '<span class="server_actions"><img src="/html/clutter/icons/delete.png" onclick="delete_daap('+ id + ')" alt="Delete" /></span>';
			}
			else {
				elLiner.innerHTML = '<img src="/html/clutter/icons/disabled/delete.png" alt="Disabled Delete" />';
			}
        };
        
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.serverAction = myCustomFormatter;
		
		var myColumnDefs = [ // sortable:true enables sorting
			{key: "id", label:"ID", hidden:true},
	        {key:"name", label:"Name", sortable:true},
	        {key: "address", label:"Address", sortable:true},
	        {key:"count", label:"Songs", sortable:true},
	        {key:"ready", label:"", formatter:"serverAction", width:32}
    	];
    	    	
    	var myDataSource = new YAHOO.util.DataSource("/json_status?");
	    myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
	    myDataSource.responseSchema = {
	        resultsList: "servers",
	        fields: [
	            {key:"count"},
	            {key:"id", parser:"number"},
	            {key:"name"}, {key:"address"}, {key:"ready"} ],
	        metaFields: {state_increment:"state_increment"} 
	    };
	    myDataSource.maxCacheEntries = 0;

	    var myDataTable = new YAHOO.widget.DataTable("servers", myColumnDefs, myDataSource, {initialRequest:""});
	    
	    var callback = { 
	     	success: myDataTable.onDataReturnInitializeTable,
	     	failure: function() { 
	                //alert("FAIL");
                	},
	     	scope: myDataTable,
	     	argument: myDataTable.getState() };
	    
	    myDataSource.setInterval(5000, null, callback); 	
	    
	    myDataTable.handleDataReturnPayload = function(oRequest, oResponse, oPayload) {
			var new_increment = oResponse.meta.state_increment;
			if(state_increment == -1)
				state_increment = new_increment;
			if(new_increment == state_increment)
				return oPayload;
			state_increment = new_increment;
			
			//alert("fish"); // SOMETHING HAS CHANED. *scary organ music*
			
			YAHOO.example.Basic.oAC.getInputEl().value = ""; //update main view
			cur_query = "";
			var dir;
			if(YAHOO.example.Basic.oDT.getState().sortedBy.dir == YAHOO.widget.DataTable.CLASS_ASC)
				dir = "asc";
			else if(YAHOO.example.Basic.oDT.getState().sortedBy.dir == YAHOO.widget.DataTable.CLASS_DESC)
				dir = "desc";
			
			
			YAHOO.example.Basic.oDT.requery("sort=" + YAHOO.example.Basic.oDT.getState().sortedBy.key + "&dir=" + dir + "&startIndex=0&results=" + YAHOO.example.Basic.p.getRowsPerPage());
			//YAHOO.example.Basic.p.setStartIndex(0); //causes double request sometimes
			
			var rs = YAHOO.example.PlaylistTable.oDT.getRecordSet(); //prune playlist
			var i, j, sid, flag, isplaying = 0;
			for(i=0; i < rs.getLength();) {
				sid = rs.getRecord(i).getData()["serverid"];
				flag = 0;
				
				for(j=0; j < oResponse.results.length; j++)
					if(oResponse.results[j].id == sid) {
							flag = 1;
							break;
						}
				
				if(flag==0) {
					YAHOO.example.PlaylistTable.oDT.deleteRow(rs.getRecord(i));
					if(i== 0)
						isplaying = 1;
				}
				else
					i++;
			}
			if(isplaying == 1) {
				loadAndPlayFirstInQueue();
			}
			
						
			return oPayload;
	    }
	    
	    return {
            oDS: myDataSource,
            oDT: myDataTable
        };
	        	
	}();

});

