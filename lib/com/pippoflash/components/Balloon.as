/* Balloon - (c) Filippo Gregoretti - www.pippoflash.com
*/

package com.pippoflash.components {
	import											com.pippoflash.utils.*;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	import											com.pippoflash.components.Balloon.DefaultMainGraphics;
	public dynamic class Balloon extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="UI - Expand", type=String, defaultValue="HEIGHT", enumeration="HEIGHT,WIDTH,BOTH")]
		public var _expandMode							:String = "HEIGHT";
		[Inspectable 									(name="UI - Max Width (0 none)", type=Number, defaultValue=0)]
		public var _maxWidth								:uint = 0;
		[Inspectable 									(name="UI - Max Height (0 none)", type=Number, defaultValue=0)]
		public var _maxHeight								:uint = 0;
		[Inspectable 									(name="UI - Tip Position (anchor)", type=String, defaultValue="BOTTOM_LEFT", enumeration="BOTTOM_LEFT,LEFT,TOP_LEFT,TOP,TOP_RIGHT,RIGHT,BOTTOM_RIGHT,BOTTOM")]
		public var _tipPosition								:String = "BOTTOM_LEFT";
		[Inspectable 									(name="UI - Don't shrink below size", type=Boolean, defaultValue=true)]
		public var _dontShrinkBelowSize						:Boolean = true;
		[Inspectable 									(name="UX - Animation In", type=String, defaultValue="FADE", enumeration="FADE,BOUNCE")]
		public var _animationIn								:String = "FADE";
		[Inspectable 									(name="UX - Animation Out", type=String, defaultValue="FADE", enumeration="FADE,BOUNCE")]
		public var _animationOut							:String = "FADE";
		[Inspectable 									(name="SYS - Main Graph Class", type=String, defaultValue="com.pippoflash.components.Balloon.DefaultMainGraphics")]
		public var _mainGraphicsClassName						:String = "com.pippoflash.components.Balloon.DefaultMainGraphics";
		// STATIC ////////////////////////////////////////////////////////////////////////////////
		private static const HORIZ_TIP_DIST					:uint = 30;
		private static const VERT_TIP_DIST					:uint = 20;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// SYSTEM
		private var _centerPoint							:Point;
// 		private var _scaleY								:Number; // Stores the original scaleY
// 		private var _scaleX								:Number; // Stores the original scaleY
		private var _balloonW								:Number;
		private var _balloonH								:Number;
		private var _hideTimeout							:*;
		// REFERENCES
		private var _mainGraphics							:MovieClip; // this references the main graphics class for balloon
		private var _txt									:TextField;
		private var _bg									:MovieClip;
		private var _square								:MovieClip;
		private var _tip									:MovieClip;
		// MARKERS
		// DATA HOLDERS
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function Balloon								(par:Object=null) {
			super									("Balloon", par);
		}
