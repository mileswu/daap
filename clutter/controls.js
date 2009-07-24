var songSound;
soundManager.url="/html/clutter/soundmanager/swf/"
var currentRecord = {};

function addToQueueFromRecord(oRecord){
	YAHOO.example.PlaylistTable.oDT.addRow({id:oRecord.getData("id"), serverid:oRecord.getData("serverid"), title:oRecord.getData("title"), album:oRecord.getData("album"), artist:oRecord.getData("artist")});

	if(YAHOO.example.PlaylistTable.oDT.getRecordSet().getLength() == 1) {
		YAHOO.example.PlaylistTable.oDT.selectRow(0);
	}

}


YAHOO.util.Event.addListener(window, "load", function() {
	delayedUpdate();
});

function setVolume1(vol) {
	if(soundManager.getSoundById('songSound') != null){
		songSound.setVolume(vol);
	}

	soundManager.defaultOptions['volume'] = vol;
}


function delayedUpdate(){
	setTimeout(updateButtonStates,110);
	setTimeout(updateButtonStates,250);
	setTimeout(updateButtonStates,325);
	setTimeout(updateButtonStates,650);
	setTimeout(updateButtonStates,1050);
	setTimeout(updateButtonStates,1400);
	setTimeout(updateButtonStates,1900);
}


function setCurrentlyPlaying(){//Have to assume that either queue[0] is playing, or nothing is.
	if(soundManager.getSoundById('songSound') == null){
		document.getElementById('trackTitle').innerHTML = "";
		document.getElementById('trackAlbum').innerHTML = "";
		document.getElementById('trackArtist').innerHTML = "";
	}else{
		var song =  getCurrentSelected().getData();
		document.getElementById('trackTitle').innerHTML = song["title"];
		document.getElementById('trackAlbum').innerHTML = song["album"];
		document.getElementById('trackArtist').innerHTML = song["artist"];
	}
}

function stopAndDeselect(){
	var r = getCurrentSelected();
	if(r) {
		YAHOO.example.PlaylistTable.oDT.unselectRow(YAHOO.example.PlaylistTable.oDT.getRecordIndex(r));
	}
	
	songSound.destruct()
	currentRecord = {};
	delayedUpdate();
}

function playPauseAction(){
	if(soundManager.getSoundById('songSound') == null){
		loadAndPlay();
	}
	else {
		songSound.togglePause();
	}
}

function getCurrentSelected() {
	var rid = YAHOO.example.PlaylistTable.oDT.getSelectedRows()[0]
	if(rid)
		return YAHOO.example.PlaylistTable.oDT.getRecord(rid);
	else
		return null;
}

function loadAndPlay() {
	var current = getCurrentSelected();
	if(current == null) {
		stopAndDeselect();
		return;
	}
	var cdata = current.getData();
	if(currentRecord["id"] == cdata["id"] && currentRecord["serverid"] == cdata["serverid"] && currentRecord["rid"] == current.getId())
		 return;
	currentRecord = cdata;
	currentRecord["rid"] = current.getId();

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
			onfinish:function (){playRelSong(1);}
		})

		songSound.play()

	delayedUpdate();
}

function playRelSong(diff) {
	var r = getCurrentSelected();
	if(r == null)
		return;
	var index = YAHOO.example.PlaylistTable.oDT.getRecordIndex(r);
	YAHOO.example.PlaylistTable.oDT.unselectRow(index);
	YAHOO.example.PlaylistTable.oDT.selectRow(index+diff);
	if((index+diff+1) > YAHOO.example.PlaylistTable.oDT.getRecordSet().getLength())
		stopAndDeselect();
	else if((index+diff) < 0)
		stopAndDeselect();
	else
		YAHOO.example.PlaylistTable.oDT.selectRow(index+diff);
}

function updateButtonStates(){
	oDT = YAHOO.example.PlaylistTable.oDT;

	if(soundManager.getSoundById('songSound') == null){

		document.getElementById('stopButton').src = "/html/clutter/icons/disabled/stop.png"
		document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/disabled/play.png"

		YAHOO.example.SongPositionSlider.autoSetMax(0);
		YAHOO.example.SongPositionSlider.autoSetValue(0);


	}else{
		document.getElementById('stopButton').src = "/html/clutter/icons/stop.png"

		//Are we already paused?
		if(songSound.paused == true){document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/play.png"}
		else{document.getElementById('playPauseToggleButton').src = "/html/clutter/icons/pause.png"}
	}


	if(getCurrentSelected() != null){
		document.getElementById('nextButton').src = "/html/clutter/icons/next.png"
		document.getElementById('previousButton').src = "/html/clutter/icons/previous.png"
	}else{
		document.getElementById('nextButton').src = "/html/clutter/icons/disabled/next.png"
		document.getElementById('previousButton').src = "/html/clutter/icons/disabled/previous.png"
	}

	setCurrentlyPlaying();
}

function loadAndPlayingCallback(){
	durationEstimate = songSound.duration*songSound.bytesTotal/songSound.bytesLoaded

	YAHOO.example.SongPositionSlider.autoSetMax((songSound.duration/durationEstimate)*100);
	YAHOO.example.SongPositionSlider.autoSetValue((songSound.position/durationEstimate)*100);
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
			//YAHOO.example.SongPositionSlider.setValue((songSound.position/durationEstimate)*100, true, true, true)
		}
	}
}

function delete_from_playlist(id) {
	var r = getCurrentSelected();
	var rindex = YAHOO.example.PlaylistTable.oDT.getRecordIndex(r);

	YAHOO.example.PlaylistTable.oDT.deleteRow(id);

	if(r.getId() == id) {
		stopAndDeselect();
		YAHOO.example.PlaylistTable.oDT.selectRow(rindex);
	}
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
	var cur = getCurrentSelected();
	var newpos;
	
	if(is_up == 1)
		newpos = pos - 1;
	else
		newpos = pos + 1;
	
	YAHOO.example.PlaylistTable.oDT.deleteRow(id);
	YAHOO.example.PlaylistTable.oDT.addRow(record, newpos);
	if(cur.getId() == id)	{
		currentRecord["rid"] = YAHOO.example.PlaylistTable.oDT.getRecord(newpos).getId();
		YAHOO.example.PlaylistTable.oDT.selectRow(newpos);
	}
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