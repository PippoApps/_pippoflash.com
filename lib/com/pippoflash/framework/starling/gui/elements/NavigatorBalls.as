package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.utils.*;
	import starling.display.*;
	import com.pippoflash.framework.PippoFlashEventsMan;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class NavigatorBalls extends _StarlingBase 
	{
		public static const EVT_SELECTED:String = "onNavigatorSelected";
		static public const MOTION_SPEED:Number = 0.4;
		private static const CLICKABLE_MARGIN:int = 18;
		// POSITION
		private var _steps:uint;
		private var _selectedStep:uint;
		private var _balls:Vector.<Canvas>;
		private var _selector:DisplayObject;
		private var _selectedBall:Canvas;
		// VARIABLES
		private var _color:uint;
		private var _selColor:uint;
		private var _radius:Number;
		private var _selRadius:Number;
		private var _distance:Number;
		private var _align:String; // LEFT; CENTER; RIGHT
		private var _anim:String; // grow, move
		private var _interactive:Boolean; // If balls are tappable
		private var _clickableArea:Canvas;
		
 		
		
		public function NavigatorBalls(color:uint = 0x000000, selColor:uint = 0xbbbbbb, radius:Number = 80, selRadius:Number = 100, distance:Number=200, align:String = "CENTER", anim:String="grow", interactive:Boolean=true, steps:uint = 0, select:uint = 0) {
			super("NavigatorBalls", NavigatorBalls, false);
			UMem.addClass(Canvas);
			_color = color;
			_selColor = selColor;
			_radius = radius;
			_selRadius = selRadius;
			_distance = distance;
			_align = align;
			_anim = anim;
			_interactive = interactive;
			if (anim == "move") {
				const sel:Canvas = UMem.getInstance(Canvas);
				//_selector = UMem.getInstance(Canvas);
				sel.clear();
				sel.beginFill(_selColor);
				sel.drawCircle(0, 0, _selRadius);
				sel.endFill();
				_selector = sel;
			}
			_clickableArea = uDisplay.getSquareCanvas(0xff0000, (radius+CLICKABLE_MARGIN)*2);
			_clickableArea.alpha = 0;
			StarlingGesturizer.addTap(_clickableArea, onClickArea);
			addChild(_clickableArea);
			if (steps) setSteps(steps);
			if (select) setSelected(select);
		}
		public function setSteps(steps:uint):void {
			if (_balls) clear();
			_steps = steps;
			_balls = new Vector.<Canvas>(_steps);
			for (var i:int = 0; i < _steps; i++) {
				var ball = new Canvas(); // UMem.getInstance(Canvas);
				ball.beginFill(_color);
				ball.drawCircle(0, 0, _radius);
				ball.endFill();
				addChild(ball);
				ball.scale = 1;
				_balls[i] = ball;
				//if (_interactive) StarlingGesturizer.addTap(ball, onTapBall);
			}
			setupLayout();
			resetSelection();
			if (_selector) addChild(_selector);
			addChild(_clickableArea);
		}
		public function setSelector(sel:DisplayObject):void { // Overrides default selector with another one
			if (_selector) {
				uDisplay.positionTo(sel, _selector);
				//addChild(sel);
				_selector.removeFromParent();
				_selector.dispose();
				_selector = sel;
				addChild(_selector);
			}
			addChild(_clickableArea);
		}
		public function resetSelection():void {
			_selectedStep = 0;	
			if (isGrow) {
				if (_selectedBall) _selectedBall.width = _selectedBall.height = _radius;
				_selectedBall = _balls[0];
				_selectedBall.width = _selectedBall.height = _selRadius * 2;
			} else if (isMove) {
				_selector.x = _balls[0].x;
			}
			//_selectedBall = null;
		}
		public function setSelected(step:uint):void {
			if (_selectedStep == step) return;
			_selectedStep = step;
			var newBall:Canvas = _balls[step];
			if (_selectedBall == newBall) return; // Already selected
			if (isGrow) {
				if (_selectedBall) mover.move(_selectedBall, MOTION_SPEED, {scale:1});
				mover.move(newBall, MOTION_SPEED, {height:_selRadius*2, width:_selRadius*2});
			} else if (isMove) {
				mover.move(_selector, MOTION_SPEED, {x:newBall.x});
			}
			_selectedBall = newBall;
		}
		
		
		
		
		private function clear():void {
			for each (var ball:Canvas in _balls) {
				//ball.clear();
				if (_interactive) StarlingGesturizer.removeGestures(ball);
				ball.removeFromParent();
				ball.scale = 1;
				ball.dispose();
				//UMem.storeInstance(ball);
			}
			_balls = null;
			if (_selector) _selector.removeFromParent();
		}
		private function setupLayout():void {
			var ball:Canvas; var offset:Number;
			if (_align == "LEFT") offset = 0;
			else if (_align == "RIGHT") offset = -(_distance * _steps);
			else offset = -((_distance * _steps) / 2);
			for (var i:int = 0; i < _steps; i++) {
				ball = _balls[i];
				ball.x = (i * _distance) + offset;
			}
			_clickableArea.clear();
			_clickableArea.beginFill(0xff000000);
			_clickableArea.drawRectangle(0,0,((_distance) * (_steps)), ((_radius + CLICKABLE_MARGIN) * 2))
			//_clickableArea.width = ((_distance) * (_steps));
			//_clickableArea.height = ((_radius + CLICKABLE_MARGIN) * 2);
			_clickableArea.y = -(_radius + CLICKABLE_MARGIN);
			_clickableArea.x = offset - (_distance / 2);
			//addChild(_clickableArea);
		}
		
		public function onTapBall(b:Canvas):void {
			var step:uint = _balls.indexOf(b);
			Debug.debug(_debugPrefix, "Tapped " + step);
			if (step == _selectedStep) {
				Debug.debug(_debugPrefix, "Step already selected.");
				return;
			}
			setSelected(step);
			if (_interactive) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SELECTED, _selectedStep);
		}
		public function onClickArea(c:Canvas):void {
			const index:int = Math.floor(StarlingGesturizer.getTapGestureRelativeLocation(c).x / _distance);
			onTapBall(_balls[index]);
		}
		// CHECKS
		public function get isMove():Boolean {
			return _anim == "move";
		}
		public function get isGrow():Boolean {
			return _anim == "grow";
		}
		
	}

}