/* Layout - (c) Filippo Gregoretti - PippoFlash.com */
/* Arranges display objects in a layout that can be horizontal, vertical, or grid
var grid = new GridLayout();
grid.createGrid({_cw:10, _ch:10, _cols:7, _rows:10}); // Creates a grid based on cells size, columns and rows
grid.splitGrid({_w:100, _h:100, _cols:10, _rows:8}); // Creates a grid based on total size, rows and columns
grid.arrangeClips(clips:Array); // Arranges all clips according to grid
grid._grid:Array; // The array of points where positioning occurs



*/

package com.pippoflash.visual {
	import com.pippoflash.visual.Layout;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.Debug;
	import									flash.display.*;
	import									flash.geom.*;
	
	
	public dynamic class Layout {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		private static var _debugPrefix				:String = "Layout";
		private static var _layoutObjectDefaults			:Object = {
			w:0, // Width of layout. Used only in grid
			h:0, // Height of layout. Used omnly in grid
			cw:0, // Width of cell
			ch:0, // Height of cell
			layout:"GRIDFULL",// GRID, GRIDFULL, HORIZONTAL, VERTICAL (GRIDFULL is a grid but margin is minimum margin)
			margin:0, // Inner margin of cells
			border:0 // Outer margin of cells
		};
		// SYSTEM - USER DEFINABLE
		// USER VARIABLES
		// REFERENCES
		// MARKERS
		// DATA HOLDERS
		private static var _infoObject				:Object;
		// UTY
		public static var _i						:int;
		public static var _n						:Number;
		public static var _s						:String;
		public static var _c						:DisplayObject;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public static function arrange				(items:Array, layoutObj:Object):Object {
			/* layoutObj definition
				w		:Number	Width of layout
				h		:Number 	Height of layout
				cw		:Number	Width of single cell
				ch		:Number	Height of single cell
				layout	:String	Type of layout: GRID, GRIDFULL, LISTVERT, LISTHORIZ
				margin	:Number	Margin of space between cells
				border	:Number	Space on sides, if not defined, 0 will be used
				
			
			*/
			_infoObject							= {};
			for (_s in _layoutObjectDefaults) 			if (!layoutObj[_s]) layoutObj[_s] = _layoutObjectDefaults[_s];
			return							Layout["arrange_"+layoutObj.layout](items, layoutObj);
		}
			private static function arrange_GRID		(items:Array, layoutObj:Object):Object {
				Debug.debug						(_debugPrefix, "Setting items:",items.length);
				var o							:Object = layoutObj;
				var amount					:uint = 0; // Amount of cells that can be set in a certain space
				var cellW						:Number = o.cw + o.margin;
				var cellH						:Number = o.ch + o.margin;
				var stepH						:uint = 0;
				var stepV						:uint = 0;
				if (layoutObj.w) { // Arrange cells in a vertical grid
					var gridW					:Number = o.w - (o.border*2);
					amount					= Math.floor(gridW/cellW);
					for each (_c in items) {
						_c.x					= o.border + (stepH * cellW);
						_c.y					= o.border + (stepV * cellH);
						stepH				++;
						if (stepH >= amount) {
							stepH			= 0;
							stepV			++;
						}
					}
				}
				else { // Arrange cells in a horizontal grid
					// TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
				}
				if (items.length < amount)			amount = items.length;
				_infoObject						= {cellsH:amount, cellsV:stepV, cellW:cellW, cellH:cellH, gridW:cellW*amount, gridH:cellW*stepV};
				return						_infoObject;
			}
			private static function arrange_GRIDFULL	(items:Array, layoutObj:Object):Object { 
				// NOT WORKING
				// this one just arranges cells leaving equal space in between (and also on sides in border > 0)
				// margin here acts as minimum margin, meaning that it has never to be less than margin
				var o							:Object = layoutObj;
				var amount					:uint = 0; // Amount of cells that can be set in a certain space
				var cellW						:Number = o.cw;
				var cellH						:Number = o.ch;
				var dividerAdd					:uint = o.border ? 1 : -1; // if I need to use also border, I divide space also for these. If no borders, then only internal spaces (-1)
				var stepH						:uint = 0;
				var stepV						:uint = 0;
				var gridW						:Number = o.w;
				var gridH						:Number = o.h;
				// Find maximum amount of cells to set in a row
				var amountH					:uint = Math.floor(gridW/cellW);
				var amountV					:uint = Math.floor(gridH/cellH);
				if (layoutObj.w) { // Arrange cells in a vertical grid
					// Find real amount of cells
					var margin					:Number = (gridW - (cellW*amountH))/(amountH+dividerAdd);
					while (margin < o.margin) { // Loop here until minimum margin is met
						trace("margin",margin,"amountH",amountH);
						amountH				--;
						margin				= (gridW - (cellW*amountH))/(amountH+dividerAdd);
					}
					cellW						+= margin;
					if (o.border)				o.border = margin; // Add space to border
					for each (_c in items) {
						_c.x					= o.border + (stepH * cellW);
						_c.y					= o.border + (stepV * cellH);
						stepH				++;
						if (stepH >= amount) {
							stepH			= 0;
							stepV			++;
						}
					}
				}
				else { // Arrange cells in a horizontal grid
					// TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
				}
				_infoObject						= {amount:amount, cellW:cellW, cellH:cellH};
				return						_infoObject;
			}






// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}