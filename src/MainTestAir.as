package 
{
	import com.pippoflash.utils.*;
	import com.pippoflash.components.*;
	import com.pippoflash.motion.PFTouchTransform;
	import flash.display.*;
	import flash.geom.*;;
	import framework._MainAppBaseAir;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public dynamic class MainTestAir extends _MainAppBaseAir 
	{
		
		private var _cbt:ContentBoxTouch;
		private var _pfTouchView:PFTouchTransform;
		private var _sprite:Sprite;
		
		
		public function MainTestAir(id:String="MainTestAir", appId:String="Test Framework for PippoApps", appVer:String="0.00") 
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
			visible = true;
			Debug.warning(_debugPrefix, "APPLICATION STARTED");
			UExec.next(debugPFTouchTransform);
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