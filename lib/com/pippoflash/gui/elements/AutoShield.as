/* DESCRIPTION
AutoShield automatically cover the whole available stage area.
*/	

package com.pippoflash.gui.elements {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.Sprite;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UDisplay;
	public dynamic class AutoShield extends Sprite {
		public var _p:Point;
		public var _r:Rectangle;
		
		public function AutoShield():void {
			// alpha = 0;
// 			UGlobal.callOnStage(update);
		}
		
		public function setColor(col:uint=0, a:Number=0):void {
			UDisplay.setClipColor(this, col);
			// alpha = a;
			trace("setcolor");
		}
		
		
		public function update(containerScale:Number=1):void {
			doUpdate(containerScale);
			trace("update");
		}
		private function doUpdate(containerScale:Number=1):void {
			_r = UGlobal.getRelativeStageRect(parent);
			x = _r.x;
			y = _r.y;
			width = _r.width;
			height = _r.height;
			//return;
			trace("Shield updated on rectangle: ", _r);
			trace("Parent is: ", parent);
			trace("Parent.parent is: ", parent.parent);
			trace("Scales: ",parent.scaleX, parent.scaleY)
		}
		
		
	}
}

