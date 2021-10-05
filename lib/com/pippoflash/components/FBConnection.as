/* FBConnection - Manages all facebook communication tools.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.utils.ULoader;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.motion.Animator;
	import 											com.pippoflash.social.FBServer;
	import 											com.pippoflash.components._cBase;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public dynamic class FBConnection extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="FB - Application ID", type=String, defaultValue="142815229063883")]
		public var _appId									:String = "142815229063883"; // The application ID
		[Inspectable 									(name="FB - Requested Permissions", type=String, defaultValue="publish_stream,read_stream,user_photos,user_photo_video_tags,user_likes")]
		public var _permissions								:String = "publish_stream,read_stream,user_photos,user_photo_video_tags,user_likes";
		[Inspectable 									(name="FB - Local Debug Token", type=String, defaultValue="142815229063883|2.qw_xhCyY9M_2LmKusbNZvw__.86400.1283817600-100001344825960|zRWduNh-51k9eH4kcuA97Aud67k.")]
		public var _debugToken							:String = "142815229063883|2.qw_xhCyY9M_2LmKusbNZvw__.86400.1283817600-100001344825960|zRWduNh-51k9eH4kcuA97Aud67k.";
		[Inspectable 									(name="FB - Startup Login", type=String, defaultValue="NONE", enumeration="NONE,SHARED OBJECT,PROMPT")]
		public var _startupLogin							:String = "NONE";
// 		[Inspectable 									(name="GUI - Link for background", type=String, defaultValue="http://www.pippoflash.com/_img/0.swf")]
// 		public var _linkBackground							:String = "http://www.pippoflash.com/_img/0.swf";
// 		[Inspectable 									(name="Margin - Internal", type=Number, defaultValue=2)]
// 		public var _intMargin								:uint = 2; // This decides a frame of the icon to go
// 		[Inspectable 									(name="Margin - External", type=Number, defaultValue=4)]
// 		public var _extMargin								:uint = 4; // This decides a frame of the icon to go
// 		[Inspectable 									(name="BG - Whole Area", type=Boolean, defaultValue=false)]
// 		public var _useAreaBg								:Boolean = false; // This decides a frame of the icon to go
// 		[Inspectable 									(name="Icon Y Offset", type=Number, defaultValue=0)]
// 		public var _yIOff									:Number = 0;
// 		[Inspectable 									(name="Icon X Offset", type=Number, defaultValue=0)]
// 		public var _xIOff									:Number = 0;
// 		[Inspectable 									(name="Button Class Name", type=String, defaultValue="PippoFlashAS3_Components_PippoFlashButton_Default")]
// 		public var _buttonLinkage							:String = "PippoFlashAS3_Components_PippoFlashButton_Default";
// 		[Inspectable 									(name="Text", type=String, defaultValue="PippoFlash.com")]
// 		public var _text									:String = "PippoFlash.com";
// 		[Inspectable 									(name="Text Alignment", type=String, defaultValue="CENTER", enumeration="CENTER,JUSTIFY,LEFT,RIGHT")]
// 		public var _textAlign								:String = "CENTER";
// 		[Inspectable 									(name="Is Radio Group (overrides switch)", type=String)]
// 		public var _radioGroup								:String;
// 		[Inspectable 									(name="FB - Auto", type=Boolean, defaultValue=false)]
// 		public var _closeOnRollOut							:Boolean = false;
// 		[Inspectable 									(name="Text Y Offset", type=Number, defaultValue=0)]
// 		public var _yOff									:Number = 0;
// 		[Inspectable 									(name="Text X Offset", type=Number, defaultValue=0)]
// 		public var _xOff									:Number = 0;
// 		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
// 		public var _textMargin								:Number = 4;
// 		[Inspectable 									(name="Direction", type=String, defaultValue="VERTICAL", enumeration="VERTICAL,HORIZONTAL")]
// 		public var _direction								:String = "VERTICAL";
// 		[Inspectable 									(name="Align - Vertical", type=String, defaultValue="MIDDLE", enumeration="TOP,MIDDLE,BOTTOM")]
// 		public var _alignV									:String = "MIDDLE";
// 		[Inspectable 									(name="Align - Horizontal", type=String, defaultValue="CENTER", enumeration="LEFT,CENTER,RIGHT")]
// 		public var _alignH									:String = "CENTER";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _words							:Object = {FBNoName:"Senza Titolo", FBRefreshing:"aggiorno i messaggi", FBShare:"Condividi...", FBSend:"Commenta...", FBConnecting:"accesso a facebook", FBNotConnected:"non sei connesso a facebook", FBConnected:"", FBHello:"Ciao", FBPage:"carico la pagina", FBLink:"Visita la pagina su facebook."};
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		private static var _cb								:FBCommentBox;
		// FOOL COMPONENT COMPILER ///////////////////////////////////////////////////////////////////////////////////////
		//var _buttConnect, _buttShare, _buttSend, _commentBg, _inputTxt, _profileTxt, _contentBox, _scrollBar, _profilePic, _infoTxt;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		private var _server								:FBServer = new FBServer(this);
		private var _shieldRect								:Rectangle; // This is used to tell ULoader the size of shield to use in this component
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		private var _boxContent							:MovieClip = new MovieClip();
		private var _feeds								:Vector.<FBCommentBox> = new Vector.<FBCommentBox>();
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		private var _user									:Object;
		private var _userId								:String;
		private var _xml									:XML;
		private var _targetType							:String; // Type of any target object - page, album, photo-image-pic
		private var _targetId								:String; // ID of any target object
		private var _targetData							:Object; // Object main data
		private var _targetFeed							:Array; // List of feed or comments
		private var _targetLink								:String; // The facebook link of the selected content
		private var _targetTitle							:String; // Title of object depending on kind and what
		private var _settingsXml							:XML; // Stores settings xml
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _status								:String = "IDLE"; // IDLE, SETUP - after I have set an application,
		private var _isLogged								:Boolean = false;
		private var _hasContent							:Boolean = false;
// INIT ONCE ///////////////////////////////////////////////////////////////////////////////////////
		public function FBConnection							(id:String="FBConnection", par:Object=null) {
			super									(id, par);
		}
		protected override function init						():void {
			scaleX = scaleY								= 1; // This component is NOT RESIZABLE
			super.init									();
			_w = 300; _h = 481;
			initializeAssets								();
			_shieldRect									= new Rectangle(0,0,_w,_h); // setup rectangle dimensions for shielding
		}
		private function initializeAssets						():void {
			_server.setErrorFunction						(onFacebookError);
			Buttonizer.autoButtons						([_buttConnect, _buttShare, _buttSend, _buttClose], this);
			
			UMem.addClass								(FBCommentBox);
			shutDownAllVisible							();
		}
		protected override function initialize					():void {
			super.initialize								();
			if (_startupLogin == "SHARED OBJECT") {
				autoConnect							();
			}
			if (_startupLogin == "PROMPT") {
				connect								();
			}
		}
// LOGIN METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function initializeConnection						(appId:String=null, permissions:String=null):void {
			if (!isReady())								return; // This can be called ONLY when status is READY
			Debug.debug								(_debugPrefix, "Initializing connection to app:",appId);
			_server._debugToken							= _debugToken;
			_server.setAppId								(appId ? appId : _appId, permissions ? permissions : _permissions);
			updateVisibility								("SETUP");
			super.complete								(); // This sets status to complete so that I am not initialized again
		}
		public function setXml								(xx:XML):void {
			Debug.debug								(_debugPrefix, "Set XML:",xx.toXMLString());
			_settingsXml								= xx;
			initializeConnection							(xx.@appId);
		}
		public function autoConnect							():void { // Performs auto-connect with id stored in flash cookie (not good practice, I may logout from fb but someone else still use my connection)
			initializeConnection							();
			_server.autoLogin							();
			setToLogging								();
		}
		public function connect							():void { // Connects to FB
			initializeConnection							();
			_server.login								();
			setToLogging								();
		}
			public function onUserLogged					(user:Object):void {
				_user									= user;
				_userId								= _user.id;
				setToLogged							();
				//renderPage								("132611793440839");
				//renderAlbum							("132612140107471");
			}
			public function onFacebookError					():void {
				if (_status == "LOGIN") {
					_isLogged							= false;
					updateVisibility							("IDLE");
				}
			}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function login								():void {
			_server.login								();
			setToLogging								();
		}
		public function renderPage							(id:String):void {
			doRenderPage								(id);
		}
		public function renderAlbum							(id:String):void {
			doRenderAlbum								(id);
		}
		public function renderXml							(xx:XML):void {
			_xml										= xx;
			render									(_xml.@id, _xml.@type);
		}
		public function render								(id:String, type:String):void {
			setLoader									(true);
			resetContent								();
			_targetId									= id;
			_targetType								= type;
			Debug.debug								(_debugPrefix, "Rendering",type,id);
			if (_targetType == "page")						renderPage(id);
			else if (_targetType == "album")					renderAlbum(id);
			else 										renderAlbum(id); // This is good for photos (stuff thta already have comments inside)
		}
		public function getInfo								():String {
			var s										:String = "Nessun contenuto.";
			if (_hasContent) {
				s 									= _targetTitle;
				s 									+= _feeds.length == 0 ? "\nnessun commento." : ("\n" + _feeds.length + (_feeds.length > 1 ? " commenti." : "commento."));
			}
			return									s;
		}
		public function stopCall							():void {
			// this stops whatever call the system was doing
			_server.resetCommads							();
			resetContent								();
		}
		public function resetContent							():void {
			_infoTxt.text = ""; _xml = null; _targetType = null; _targetId = null; _hasContent = false;
			setLoader									(false);
			resetFeeds									();
		}
// STATUSES ///////////////////////////////////////////////////////////////////////////////////////
		private function setToLogging						():void {
// 			updateVisibility								("LOGIN");
// 			shutDownAllVisible							();
			setLoader									(true);
		}
		private function setToLogged						():void {
			_isLogged									= true;
			_profilePic.loadImage							(_server.getProfileThumbUrl(_userId));
			_profileTxt.text								= _words.FBHello+",\n"+ _user.name;
			broadcastEvent								("onFacebookLogged", this);
			updateVisibility								();
			activateComment								();
			setLoader									(false);
		}
		private function setToPage							():void {
			// This presuppose I have alreayd loaded everything about the page
			_targetTitle								= (_targetData.name?_targetData.name:_words.FBNoName);
			_infoTxt.htmlText								= _targetTitle+"<br/><u><a target='_blank' href='"+_targetData.link+"'>"+_words.FBLink+"</a></u>";
			_targetLink									= _targetData.link;
			_hasContent								= true;
			updateVisibility								("PAGE");
			renderFeeds								();
			activateComment								();
			broadcastEvent								("onFacebookRendered", this);
			setLoader									(false);
		}
		private function setToAlbum							():void {
			_targetTitle								= (_targetData.name?_targetData.name:_targetData.from.name);
			_infoTxt.htmlText								= _targetTitle+"<br/><u><a target='_blank' href='"+_targetData.link+"'>"+_words.FBLink+"</a></u>";
			_targetLink									= _targetData.link;
			_hasContent								= true;
			updateVisibility									("ALBUM");
			renderFeeds								();
			broadcastEvent								("onFacebookRendered", this);
			activateComment								();
			setLoader									(false);
		}
// VISIBILITY ///////////////////////////////////////////////////////////////////////////////////////
		private function shutDownAllVisible					():void {
			// Suts down all components that may or may be not visible
			_buttConnect.visible = _buttShare.visible = _buttSend.visible = _commentBg.visible = _inputTxt.visible = _profileTxt.visible = _contentBox.visible = _scrollBar.visible = _profilePic.visible = _infoTxt.visible = false;
		}
		private function updateVisibility						(status:String=null):void {
			if (status)									_status = status;
			// Update visibility
			shutDownAllVisible							();
// 			setLoader									(false);
			_profileTxt.visible = _profilePic.visible 				= _isLogged;
			_buttConnect.visible							= !_isLogged;
			_infoTxt.visible								= true;
			_contentBox.visible = _scrollBar.visible				= _hasContent;
			activateComment								();
		}
// SHARE ///////////////////////////////////////////////////////////////////////////////////////
		private function doShareContent						():void {
			_server.shareLink								(_userId, _targetLink, {_okFunc:onShareOk});
		}
			public function onShareOk						(o:Object):void {
				Debug.debug							(_debugPrefix, "Sharing OK");
			}
// COMMENTS ///////////////////////////////////////////////////////////////////////////////////////		
		private function activateComment						():void {
			_buttShare._txt.text = _words.FBShare; _buttSend._txt.text = _words.FBSend; _inputTxt.text = "";
			_buttShare.visible = _buttSend.visible = _commentBg.visible = _inputTxt.visible = _isLogged && _hasContent;
		}
		private function hideComment						():void {
			_buttShare.visible = _buttSend.visible = _commentBg.visible = _inputTxt.visible = false;
		}
		private function doSendComment						():void {
			var txt									:String = UText.stripSpaces(_inputTxt.text);
			if (txt.length < 2) 							UGlobal.setFocus(_inputTxt);
			else if (_status == "PAGE")						_server.postFeed(_targetId, txt, {_okFunc:onFeedPosted, _hasLoader:false, _errorFunc:onCommentError, _networkErrorFunc:onCommentError});
			else 										_server.postComment(_targetId, txt, {_okFunc:onCommentPosted, _hasLoader:false, _errorFunc:onCommentError, _networkErrorFunc:onCommentError});
		}
			public function onFeedPosted					(o:Object):void {
				setLoader								(true);
				resetFeeds								();
				hideComment							();
				setTimeout								(updateFeed, 1000);
			}
			public function onCommentPosted					(o:Object):void {
				setLoader								(true);
				resetFeeds								();
				hideComment							();
				setTimeout								(updateComments, 1000);
			}
			public function onCommentError					(o:Object=null):void {
				broadcastEvent							("onPostCommentError", this);
			}
// ALBUM ///////////////////////////////////////////////////////////////////////////////////////
		
		private function doRenderAlbum						(id:String):void {
			_server.getAllData							(_targetId, {_okFunc:onAlbumData, _loadText:_words.FBPage, _hasLoader:false});
		}
			public function onAlbumData						(o:Object):void {
				// Rendering page data, loading feed
				_targetData							= o;
				updateComments							();
			}
// PAGE ///////////////////////////////////////////////////////////////////////////////////////
		private function doRenderPage						(id:String):void {
			_server.getAllData							(_targetId, {_okFunc:onPageData, _loadText:_words.FBPage, _hasLoader:false});
		}
			public function onPageData						(o:Object):void {
				// Rendering page data, loading feed
				_targetData							= o;
				updateFeed							();
			}
// COMMENTS ///////////////////////////////////////////////////////////////////////////////////////
			public function updateComments					():void {
				_server.getComments						(_targetId, {_okFunc:onComments, _loadText:_words.FBPage, _hasLoader:false});
			}
				public function onComments					(o:Object):void {
					_targetFeed						= o._list;
					setToAlbum							();
					if (_targetFeed.length)					_contentBox.scrollToBottom();
				}
// FEED ///////////////////////////////////////////////////////////////////////////////////////
			public function updateFeed						():void {
				_server.getFeed							(_targetId, {_okFunc:onPageFeed, _loadText:_words.FBPage, _hasLoader:false});
			}
				public function onPageFeed					(o:Object):void {
					_targetFeed						= o._list;
					setToPage							();
					if (_targetFeed.length)					_contentBox.scrollToTop();
				}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
			private function renderFeeds						():void {
				if (_targetFeed.length == 0)					return;
				_boxContent							= new MovieClip();
				var dist								:Number = 0;
				var t									:String;
				for each (_o in _targetFeed) {
					_cb								= UMem.getInstance(FBCommentBox);
					_cb._txt.autoSize					= "center";
					t								= "";
					t								+= "<img vspace='0' hspace='5' width='50' height='50' src='"+_server.getProfileThumbUrl(_o.from.id)+"'>";
					t								+= "<font size='12' color='#334c84'>" + _o.from.name + "</font><br/>";
					t								+= _o.message ? "<font size='10' color='#000000'>" + _o.message + "</font><br/>" : ""; 
					_cb._txt.htmlText					= t;
					_cb.y								= dist;
					_cb._bg.scaleY						= 1;
					_cb._bg.height 						= _cb._txt.height + 10;
					if (_cb._bg.height < 58)				_cb._bg.height = 58;
					dist								+= _cb.height;
					_boxContent.addChild					(_cb);
					_feeds.push						(_cb);
				}
				_contentBox.setContent					(_boxContent);
				_contentBox.visible						= true;
			}
			private function resetFeeds						():void {
// 				UDisplay.removeClip						(_boxContent);
				UMem.storeInstanceList					(_feeds);
				_contentBox.release						();
				_contentBox.visible						= false;
				_scrollBar.visible							= false;
				_feeds								= new Vector.<FBCommentBox>();
			}
			public function setLoader						(v:Boolean):void {
				ULoader.setComponentLoader				(this, v, "", true);
			}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressConnect						(c:MovieClip=null) {
			login										();
		}
		public function onPressSend							(c:MovieClip=null) {
			doSendComment								();
		}
		public function onPressShare							(c:MovieClip=null) {
			doShareContent								();
		}
		public function onServerCall							(o):void {
			
		}
		public function onServerFeedback						(o):void {
			
		}
		public function onPressClose							(c:MovieClip=null) {
			broadcastEvent								("onFacebookClose");
		}
	}
}