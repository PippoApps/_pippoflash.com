package com.pippoflash.visual {
	import											com.pippoflash.utils.*;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.filters.*;
	import 											fl.motion.Color; 
	import 											com.greensock.*;
	import 											com.greensock.easing.*;
	
	public class Effector {
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static const _effectsList							:Object = {
				glowAndroid:{f:GlowFilter, par:{blurX:8, blurY:8, quality:1, color:0x000000, strength:1}},
				glowTalco:{f:GlowFilter, par:{blurX:20, blurY:20, quality:1, color:0xffffff, strength:1}},
				glowWhite:{f:GlowFilter, par:{color:0xffffff, alpha:1, blurX:20,blurY:20}},
				glowBlack:{f:GlowFilter, par:{color:0x000000, alpha:1, blurX:10,blurY:10, quality:1, strength:1}},
				glowBlackBorder:{f:GlowFilter, par:{color:0x000000, alpha:1, blurX:8,blurY:8, quality:1, strength:3}},
				removeGlow:{f:GlowFilter, par:{alpha:0, blurX:0,blurY:0, remove:true}},
				glowInner:{f:GlowFilter, par:{inner:false, color:0xffffff, alpha:1, blurX:12,blurY:12}},
				glowInviteFriendsClaim:{f:GlowFilter, par:{inner:false, color:0xFFDC00, alpha:1, blurX:12,blurY:12, quality:1, strength:1.6}},
				glowCasinoLobbyTimedBonus:{f:GlowFilter, par:{inner:false, color:0x009900, alpha:1, blurX:12,blurY:12, quality:1, strength:1.6}},
				superKnockout:{f:GlowFilter, par:{inner:false, color:0x99ffff, alpha:1, blurX:30,blurY:30, quality:1, strength:3, knockout:true}},
				cartoonBorder:{f:GlowFilter, par:{inner:false, color:0x000000, alpha:1, blurX:6,blurY:6, quality:1, strength:10, knockout:false}}
			};
		public static var _default_GLOW						:Object = {blurXS:10,blurXE:30};
		// SYSTEM
		public var _id									:String;
		public var _effId									:String;
		public var _filter;
// 		public var _filterArrayNum							:uint;
		public var _par									:Object = new Object();
// 		public var _par									:Object;
		// USER VARIABLES
		public static var _glowColor							:Number = 0xffffff;
		// REFERENCES
		public var _target								:DisplayObject;
		// MARKERS
		// STATIC UTY
		public static var _o								:Object;
		public static var _s								:String;
// INIT /////////////////////////////////////////////////////////////////////////////////////////
		public function Effector(c:DisplayObject, eff:String="GLOW", anim:Boolean=true, id:String=null, par:Object=null) {
			_id = id ? id : UText.getRandomString();
			_effId = eff;
			_target = c;
			if (_target.filters.length > 0) _target.filters = new Array();
			UCode.setParameters(_par, par);
			UCode.setDefaults(_par, Effector["_default_"+_effId]);
			activateEffect();
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function addEffect						(id:String, effect:Object):void { // Adds an effet to the _effectsList to be used as a default effect
			_effectsList[id]								= effect;
		}
		public static function setEffect						(c:DisplayObject, effId:String, par:Object=null):void {
			c.filters									= [getFilter(effId, par)];
		}
		public static function getFilter						(effId:String, par:Object=null):BitmapFilter {
			_o										= _effectsList[effId];
			var f										:BitmapFilter = new (_o.f as Class)();
			for (_s in _o.par)							f[_s] = _o.par[_s];
			if (par)									for (_s in par) f[_s] = par[_s];
			return									f;
		}
		
		// convert passed clip to greyscale
		public static function desaturate(obj:DisplayObject)
		{
			var r:Number=0.212671;
			var g:Number=0.715160;
			var b:Number=0.072169;
		 
			var matrix:Array = [r, g, b, 0, 0,
											  r, g, b, 0, 0,
											  r, g, b, 0, 0,
											  0, 0, 0, 1, 0];
											  
			if (obj.filters == null) {
				obj.filters			=	[new ColorMatrixFilter(matrix)];
				} else {
					var _tmp		= obj.filters;
					_tmp.push		(new ColorMatrixFilter(matrix))
					obj.filters		= _tmp;
					_tmp			= null
			}

		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public static function setColor						(clip:DisplayObject, col:uint) {
			var c										:Color = new Color();
			c.setTint									(col, 1);
			clip.transform.colorTransform						= c;
		}
		public function setVisible							(v:Boolean) {
			if (v)										activateEffect();
			else										_target.filters = null;
		}
		public static function blurIn							(c:DisplayObject, time:Number=1, func=null):void {
			TweenMax.to								(c, time, {alpha:1, blurFilter :{blurX:0,blurY:0,color:_glowColor}, startAt:{alpha:0, blurFilter :{blurX:50,blurY:10,color:_glowColor}, onCompleteListener:func ? func : UCode.dummyFunction}});
		}
		public static function blurOut						(c:DisplayObject, time:Number=1, func=null):void {
			
		}
		public static function fadeIn							(c:DisplayObject, time:Number=1):void {
			TweenMax.to								(c, time, {autoAlpha:1});
		}
		public static function fadeOut						(c:DisplayObject, time:Number=1):void {
			TweenMax.to								(c, time, {autoAlpha:0});
		}
		public static function setGlowColor						(c:Number):void {
			_glowColor									= c;
		}
		public static function startGlow(c:DisplayObject, time:Number=0.5, glowFilter:*=null):void {
			if (glowFilter == null) glowFilter = {color:_glowColor, alpha:1, blurX:12,blurY:12,inner:false};
			else if (glowFilter is String) glowFilter = _effectsList[glowFilter].par;
			TweenMax.to(c, time, {yoyo:true, repeat:-1, glowFilter:glowFilter});
		}
		public static function startGlowColor					(c:DisplayObject, col:uint=0xffffff, time:Number=0.5):void {
			var prevColor								:uint = _glowColor;
			_glowColor									= col;
			startGlow									(c as DisplayObject, time);
			_glowColor									= prevColor;
		}
		public static function stopGlow(c:DisplayObject, time:Number=0.5):void {
			setGlow(c, time, "removeGlow");
// 			TweenMax.to(c, 0, {glowFilter  :{remove:true}});
		}
		public static function startBounce(c:DisplayObject, time:Number = 0.3, scale:Number=1.08):void {
			TweenMax.to(c, time, {yoyo:true, repeat:-1, scaleX:scale, scaleY:scale});
		}
		public static function stopBounce(c:DisplayObject, time:Number=0.5, scale:Number=1):void {
			TweenMax.to(c, time, {scaleX:scale, scaleY:scale});
		}
		public static function setGlow(c, time:Number=0.5, filter:String="glowWhite"):void {
			var t:TweenMax = TweenMax.to(c, time, {glowFilter:_effectsList[filter].par});
			if (time == 0) t.progress(1);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		public function activateEffect						() {
			this["activateEffect_"+_effId]					();
		}
		private function activateEffect_GLOW					() {
			_filter									= new GlowFilter();
// 			_target.filters[_filterArrayNum]					= _filter;
// 			if (_target.filters.length > 0)						_target.filters.push(_filter);
			_target.filters 								= [_filter];
			_filter.color									= 0x000000;
			_filter.alpha								= 0.3;
			_filter.quality								= 3;
			_filter.blurX = _filter.blurY						= 2;
			_target.filters 								= [_filter];
			
		}
		public function removeEffects						() {
			_target.filters 								= [];
		}
// END MOTION ACTIONS ////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
}


/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all DisplayObjects included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All DisplayObjects and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */