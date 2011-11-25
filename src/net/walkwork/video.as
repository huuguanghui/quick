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

private var lcoalConn:NetConnection = null;
private var localCamera:Camera = null;
private var localStream:NetStream = null;


private var remoteConn:NetConnection = null;
private var remoteStream:NetStream = null;


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
	
	localCamera = Camera.getCamera("0");
	if (localCamera){
		localCamera.addEventListener(StatusEvent.STATUS, eventHandler);
		localCamera.setMode(420, 278, 15);
		localCamera.setQuality(0, 85);
		
		var lcoalVideo:Video = new Video(localCamera.width, localCamera.height);
		lcoalVideo.attachCamera(localCamera);
		localVideoDisplay.addChild(lcoalVideo);
		
		localConnect();
	}
	
}

private function eventHandler(event:StatusEvent):void {
	trace("Event:" + event.code);
}


private function localConnect():void {
	var uri:String = "rtmfp://" + this.data.ipAddr;
	lcoalConn = new NetConnection();
	lcoalConn.addEventListener(NetStatusEvent.NET_STATUS, localConnectionHandler);
	
	try{
		lcoalConn.connect(uri);
	}catch (e:ArgumentError){
		trace("Incorrect connet URL");
	}
}

private function localConnectionHandler(event:NetStatusEvent):void {
	trace("Net Status Event: " + event.info.code);
	switch (event.info.code) {
		case "NetConnection.Connect.Success" :
			initLocalStreamAndGroup();
			break;
		case "NetStream.Connect.Success":
			publishLocalVideo();
			remoteConnect();
			break;
		default:
			break;
	}
}

private function initLocalStreamAndGroup():void {
	
	var groupSpec:GroupSpecifier = new GroupSpecifier(this.data.confId);
	groupSpec.multicastEnabled = true;
	groupSpec.postingEnabled = true;
	groupSpec.serverChannelEnabled = true;
	
	localStream = new NetStream(lcoalConn, groupSpec.groupspecWithAuthorizations());
	var group:NetGroup = new NetGroup(lcoalConn, groupSpec.groupspecWithAuthorizations());
}

private function publishLocalVideo():void {
	
	localStream.attachCamera(localCamera);
	localStream.publish(this.data.userId);	
}

/**
 * 
 * remote connection 
 * 
 * */

private function remoteConnect():void {
	var uri:String = "rtmfp://" + this.data.ipAddr;
	remoteConn = new NetConnection();
	remoteConn.addEventListener(NetStatusEvent.NET_STATUS, remoteConnectionHandler);
	
	try{
		remoteConn.connect(uri);
	}catch (e:ArgumentError){
		trace("Incorrect remote connet URL");
	}
}

private function remoteConnectionHandler(event:NetStatusEvent):void {
	trace("Net Status Event: " + event.info.code);
	switch (event.info.code) {
		case "NetConnection.Connect.Success" :
			initRemoteStreamAndGroup();
			break;
		case "NetStream.Connect.Success":
			playRemoteStream();
			break;
		default:
			break;
	}
}

private function initRemoteStreamAndGroup():void {
	
	var groupSpec:GroupSpecifier = new GroupSpecifier(this.data.confId);
	groupSpec.multicastEnabled = true;
	groupSpec.postingEnabled = true;
	groupSpec.serverChannelEnabled = true;
	
	remoteStream = new NetStream(remoteConn, groupSpec.groupspecWithAuthorizations());
	var group:NetGroup = new NetGroup(remoteConn, groupSpec.groupspecWithAuthorizations());
}

private function playRemoteStream():void {
	
	var remoteVideoDisplay:VideoDisplay = this["remoteVideoDisplay"];
	var video:Video = new Video(remoteVideoDisplay.width, remoteVideoDisplay.height);
	video.smoothing = true;
	video.attachNetStream(remoteStream);
	remoteVideoDisplay.addChild(video);
	remoteStream.play(this.data.playId);
}

/**
 * 
 *
 * */
 private function disconnect():void {
	 localStream.close();
	 lcoalConn.close();
	 
	 remoteStream.close();
	 remoteConn.close();
 }

