var songSound;

function addToQueueFromRecord(oRecord){
	YAHOO.example.PlaylistTable.oDT.addRow({id:oRecord.getData("id"), serverid:oRecord.getData("serverid"), title:oRecord.getData("title"), album:oRecord.getData("album"), artist:oRecord.getData("artist")});


	if(YAHOO.example.PlaylistTable.oDT.getRecordSet().getLength() == 1){
		loadAndPlayFirstInQueue();
	}

	delayedUpdate();
}


YAHOO.util.Event.addListener(window, "load", function() {


	delayedUpdate();
});

function setVolume1(vol) {
	if(soundManager.getSoundById('songSound') != null){
		songSound.setVolume(vol);
	}
}


function delayedUpdate(){
	//updateButtonStates()
	setTimeout(updateButtonStates,110);
	setTimeout(updateButtonStates,250);
	setTimeout(updateButtonStates,325);
}

function setCurrentlyPlaying(){//Have to assume that either queue[0] is playing, or nothing is.
	if(soundManager.getSoundById('songSound') == null){
		function setCurrentlyPlaying(){//Have to assume that either queue[0] is playing, or nothing is.
			if(soundManager.getSoundById('songSound') == null){
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
	}
}

function stopAndDeselect(){
	songSound.destruct()

	delayedUpdate();
}

function playPauseAction(){
	if(soundManager.getSoundById('songSound') == null){//Check This Line, destroy() behaviour unknown
		loadAndPlayFirstInQueue();
	}else{
		songSound.togglePause()
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
		if(soundManager.getSoundById('songSound') != null){
			songSound.destruct()
		}
		request = "/get?serverid="+current.getData()["serverid"]+"&id="+current.getData()["id"];
		songSound = soundManager.createSound({
			id: 'songSound',
			url: request,
			onplay:delayedUpdate,
			onpause:delayedUpdate,
			onresume:delayedUpdate,
			onstop:delayedUpdate,
			whileplaying:loadAndPlayingCallback,
			whileloading:loadAndPlayingCallback,
			onfinish:playNextSong
		})


		songSound.play()
	}

	delayedUpdate();
}

function playNextSong(){
	YAHOO.example.PlaylistTable.oDT.deleteRow(0);
	loadAndPlayFirstInQueue();
}

function updateButtonStates(){
	oDT = YAHOO.example.PlaylistTable.oDT;

	topOfThePlaylist = oDT.getRecord(0);

	if(soundManager.getSoundById('songSound') == null){

		document.getElementById('stopButton').src = "/html/clutter/icons/disabled/stop.png"

		//Can we start the playlist though?
		if(topOfThePlaylist != null){document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/play.png"}
		else{document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/disabled/play.png"}
				
		YAHOO.example.SongPositionSlider.autoSetMax(0);
		YAHOO.example.SongPositionSlider.autoSetValue(0);
		

	}else{
		document.getElementById('stopButton').src = "/html/clutter/icons/stop.png"

		//Are we already paused?
		if(songSound.paused == true){document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/play.png"}
		else{document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/pause.png"}
	}

	if(topOfThePlaylist != null){document.getElementById('nextButton').src = "/html/clutter/icons/next.png"}
	else{document.getElementById('nextButton').src = "/html/clutter/icons/disabled/next.png"}

	setCurrentlyPlaying();
}

function loadAndPlayingCallback(){
	durationEstimate = songSound.duration*songSound.bytesTotal/songSound.bytesLoaded

	//alert(Math.round((songSound.duration/durationEstimate)*100));
	YAHOO.example.SongPositionSlider.autoSetMax((songSound.duration/durationEstimate)*100);
	YAHOO.example.SongPositionSlider.autoSetValue((songSound.position/durationEstimate)*100);
	//YAHOO.example.SongPositionSlider.setValues(Math.round((songSound.position/durationEstimate)*100), Math.round((songSound.duration/durationEstimate)*100), true, true, true)
}


function setPositionAsPercent(percent){
	if(soundManager.getSoundById('songSound') == null){
		YAHOO.example.SongPositionSlider.setMinValue((songSound.position/durationEstimate)*100, true, true, true)
	}else{
		durationEstimate = songSound.duration*songSound.bytesTotal/songSound.bytesLoaded
		targetPosition = durationEstimate*percent/100
		//Can only seek within loaded sound data, as defined by the duration property.
		if(targetPosition < songSound.duration){
			songSound.setPosition(targetPosition)
			}else{//Sorry
				YAHOO.example.SongPositionSlider.setMinValue((songSound.position/durationEstimate)*100, true, true, true)
			}
		}
	}


	/* */

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

	function move(id, is_up) {
		var pos = YAHOO.example.PlaylistTable.oDT.getRecordIndex(id);
		var length = YAHOO.example.PlaylistTable.oDT.getRecordSet().getLength()
		if(pos == 0 && is_up == 1) //top
		return;
		if(pos == (length-1) && is_up == 0) //bottom
		return;
		if(length < 2)
		return;

		var record = YAHOO.example.PlaylistTable.oDT.getRecord(id).getData();
		delete_from_playlist(id);

		if(is_up == 1)
		{
			YAHOO.example.PlaylistTable.oDT.addRow(record, pos - 1);
			if(pos == 1) //reached the top
			loadAndPlayFirstInQueue();
		}
		else
		YAHOO.example.PlaylistTable.oDT.addRow(record, pos + 1);
	}
	function delete_daap(index) {
		var id = YAHOO.example.Servers.oDT.getRecord(index).getData("id");

		var add_remove_callback = function(o)
		{ YAHOO.example.Servers.oDT.requery(""); }

		var callback = {
			success: add_remove_callback,
			failure: add_remove_callback,
			argument: { }
		};

		var request = YAHOO.util.Connect.asyncRequest('GET', "/delete?id=" + id, callback);
	}

	function add_daap(add, nick) {
		var add_remove_callback = function(o) {
			YAHOO.example.Servers.oDT.requery("");
		}

		var callback = {
			success: add_remove_callback,
			failure: add_remove_callback,
			argument: { }
		};

		var request = YAHOO.util.Connect.asyncRequest('GET', "/add?address=" + add + "&nickname=" + nick, callback);
		YAHOO.example.Servers.oDT.requery("");
	}
