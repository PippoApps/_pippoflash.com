/* ExternalLibrary - ver 0.1 - Filippo Gregoretti - www.pippoflash.com - MIN PLAYER VERSION: 11.3
This is the Main class for external library files.
It automatically finds Sounds (in future also bitmaps, swfs, etc...)
*/

package com.pippoflash.framework {

	import 									flash.text.*;
	import 									flash.utils.*;
	import 									flash.net.*;
	import 									flash.display.*;
	import 									flash.system.*;
	import									com.pippoflash.utils.*;
	import									com.pippoflash.net.SimpleQueueLoaderObject;

	
	public dynamic class ExternalLibrary extends MovieClip {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		private static const SOUND_KEYWORDS		:Array = [".wav"]; // If this keyword is present in export ID, it will be trated as a sound
		// REFERENCES
		// DATA HOLDERS
		// CONTENTS
		private var _definitions					:Vector.<String> = new Vector.<String>; // A list of definitions formatted as strings
		private var _sounds						:Object; // A list of sound objects - definition -> Class
		// MARKERS
		public var processSounds					:Boolean = true;
		// STATIC UTY
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ExternalLibrary				():void {
			// Here it means I am loaded and instantiated
			var definitions						:Vector.<String> = this.loaderInfo.applicationDomain.getQualifiedDefinitionNames();
			_definitions						= new Vector.<String>();
			_sounds							= {};
			var subWithDot						:String = "::";
			var dot							:String = ".";
			var fullDef							:String;
			for each (var def:String in definitions) {
				fullDef						= def.indexOf(subWithDot) == -1 ? def : def.split(subWithDot).join(dot); 
				_definitions.push				(fullDef);
				// Proceed setting up sounds and else
				if (definitionIsSound(fullDef)) {
					_sounds[fullDef]			= getInternalClass(fullDef);
				}
			}
			trace								("[ExternalLibrary] with",_definitions.length,"classes initialized on", this.loaderInfo.url);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// This is needed in order to be recognized by loader objects
		public function get isPippoFlashLibrary		():Boolean {
			return							true;
		}
		public function getInfo					():String {
			// Returns info on the library
			var info							:String = "[PippoFlash ExternalLibrary]\n";
			info								+= this.loaderInfo.url + "\n";
			info								+= _definitions.join("\n");
			return							info;
		}
		public function getUrl					():String {
			return							this.loaderInfo.url;
		}
		public function getDefinitions				():Vector.<String> {
			return							_definitions;
		}
		public function getInternalClass				(className:String):Class {
			return							this.loaderInfo.applicationDomain.getDefinition(className) as Class;
		}
		public function getSoundClasses			():Object {
			return							_sounds;
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function definitionIsSound			(def:String):Boolean {
			for each (var key:String in SOUND_KEYWORDS) {
				if (def.indexOf(key) != -1)			return true;
			}
			return 							false;
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