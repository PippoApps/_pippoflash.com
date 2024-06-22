package com.pippoflash.framework.starling 
{
	import starling.display.Canvas;
	import starling.display.*;
	import starling.display.Quad;
	import com.pippoflash.utils.Debug;
	import starling.textures.Texture;
	import starling.textures.SubTexture;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class _StarlingUMem extends _StarlingBase 
	{
		
		public function _StarlingUMem() {
			super("StarlingUMem", _StarlingUMem, true);
		}
		
		public function disposeDisplayObject(c:DisplayObject):void {
			c.removeFromParent();
			c.filter = null;
			if (c is Image) {
				//trace("dispose image", c);
				if ((c as Image).texture) {
					Debug.debug(_debugPrefix, "Disposing texture for Image: " + c);
					var tex:Texture = (c as Image).texture;
					tex.dispose();
					if ( tex is SubTexture ) {
						(tex as SubTexture).parent.dispose();
					}
				}
				c.dispose();
			}
		}
		
		
		public function disposeEnumerableDisplayObjects(vectorOrArray:*):void {
			for each (var c:DisplayObject in vectorOrArray) {
				if (c) {
					c.removeFromParent();
					c.removeEventListeners();
					c.dispose();
					if (c is Image) (c as Image).texture.dispose();
				}
			}
		}
		
		
	}

}