
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)
 
package com.pippoflash.components {
	
	import com.pippoflash.components._cBase;
	import com.pippoflash.utils.*;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.utils.UGlobal
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	public class ToolTipBalloon extends _cBase{
		[Inspectable (name="0.0 - Text Color", type=Color, defaultValue="#000000")]
		public var _colorTxt:uint = 0x000000;
		[Inspectable (name="0.1 - Fill Color", type=Color, defaultValue="#ffffff")]
		public var _colorBg:uint = 0xffffff;
		[Inspectable (name="0.2 - Border Color", type=Color, defaultValue="#aaaaaa")]
		public var _colorBorder:uint = 0xaaaaaa;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		private static const TOOLTIP_SHOW_TIMEOUT:uint = 500;
		private static var MARGIN:uint = 15;
		private static var HORIZ_MARGIN:uint = 5;
		private static var MAX_WIDTH:uint = 300;
		private static var _tipMargin:uint = 18; // Distance of tip from border of balloon
		private static var _point:Point = new Point(0, 0);
		
		// DATA HOLDERS
		private var _txt:String;
		private var _staticId:String; // when tooltip is static (not following mouse) it will be closed ONLY with another tooltip appearing, or using the same id (if any)used to open it
		// SWITCHES
		private static var _alwaysHtml:Boolean = true; // This can be changed from the outside
		private var _isStatic:Boolean;
		private var _isMouse:Boolean;
		// MARKERS
		private var _visible:Boolean;
		private var _timeout:*;
		private var _active:Boolean;
		// REFERENCES FUCK COMPONENT DEFINITION
		public var _toolTip:MovieClip;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ToolTipBalloon						(par:Object=null) {
			super("ToolTip", par);
			//setTextColor(_colorTxt);
			//setFillColor(_colorBg);
			//setBorderColor(_colorBorder);
			visible = false;
			Buttonizer.setClickThrough(this);
			UGlobal.registerToolTip(this);
		}
		// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function followMouseTip(t:String) {
			if (_active && _staticId) { // There was already a static tip, and I remove it first
				hideTip(_staticId, true);
			}
			_txt = t;
			addEventListener(Event.ENTER_FRAME, positionToolTip);
			_timeout = setTimeout(showTip, TOOLTIP_SHOW_TIMEOUT);
			_active = true;
		}
		public function showStillTip(t:String, position:Point, id:String = null, invertY:Boolean=false):void {
			if (_active) hideTip(_staticId, true);
			_isStatic = true;
			_isMouse = false;
			//removeEventListener(Event.ENTER_FRAME, positionToolTip);
			_active = true;
			showTip(t, position, invertY);
			_staticId = id; // This one goes afterwards since showTip nullifies the ID
		}
		public function hideTip(id:String=null, immediate:Boolean=false) {
			if (_staticId && _staticId != id) {
				Debug.debug(_debugPrefix, "Tip is in static mode with an ID. In order to be removed, ToolTip is waiting for ID " + _staticId + ". This ID is not working: " + id);
				return;
			}
			_staticId = null;
			_active = false;
			_visible = false;
			_isStatic = false;
			_isMouse = true;
			removeEventListener(Event.ENTER_FRAME, positionToolTip);
			if (immediate) {
				UDisplay.removeClip(this);
			}
			else {
				PFMover.fadeOutAndKill(this, 5);
				//Animator.fadeOutAndInvisible(this, 3);
			}
			if (_timeout != null) clearTimeout(_timeout);
		}
		public function setTextColor(n:uint) {
			UText.setTextFormat(_toolTip._txt, {color:n});
		}
		public function setFillColor(n:uint) {
			UDisplay.setClipColor(_toolTip._bg, n);
			UDisplay.setClipColor(_toolTip._tip._bg, n);
		}
		public function setBorderColor(n:uint) {
			UDisplay.setClipColor(_toolTip._border, n);
			UDisplay.setClipColor(_toolTip._tip._border, n);
		}
		public function setText(t:String):void {
			if (_alwaysHtml) _toolTip._txt.htmlText = "<TOOLTIP>"+t+"</TOOLTIP>";
			else _toolTip._txt.text = t;
		}
		// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function showTip(t:String=null, position:Point=null, invertY:Boolean=false) {
			//trace("cazzooooo", _active);
			if (!_active) return; // This
			_staticId = null;
			if (t) _txt = t;
			//trace("dajeeeeee",_txt);
			_visible = true;
			alpha = 0;
			UCode.setParameters(_toolTip._txt, _alwaysHtml ? {width:10, autoSize:TextFieldAutoSize.LEFT, multiline:true, wordWrap:false} : {width:10, autoSize:TextFieldAutoSize.LEFT, multiline:false, wordWrap:false});
			setText(_txt);
			if (_toolTip._txt.width > MAX_WIDTH) {
				_toolTip._txt.text = "";
				UCode.setParameters(_toolTip._txt, {width:MAX_WIDTH, multiline:true, wordWrap:true});
				setText(_txt);
			}
			UGlobal.stage.addChild(this);
			_o = {width:_toolTip._txt.width+12, height:_toolTip._txt.height+12};
			UCode.setParameters(_toolTip._bg, _o);
			// ------------------------------------------------------------------------------------------------
			UCode.setParameters(_toolTip._border, {width:_toolTip._bg.width, height:_toolTip._bg.height});
			positionToolTip(null, position, invertY);
			visible = true;
			PFMover.fadeInTotal(this, 5);
		}
		private function positionToolTip(e = null, position:Point = null, invertY:Boolean=false) {
			var xx:Number = position ? position.x : UGlobal.stage.mouseX;
			var yy:Number = position ? position.y : UGlobal.stage.mouseY;
			//if (position) {
				//x = position.x -_tipMargin;
				//y = position.y - _toolTip._bg.height - MARGIN;
			//}
			//else {
				//x = UGlobal.stage.mouseX-_tipMargin;
				//y = UGlobal.stage.mouseY - _toolTip._bg.height - MARGIN;
			//}
			
			x = xx -_tipMargin;
			y = yy - _toolTip._bg.height - MARGIN;
			
			// X positioning
			if ((x + _toolTip._bg.width) > (UGlobal._sw - HORIZ_MARGIN)) {
				var newX:Number = UGlobal._sw - _toolTip._bg.width - HORIZ_MARGIN;
				var diff:Number = x - newX;
				x = newX;
				_toolTip._tip.x = diff + _tipMargin; // xx > (_toolTip._bg.width - _tipMargin) ? _toolTip._bg.width - _tipMargin : xx;
			}
			else if (x < HORIZ_MARGIN) {
				x = HORIZ_MARGIN;
			}
			else {
				_toolTip._tip.x = _tipMargin;
			}
			
			// Y positioning
			if (y < MARGIN || invertY) {
				y = yy + MARGIN*2;
				_toolTip._tip.y = 0;
				_toolTip._tip.scaleY = -1;
			}
			else {
				_toolTip._tip.y = _toolTip._bg.height;
				_toolTip._tip.scaleY = 1;
			}
		}
	}
	
	
	
}