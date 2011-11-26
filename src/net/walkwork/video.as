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
private var _remoteStreamArray:Array = null;

private var localStream:NetStream = null;
private var remoteStream:NetStream = null;

//for test
private var _conn2:NetConnection = null;
private var _group2:NetGroup = null;
private var _stream2:NetStream = null;



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
	
	_camera = Camera.getCamera("0");
	if (_camera){
		_camera.addEventListener(StatusEvent.STATUS, cameraEventHandler);
		_camera.setMode(420, 278, 15);
		_camera.setQuality(0, 85);
		
		var lcoalVideo:Video = new Video(_camera.width, _camera.height);
		lcoalVideo.attachCamera(_camera);
		localVideoDisplay.addChild(lcoalVideo);
		
		connect();
		connect2();
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
		case "NetGroup.MulticastStream.PublishNotify":
			groupMultiStreamPublishNotify(event.info.name);
			break;
		case "NetGroup.Posting.Notify":
			trace(event.info.message);
			break;		
		default:
			break;
	}
}

private function connectGroup():void {
	var groupSpec:GroupSpecifier = new GroupSpecifier(this.data.confId);
	groupSpec.multicastEnabled = true;
	groupSpec.postingEnabled = true;
	groupSpec.serverChannelEnabled = true;
	
	_group = new NetGroup(_conn, groupSpec.groupspecWithAuthorizations());
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
	trace("New stream : " + name);
	if (_remoteStreamArray == null) {
		_remoteStreamArray = new Array();
	}
	
	if (_remoteStreamArray.length >= 3){
		trace("Too many streams!");
	}
	
	_remoteStreamArray.push(name);
	
	if (_remoteStreamArray.length == 1){
		playStream(name);
	}
}

private function connectStream():void {
	var groupSpec:GroupSpecifier = new GroupSpecifier(this.data.confId);
	groupSpec.multicastEnabled = true;
	groupSpec.postingEnabled = true;
	groupSpec.serverChannelEnabled = true;
	
	localStream = new NetStream(_conn, groupSpec.groupspecWithAuthorizations());
	localStream.addEventListener(NetStatusEvent.NET_STATUS, eventHandler);
	
	remoteStream = new NetStream(_conn, groupSpec.groupspecWithAuthorizations());
	remoteStream.addEventListener(NetStatusEvent.NET_STATUS, eventHandler);
}

private function streamConnectSuccess(stream:NetStream):void {
	if (stream == localStream){
		trace("Upload local stream");
		publishVideo();
	} else if (stream == remoteStream){
		trace("Do noting for remote stream");
	} else {
		trace("Error Stream");
	}
}

private function publishVideo():void {
	localStream.attachCamera(_camera);
	localStream.publish(this.data.userId);	
}

private function playStream(name:String):void {
	var remoteVideoDisplay:VideoDisplay = this["remoteVideoDisplay"];
	var video:Video = new Video(remoteVideoDisplay.width, remoteVideoDisplay.height);
	video.smoothing = true;
	video.attachNetStream(remoteStream);
	remoteVideoDisplay.addChild(video);
	remoteStream.play(name);
}

/**
 * 
 * second connection, just for test 
 * 
 * */

private function connect2():void {
	var uri:String = "rtmfp://" + this.data.ipAddr;
	_conn2 = new NetConnection();
	_conn2.addEventListener(NetStatusEvent.NET_STATUS, eventHandler2);
	
	try{
		_conn2.connect(uri);
	}catch (e:ArgumentError){
		trace("Incorrect remote connet URL");
	}
}

private function eventHandler2(event:NetStatusEvent):void {
	trace("Net Status Event Remote : " + event.info.code);
	switch (event.info.code) {
		case "NetConnection.Connect.Success" :
			connectGroup2();
			break;
		case "NetStream.Connect.Success":
			_stream2.attachCamera(_camera);
			_stream2.publish(this.data.playId);	
			break;
		case "NetGroup.Connect.Success":
			groupConnectSuccess2();
			break;		
		case "NetGroup.Posting.Notify":
			break;
		default:
			break;
	}
}

private function connectGroup2():void {
	var groupSpec:GroupSpecifier = new GroupSpecifier(this.data.confId);
	groupSpec.multicastEnabled = true;
	groupSpec.postingEnabled = true;
	groupSpec.serverChannelEnabled = true;
	
	_group2 = new NetGroup(_conn2, groupSpec.groupspecWithAuthorizations());
	_group2.addEventListener(NetStatusEvent.NET_STATUS, eventHandler2);
}

private function groupConnectSuccess2():void {
	var groupSpec:GroupSpecifier = new GroupSpecifier(this.data.confId);
	groupSpec.multicastEnabled = true;
	groupSpec.postingEnabled = true;
	groupSpec.serverChannelEnabled = true;
	
	_stream2 = new NetStream(_conn2, groupSpec.groupspecWithAuthorizations());
	_stream2.addEventListener(NetStatusEvent.NET_STATUS, eventHandler2);
}


/**
 * 
 *
 * */
 private function disconnect():void {
	 remoteStream.close();
	 localStream.close();
	 _group.close();
	 _conn.close();
	 
	 _stream2.close();
	 _group2.close();
	 _conn2.close();
 }