// 		protected override function initAfterVariables				():void {
// 			super.initAfterVariables						(); 
// 		}
// RECURRENT INIT ///////////////////////////////////////////////////////////////////////////////////////
		protected override function initialize					():void { // This is called EVERY TIME the component is initialized. It suppose a full re-rendering. Its called automatically on recycle.
			initializeGraphics								();
			super.initialize								();
		}
			private function initializeGraphics					():void {
				// Create main graphics
				_mainGraphics							= MovieClip(addChild(UCode.getInstance(_mainGraphicsClassName)));
				_mainGraphics._tipBL.visible = _mainGraphics._tipL.visible = _mainGraphics._tipTL.visible = _mainGraphics._tipT.visible = _mainGraphics._tipTR.visible = _mainGraphics._tipR.visible = _mainGraphics._tipBR.visible = _mainGraphics._tipB.visible = false;
				_bg									= _mainGraphics._bg;
				_square								= _mainGraphics._square;
				_txt									= _mainGraphics._txt;
				_bg.width								= _w;
				_bg.height								= _h;
// 				_scaleY								= _bg.scaleY;
// 				_scaleX								= _bg.scaleX;
				_square.scaleY							= _bg.scaleY;
				_square.scaleX							= _bg.scaleX;
				_txt.width								= _square.width;
				_txt.height								= _square.height;
				_centerPoint							= new Point(Math.round(_w/2), Math.round(_h/2));
				UDisplay.positionToPoint					(_square, _centerPoint);
				UDisplay.positionToPoint					(_bg, _centerPoint);
				visible								= false;
			}// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////		
		public override function cleanup						():void {
			_bg = _square = _tip 							= null; 
			_txt										= null;
			UDisplay.removeClip							(_mainGraphics);
			super.cleanup								();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function say								(txt:String, disappearAfter:int=-1, isHtml:Boolean=false):void {
			if (txt == _txt.text)							return;
			renderText									(txt, isHtml);
			renderBalloon								();
			show										();
			if (disappearAfter > 0)						_hideTimeout = setTimeout(hide, disappearAfter);
		}
		public function show								():void {
			removeTimeout								();
			if (_animationIn == "FADE") {
				Animator.fadeInTotal						(this, 2);
			}
			else {
				visible								= true;
				alpha									= 1;
			}
		}
		public function hide								():void {
			removeTimeout								();
			if (_animationOut == "FADE") {
				Animator.fadeOutAndInvisible				(this, 2);
			}
			else {
				visible								= false;
			}
			_txt.text									= "";
		}
		private function removeTimeout						():void {
			if (_hideTimeout)								clearTimeout(_hideTimeout);
			_hideTimeout								= null;
		}
		public function setXmlTextFormat						(xml:*):void {
			UText.setXmlTextFormat						(_txt, xml);
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////////////
		private function renderText							(txt:String, isHtml:Boolean=false):void {
			Debug.debug								(_debugPrefix, "Saying: \""+txt+"\"");
			_txt.autoSize								= TextFieldAutoSize.CENTER;
			if (isHtml)									_txt.htmlText = txt;
			else										_txt.text = txt;
		}
		private function renderBalloon						():void {
			_square.width								= Math.round(_txt.width) + 10;
			_square.height								= Math.round(_txt.height) + 10;
			_bg.scaleY									= _square.scaleY;
// 			_bg.scaleX									= _square.scaleX;
			_balloonW									= Math.round(_bg.width);
			_balloonH									= Math.round(_bg.height);
			if (_dontShrinkBelowSize)						dontShrinkBelowSize();
			positionContentToBg							();
			UCode.callMethodAlert							(this, "renderTip_"+_tipPosition);
			_tip.visible									= true;
		}
			private function dontShrinkBelowSize				():void {
					if (_balloonW < _w) {
						_bg.width						= _w;
						_balloonW						= _w;
					}
					if (_balloonH < _h) {
						_bg.height						= _h;
						_balloonH						= _h;
					}
			}
			public function renderTip_BOTTOM_LEFT				():void {
				_tip									= _mainGraphics._tipBL;
				_tip.x									= 0;
				_tip.y								= _balloonH;
				_tip.width								= _centerPoint.x;
				_tip.height								= _balloonH*0.7;
				alignMainGraphicsBottom					();
			}
			public function renderTip_BOTTOM_RIGHT			():void {
				_tip									= _mainGraphics._tipBR;
				_tip.x									= _balloonW;
				_tip.y								= _balloonH;
				_tip.width								= _centerPoint.x;
				_tip.height								= _balloonH*0.7;
				alignMainGraphicsBottom					();
			}
			public function renderTip_BOTTOM					():void {
				_tip									= _mainGraphics._tipB;
				_tip.x									= _centerPoint.x;
				_tip.y								= _balloonH + VERT_TIP_DIST;
				_tip.height								= _centerPoint.y;
				alignMainGraphicsBottom					();
			}
			public function renderTip_TOP					():void {
				_tip									= _mainGraphics._tipT;
				_tip.x									= _centerPoint.x;
				_tip.y								= -VERT_TIP_DIST;
				_tip.height								= _centerPoint.y;
				alignMainGraphicsTop						();
			}
			public function renderTip_TOP_LEFT				():void {
				_tip									= _mainGraphics._tipTL;
				_tip.x									= 0;
				_tip.y								= 0;
				_tip.width								= _centerPoint.x;
				_tip.height								= _balloonH*0.7;
				alignMainGraphicsTop						();
			}
			public function renderTip_TOP_RIGHT			():void {
				_tip									= _mainGraphics._tipTR;
				_tip.x									= _balloonW;
				_tip.y								= 0;
				_tip.width								= _centerPoint.x;
				_tip.height								= _balloonH*0.7;
				alignMainGraphicsTop						();
			}
			public function renderTip_LEFT					():void {
				_tip									= _mainGraphics._tipL;
				_tip.x									= -HORIZ_TIP_DIST;
				_tip.y								= _centerPoint.y;
				alignMainGraphicsMiddle						();
			}
			public function renderTip_RIGHT					():void {
				_tip									= _mainGraphics._tipR;
				_tip.x									= _balloonW+HORIZ_TIP_DIST;
				_tip.y								= _centerPoint.y;
				alignMainGraphicsMiddle						();
			}
				private function alignMainGraphicsMiddle			():void {
					_mainGraphics.y						= (_h - _balloonH)/2;
				}
				private function alignMainGraphicsBottom		():void {
					_mainGraphics.y						= (_h - _balloonH);
				}
				private function alignMainGraphicsTop			():void {
					_mainGraphics.y						= -(_h - _balloonH);
				}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function positionContentToBg					():void {
			_centerPoint								= new Point(_bg.width/2, _bg.height/2);
			UDisplay.positionToPoint						(_square, _centerPoint);
			UDisplay.positionToPoint						(_bg, _centerPoint);
			_txt.x									= _square.x - (_txt.width/2);
			_txt.y									= _square.y - (_txt.height/2);
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
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