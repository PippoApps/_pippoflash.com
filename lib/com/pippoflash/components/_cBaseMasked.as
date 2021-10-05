/* IMPORTANT - UMem usage.
	Components decide their own id. So they are taken with: UMem.getInstanceId. They can also be taken with getInstance(Class) though...
*/

package com.pippoflash.components {	import com.pippoflash.utils.Debug;	import com.pippoflash.utils.UCode;	import com.pippoflash.utils.UDisplay;	import com.pippoflash.utils.UMem;		import flash.display.*;	import flash.events.*;	import flash.net.*;	import flash.geom.*;	import flash.utils.setTimeout;		// Ready to be updated to framework 0.44 - Be carefulò to update all components!!!!			public class _cBaseMasked extends _cBase {// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		private var _maskRect						:Rectangle;// VARIABLES ///////////////////////////////////////////////////////////////////////////////////
// INIT ONCE /////////////////////////////////////////////////////////////////////////////////////////
		// Initialization here happens only on first component instantiation		public function _cBaseMasked				(id:String="", par:Object=null) {
			super							(id, par);		}			protected override function initDimensions	():void {
				super.initDimensions				();				setupScrollRect					();			}// UPDATE ///////////////////////////////////////////////////////////////////////////////////////		public override function update				(par:Object):void { // This is overridable, it means that we are updating component on programmatically set values
			super.update						(par);			// In this baseclass I only init the references to width and height			if (par.width || par.height) {
				resize						(_w, _h);			}		}		public override function resize						(w:Number, h:Number):void {
			super.resize						(w, h);
			setupScrollRect						();		}// INTERNAL UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		private function setupScrollRect				():void {
// 			_maskRect							= new Rectangle(0, 0, _w, _h);
			scrollRect							= new Rectangle(0, 0, _w, _h);;
		}	}}