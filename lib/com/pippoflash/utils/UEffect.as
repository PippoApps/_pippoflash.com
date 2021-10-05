/* UGlobal - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Manaes all informations about Global values.
- Stage sizes and alignment
- Focus management
- Main application links

*/

package com.pippoflash.utils {

	import com.pippoflash.utils.Debug;
	import com.gskinner.geom.ColorMatrix;
	import flash.filters.BitmapFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.display.*;
	import flash.filters.GlowFilter;
	
	public class UEffect {
		
		public static var _verbose					:Boolean = true;
		public static var _debugPrefix				:String = "UEffect";
		public static var _matrix					:ColorMatrix = new ColorMatrix();
		// UTY
// METHODS ///////////////////////////////////////////////////////////////////////////
		public static function setBrightness(c:DisplayObject, n:Number, overwrite:Boolean=false):void {
			var cm:ColorMatrix = new ColorMatrix();
			cm.adjustBrightness(n);
			var f:ColorMatrixFilter = new ColorMatrixFilter(cm);
			addFilter(c, f, overwrite);
		}
		static public function setGlow(c:DisplayObject, color:uint=0, alpha:Number=1, blurX:Number=10, blurY:Number=10, strength:Number=2, quality:int=1, inner:Boolean=false, knockout:Boolean=false, overwrite:Boolean=false):void {
			var f:GlowFilter = new GlowFilter(color, alpha, blurX, blurY, strength, quality, inner, knockout);
			addFilter(c, f, overwrite);
		}
		
		
		
		
		
		
		public static function clear(c:DisplayObject):void {
			c.filters = [];
		}
		// UTY
		static private function addFilter(c:DisplayObject, filter:BitmapFilter, overwrite:Boolean=false):void {
			if (overwrite) c.filters = [filter];
			else c.filters.length ? c.filters.push(filter) : c.filters = [filter];
		}
	}
}


/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */