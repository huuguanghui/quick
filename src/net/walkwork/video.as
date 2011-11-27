// ActionScript file

import flash.events.NetStatusEvent;
import flash.events.StatusEvent;
import flash.media.Camera;
import flash.media.CameraUI;
import flash.media.StageVideo;
import flash.media.Video;
import flash.net.GroupSpecifier;
import flash.net.NetConnection;
import flash.net.NetGroup;
import flash.net.NetStream;

import spark.components.VideoDisplay;

private var _camera:Camera = null;

private var _conn:NetConnection = null;
private var _group:NetGroup = null;
private var _groupSpec:GroupSpecifier = null;
private var _remoteStreamArray:Array = null;

private var localStream:NetStream = null;
private var remoteStream:NetStream = null;

private var _isRemoteStreamConnected:Boolean = false;
private var _currentRemoteStream:String = null;


private function init():void{
	
	if (Camera.names.length > 0) { 
		trace("User has at least one camera installed."); 
	} else { 
		trace("User has no cameras installed."); 
	}
	
	
//	var v:Vector.<StageVideo> = this.stage.stageVideos;       
//	var sv:StageVideo;       
//	if ( v.length >= 1 )       
//	{    
//		trace("get state video");
//		sv = v[0];       
//	}
	
	var localVideoDisplay:VideoDisplay = this["lcoalVideoDisplay"];
	
	_camera = Camera.getCamera(this.data.playId);
	if (_camera){
		_camera.addEventListener(StatusEvent.STATUS, cameraEventHandler);
		_camera.setMode(420, 278, 15);
		_camera.setQuality(0, 85);
		
		var lcoalVideo:Video = new Video(_camera.width, _camera.height);
		lcoalVideo.attachCamera(_camera);
		localVideoDisplay.addChild(lcoalVideo);
		
		_groupSpec = new GroupSpecifier(this.data.confId);
		_groupSpec.multicastEnabled = true;
		_groupSpec.postingEnabled = true;
		_groupSpec.serverChannelEnabled = true;
		
		connect();
	}
}

private function cameraEventHandler(event:StatusEvent):void {
	trace("Event:" + event.code);
}


private function connect():void {
	var uri:String = "rtmfp://" + this.data.ipAddr;
	_conn = new NetConnection();
	_conn.addEventListener(NetStatusEvent.NET_STATUS, eventHandler);
	
	try{
		_conn.connect(uri);
	}catch (e:ArgumentError){
		trace("Incorrect connet URL");
	}
}

private function eventHandler(event:NetStatusEvent):void {
	trace("Net Status Event : " + event.info.code);
	switch (event.info.code) {
		case "NetConnection.Connect.Success":
			connectGroup();
			break;
		case "NetGroup.Connect.Success":
			groupConnectSuccess(event.info.group);
			break;		
		case "NetStream.Connect.Success":
			streamConnectSuccess(event.info.stream);
			break;
		
		//net group events
		case "NetGroup.MulticastStream.PublishNotify":
			groupMultiStreamPublishNotify(event.info.name);
			break;
		case "NetGroup.MulticastStream.UnpublishNotify":
			groupMultiStreamUnPublishNotify(event.info.name);
			break;
		case "NetGroup.Posting.Notify":
			trace(event.info.message);
			break;	
		
		//net stream events
		case "NetStream.MulticastStream.Reset":
			break;
		
		//deault
		default:
			break;
	}
}

private function connectGroup():void {
	_group = new NetGroup(_conn, _groupSpec.groupspecWithAuthorizations());
	_group.addEventListener(NetStatusEvent.NET_STATUS, eventHandler);
}

private function groupConnectSuccess(group:NetGroup):void {
	if (group != _group) {
		trace("Error Group");
		return;
	}
	
	if (group.estimatedMemberCount >= 4){
		trace("estimatedMemberCount : " + group.estimatedMemberCount);
		return;
	}
	
	connectStream();
}

private function groupMultiStreamPublishNotify(name:String):void {
	trace("Notif: stream " + name + " published.");
	if (_remoteStreamArray == null) {
		_remoteStreamArray = new Array();
	}
	
	if (_remoteStreamArray.length >= 3){
		trace("Too many streams!");
	}
	
	_remoteStreamArray.push(name);
	
	playRemoteStream(0);
}

private function groupMultiStreamUnPublishNotify(name:String):void {
	trace("Notify: stream " + name + " unpublished.");
	if (_remoteStreamArray == null) {
		_remoteStreamArray = new Array();
		return;
	}
	
	for(var i:int=0; i<_remoteStreamArray.length; i++){
		if (name == _remoteStreamArray[i]) {
			_remoteStreamArray.splice(i, 1);
			break;
		}
	}
	
	if (_currentRemoteStream == name){
		playRemoteStream(0);
	}
}

private function connectStream():void {
	localStream = new NetStream(_conn, _groupSpec.groupspecWithAuthorizations());
	localStream.addEventListener(NetStatusEvent.NET_STATUS, eventHandler);
	
	remoteStream = new NetStream(_conn, _groupSpec.groupspecWithAuthorizations());
	remoteStream.addEventListener(NetStatusEvent.NET_STATUS, eventHandler);		
}

private function streamConnectSuccess(stream:NetStream):void {
	if (stream == localStream){
		trace("Upload local stream");
		publishLocalVideo();
	} else if (stream == remoteStream){
		trace("Init remote stream");
		_isRemoteStreamConnected = true;
		initRemoteVideo();		
	} else {
		trace("Error Stream");
	}
}

private function publishLocalVideo():void {
	trace("Publish stream : " + this.data.userId);
	localStream.attachCamera(_camera);
	localStream.publish(this.data.userId);	
}

private function initRemoteVideo():void {
	var remoteVideoDisplay:VideoDisplay = this["remoteVideoDisplay"];
	var video:Video = new Video(remoteVideoDisplay.width, remoteVideoDisplay.height);
	video.smoothing = true;
	video.attachNetStream(remoteStream);
	remoteVideoDisplay.addChild(video);
	
	playRemoteStream(0);
}

private function playRemoteStream(index:int):void {
	if (!_isRemoteStreamConnected) {
		trace("Remote stream is not connected.");
		return;
	}
	
	if (null == _remoteStreamArray || _remoteStreamArray.length <=0 ){
		trace("Nothing to play.");
		return;
	}
	
	_currentRemoteStream = _remoteStreamArray[index];
	remoteStream.play(_remoteStreamArray[index]);
}


/**
 * 
 *
 * */
 private function disconnect():void {
	 if (null != remoteStream)	 remoteStream.close();
	 if (null != localStream)	 localStream.close();
	 if (null != _group)        _group.close();
	 if (null != _conn)         _conn.close();
 }

