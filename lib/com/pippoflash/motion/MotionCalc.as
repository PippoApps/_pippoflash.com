/* DESCRIPTION

utilities.entities.math.MotionCalc
	

VERSION
	1.0

LAST UNIVERSAL VERSION
	1.0

TYPE
	Static Class
	
HELPERS
	no helpers needed

USAGE

METHODS



*/
/* ANALISYS

Returns the actual value, starting from:
	s - starting value			(where does the value start?)
	c - change in value 			(how much should I add or subtract to that value?)
	d - global duration of motion	(how long should the motion last?)
	n - actual timing in duration	(which step of the motion am I now? from 0 to duration)
	p - power of easing			(how should I ease the motion?)
	


*/

package com.pippoflash.motion {
	public class MotionCalc {
		
	// METHODS ///////////////////////////////////////////////////////////////////////////
	
		public static function straightMove(b, c, d, n) {
			return (c-b) * (n/d);
		}
		public static function slideOut(b, c, d, n, p) {
			return (c-b)*Math.pow(n/=d,p);
		}
		public static function slideIn(b, c, d, n, p) {
			// Quadratic elevation needs this easeOut function
			if (p == 2) return -(c-b) * (n/=d) * (n-2);
			// Even elevation
			else if (p%2 == 0) return -(c-b) * (Math.pow(n/d-1,p) -1);
			// odd elevation
			else return (c-b)* (Math.pow(n/d-1,p) +1);
		}
		
		public static function slideOutIn(b, c, d, n, p) {
			// Quadratic elevation needs this easeOut function
			if (p == 2) {
				if ((n/=d/2) < 1) return (c-b)/2*n*n;
				return  -(c-b)/2 * ((--n)*(n-2)-1);
			}
			// Even elevation
			else if (p%2 == 0) {
				if ((n/=d/2) < 1) return (c-b)/2 * Math.pow(n,p);
				return -(c-b)/2 * (Math.pow(n-2,p)-2);
			}
			// odd elevation
			else {
				if ((n/=d/2) < 1) return (c-b)/2 * Math.pow(n,p);
				return (c-b)/2 * (Math.pow(n-2,p)+2);
			}
		}
	}

}

