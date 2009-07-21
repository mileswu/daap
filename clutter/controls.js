function addToQueueFromRecord(oRecord){
	YAHOO.example.PlaylistTable.oDT.addRow({id:oRecord.getData("id"), serverid:oRecord.getData("serverid"), title:oRecord.getData("title"), album:oRecord.getData("album"), artist:oRecord.getData("artist")});
	
	
	if(YAHOO.example.PlaylistTable.oDT.getRecordSet().getLength() == 1){
		loadAndPlayFirstInQueue();
	}
	
	delayedUpdate();
}

YAHOO.util.Event.addListener(window, "load", function() {	
	niftyplayer('niftyPlayer1').registerEvent('onSongOver', 'delayedUpdate()');
	niftyplayer('niftyPlayer1').registerEvent('onSongOver', 'playNextSong()');
	niftyplayer('niftyPlayer1').registerEvent('onPause', 'updateButtonStates()');
	niftyplayer('niftyPlayer1').registerEvent('onPlay', 'delayedUpdate()');
	
	niftyplayer('niftyPlayer1').registerEvent('onBufferingStarted', "setHealthIndicator('busy');");
	niftyplayer('niftyPlayer1').registerEvent('onBufferingComplete', "setHealthIndicator('smiley');");
	niftyplayer('niftyPlayer1').registerEvent('onError', "setHealthIndicator('error');");


	delayedUpdate();
});

function setVolume1(vol) {
	niftyplayer('niftyPlayer1').setVolume(vol);
}

function delayedUpdate(){
	setTimeout(updateButtonStates,150);
}

function setCurrentlyPlaying(){//Have to assume that either queue[0] is playing, or nothing is.
	if(niftyplayer('niftyPlayer1').getLoadingState() == "empty"){
		document.getElementById('trackTitle').innerHTML = "";
		document.getElementById('trackAlbum').innerHTML = "";
		document.getElementById('trackArtist').innerHTML = "";
	}else{
		var song = YAHOO.example.PlaylistTable.oDT.getRecord(0).getData();
		document.getElementById('trackTitle').innerHTML = song["title"];
		document.getElementById('trackAlbum').innerHTML = song["album"];
		document.getElementById('trackArtist').innerHTML = song["artist"];
	}
}

function stopAndDeselect(){
	niftyplayer('niftyPlayer1').stop();
	niftyplayer('niftyPlayer1').load("");
	
	delayedUpdate();
}

function playPauseAction(){
	if(niftyplayer('niftyPlayer1').getLoadingState() == "empty"){
		loadAndPlayFirstInQueue();
	}else{
		niftyplayer('niftyPlayer1').playToggle();
	}
}

function setHealthIndicator(image){
	document.getElementById("healthIndicator").setAttribute("src","/html/clutter/icons/"+image+".png");
}


function loadAndPlayFirstInQueue(){
	current = YAHOO.example.PlaylistTable.oDT.getRecord(0);
	if(current == null){
		stopAndDeselect();
	}else{
		request = "/get?serverid="+current.getData()["serverid"]+"&id="+current.getData()["id"];
		niftyplayer('niftyPlayer1').loadAndPlay(request);
	}
	
	delayedUpdate();
}

function playNextSong(){
	YAHOO.example.PlaylistTable.oDT.deleteRow(0);
	loadAndPlayFirstInQueue();
}

function updateButtonStates(){
	oDT = YAHOO.example.Basic.oDT;
	
	if(niftyplayer('niftyPlayer1').getPlayingState() == "playing"){
		document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/pause.png";
	}else{
		document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/play.png"; 
	}
	
	if(niftyplayer('niftyPlayer1').getLoadingState() == "empty"){
		document.getElementById('healthIndicator').src = "/html/clutter/icons/smiley.png";
		document.getElementById('stopButton').src = "/html/clutter/icons/disabled/stop.png" ;
		
		if(YAHOO.example.PlaylistTable.oDT.getRecord(0) == null){
			document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/disabled/play.png" ;
		}
	}else{
		document.getElementById('stopButton').src = "/html/clutter/icons/stop.png" ;
	}
	
	if(YAHOO.example.PlaylistTable.oDT.getRecord(0) == null){
		document.getElementById('nextButton').src = "/html/clutter/icons/disabled/next.png";
	}else{
		document.getElementById('nextButton').src = "/html/clutter/icons/next.png";
	}
	
	setCurrentlyPlaying();
}


function delete_from_playlist(id) {
	var skip = 0;
	if(YAHOO.example.PlaylistTable.oDT.getRecordIndex(id) == 0) {
		skip = 1;
		if(YAHOO.example.PlaylistTable.oDT.getRecord(1) == null)
			skip = 2;
	}
	
	YAHOO.example.PlaylistTable.oDT.deleteRow(id);
	
	if(skip == 1)
		loadAndPlayFirstInQueue();
	else if(skip == 2)
		stopAndDeselect();
}