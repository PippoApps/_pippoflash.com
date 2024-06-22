package 
{
	import com.pippoflash.utils.*;
	import com.pippoflash.components.*;
	import com.pippoflash.motion.PFTouchTransform;
	import flash.display.*;
	import flash.geom.*;;
	import framework._MainAppBaseStarling;
	import com.pippoflash.media.PFVideo;
	import com.pippoflash.framework.starling.StarlingApp;
	import com.pippoflash.framework.air.LocalContentUpdater;
	
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public dynamic class TestAirLocalContentUpdate extends _MainAppBaseStarling
	{
		
		private var _cbt:ContentBoxTouch;
		private var _pfTouchView:PFTouchTransform;
		private var _sprite:Sprite;
		private var _bgVideo:PFVideo;
		
		
		public function TestAirLocalContentUpdate(id:String="TestAirVideoInVideo", appId:String="Test TestAirVideoInVideo for PippoApps", appVer:String="0.00") 
		{
			super(id, appId, appVer);
			DEBUG = true;
			DEPLOY = false;
			USystem.forceDevice();
			ContentBoxTouch.FORCE_SWIPE_SCROLL = true;
		}
		override protected function onApplicationStarted():void 
		{
			super.onApplicationStarted();
			//visible = false;
			Debug.warning(_debugPrefix, "APPLICATION STARTED");
			
			LocalContentUpdater.init();
			
			var baseUrl:String = "https://www.pippoapps.com/_test/content/";
			var urls:Array = ["config.xml", "img0.jpg", "img1.jpg", "img2.jpg", "vid0.mp4", "vid1.mp4"];
			//var urls:Array = ["img0.jpg"];
			var urls2:Array = [];
			for (var i:int = 0; i < urls.length; i++) {
				urls2.push(baseUrl + urls[i]);
			}
			
			
			LocalContentUpdater.updateContent(urls2);
			
			
			
			
			
			
			
			
			
			
			
			return;
			UExec.next(debugPFTouchTransform);
			initStarling(StarlingApp);
			
			
			
			
			//PFVideo.init(null, onVideoInit);
		}
		
		
		override protected function onStarlingReady():void {
			super.onStarlingReady();
			//PFVideo.init(null, onVideoInit);
		}
		
		
		
		
		
		
		
		
		private function onVideoInit(stageVideoAvailable:Boolean):void {
			Debug.debug(_debugPrefix, "Video has been initialized");
			_bgVideo = new PFVideo("BG", "vid.mp4", UGlobal.getStageRect(), true, null, "", false);
			// Add another video with alpha 50%
			//addSoftwareVideo(new Rectangle(0, 0, UGlobal.centerPoint.x, UGlobal.centerPoint.y));
			//addSoftwareVideo(new Rectangle(0, UGlobal.centerPoint.y, UGlobal.centerPoint.x, UGlobal.centerPoint.y));
			//addSoftwareVideo(new Rectangle(UGlobal.centerPoint.x, 0, UGlobal.centerPoint.x, UGlobal.centerPoint.y));
			//addSoftwareVideo(new Rectangle(UGlobal.centerPoint.x, UGlobal.centerPoint.y, UGlobal.centerPoint.x, UGlobal.centerPoint.y));
		}
		private function addSoftwareVideo(r:Rectangle):void {
			Debug.debug(_debugPrefix, "Adding software video: " + r);
			var v:PFVideo = new PFVideo("", "vid_540.mp4", r, true, null, "", true);
			v.addVideo(UGlobal.stage);
			v.getVideo().alpha = 0.5;
		}
	// ContentBoxTouch
		private function debugContentBoxTouch():void {
			_cbt = new ContentBoxTouch({width:UGlobal._sw, height:UGlobal._sh});
			addChild(_cbt);
			UExec.next(initCbt);
		}
		private function initCbt():void {
			var c:RectContent = new RectContent();
			Buttonizer.setupButton(c, this, "Content", "onClick");
			_cbt.setContent(c);
		}
	// PFTouchTransform
		private function debugPFTouchTransform():void {
			// Create a button on the right
			var s:Sprite = new SpriteSquare();
			s.width = 100;
			s.height = 100;
			s.x = UGlobal._sw - 100;
			addChild(s);
			_sprite = s;
			Buttonizer.setupButton(s, this, "Content");
			
			
			_pfTouchView = new PFTouchTransform(this, {});
			_pfTouchView.setViewport(new Rectangle(0, 0, UGlobal._sw - 120, UGlobal._sh), "CROP-RESIZE", false, true, true);
			UExec.frame(60, initPFTouchTransform);
		}
		private function initPFTouchTransform():void {
			var c:RectContent = new RectContent();
			Buttonizer.setupButton(c, this, "Content", "onClick");
			_pfTouchView.setContent(c);
			//Buttonizer.setupButton(c, this, "Content", "onClick");
			UExec.frame(10, addChild, _sprite);
		}
		public function onClickContent(c:InteractiveObject=null):void {
			trace("CONTENT CLICK");
		}
		public function onPressContent(c:InteractiveObject=null):void {
			trace("CONTENT PRESS");
		}
	}

}