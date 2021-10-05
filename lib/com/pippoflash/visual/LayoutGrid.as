/* GridLayout - (c) Filippo Gregoretti - PippoFlash.com */
/* Arranges display objects in a grid 

var grid = new GridLayout();
grid.createGrid({_cw:10, _ch:10, _cols:7, _rows:10}); // Creates a grid based on cells size, columns and rows
grid.splitGrid({_w:100, _h:100, _cols:10, _rows:8}); // Creates a grid based on total size, rows and columns
grid.arrangeClips(clips:Array); // Arranges all clips according to grid
grid._grid:Array; // The array of points where positioning occurs



*/

package com.pippoflash.visual {
	import com.pippoflash.visual.LayoutGrid;
	import									com.pippoflash.utils.UCode;
	import									flash.display.*;
	import									flash.geom.*;
	
	
	public dynamic class LayoutGrid extends MovieClip {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		// SYSTEM - USER DEFINABLE
		// USER VARIABLES
		public var _w							:Number; // Total width of grid
		public var _h							:Number; // Total height of grid
		public var _cw							:Number; // width of cell
		public var _ch							:Number; // Height of cell
		public var _cols							:uint;
		public var _rows							:uint;
		// REFERENCES
		public var _grid							:Array; // List of Points
		public var _gridCols						:Array; // Multidimensional array with columns
		public var _gridRows						:Array; // Multidimensional array with rows
		public var _clips							:Array; // Eventual list of clips to arrange
		// MARKERS
		// DATA HOLDERS
		// UTY
		public static var col						:uint;
		public static var row						:uint;
		public static var p						:Point;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function LayoutGrid					() {
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function createGrid					(par:Object) {
			UCode.setParameters					(this, par);
			_w								= _cw*_cols;
			_h								= _ch*_rows;
			calculatePoints						();
		}
		public function splitGrid					(par:Object) {
			UCode.setParameters					(this, par);
			_cw								= _w/_cols;
			_ch								= _h/_rows;
			calculatePoints						();
		}
		public function arrangeClips					(list:Array) {
			_clips								= list;
			for (var i:uint=0; i<_clips.length; i++) {
				UCode.positionToPoint(_clips[i], _grid[i]);
			}
		}
		public function harakiri						() {
			_clips								= null;
			_grid								= null;
			_gridCols							= null;
			_gridRows							= null;
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
		private function calculatePoints				() {
			_grid								= new Array();
			_gridCols							= new Array();
			_gridRows							= new Array();
			for (row=0; row<_rows; row++) {
				for (col=0; col<_cols; col++) {
					p						= new Point(col*_cw, row*_ch);
					_grid.push					(p);
// 					trace("ROW",row,",COL",col, "POINT",p);
				}
			}
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}