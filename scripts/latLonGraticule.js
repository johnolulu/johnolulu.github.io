/*
latLonGraticule.js

Source: http://www.bdcc.co.uk/Gmaps/BdccGmapBits.htm
Author: Bill Chadwick, 2006

This shows a lat/lon graticule on the map.
Interval between lat/lon lines is automatic.

2009, John Maurer: Cleaned up code style and added more comments; changed label
format for DMS to include seconds, etc.
*/


/*
LatLonGraticule()

Initiate LatLonGraticule object.

Sexagesimal (base-sixty) is a numeral system with sixty as the base;
if set to true, lat/lon will be reported like 50d 20' 30", meaning
50 degrees, 20 minutes, 30 seconds. The default is to report decimal
intervals like 50.25, meaning 50.25 degrees...
*/

function LatLonGraticule ( map, sexagesimal ) {
    this.map_ = map;
    this.sex_ = sexagesimal || false; // default is decimal intervals
}


LatLonGraticule.prototype = new GOverlay();


/*
initialize()
*/

LatLonGraticule.prototype.initialize = function () {

  // Array for divs used for lines and labels:

  this.divs_ = new Array();
      
}


/*
remove()
*/

LatLonGraticule.prototype.remove = function () {

  try {

    var div = this.map_.getPane( G_MAP_MARKER_SHADOW_PANE );

    for ( var i = 0; i < this.divs_.length; i++ ) {
	    div.removeChild( this.divs_[ i ] );
    }

	}

  catch( e ) {
  }

} // remove()


/*
copy()
*/

LatLonGraticule.prototype.copy = function () {
  return new LatLonGraticule( this.sex_ );
}


/*
redraw()
Redraw the graticule based on the current projection and zoom level...
*/

LatLonGraticule.prototype.redraw = function ( force ) {

  // Clear old:

  this.remove();

  // Best color for writing on the map?:

  this.color_ = this.map_.getCurrentMapType().getTextColor();

  // Determine graticule interval:

  var bounds = this.map_.getBounds();
  
  var maxWest  = bounds.getSouthWest().lng();
  var maxSouth = bounds.getSouthWest().lat();
  var maxNorth = bounds.getNorthEast().lat();
  var maxEast  = bounds.getNorthEast().lng();

  // Sanity check:

  if ( maxSouth < -90.0 ) {
	  maxSouth = -90.0;
  }

  if ( maxNorth > 90.0 ) {
	  maxNorth = 90.0;
  }

  if ( maxWest < -180.0 ) {
    maxWest = -180.0;  
  }

  if ( maxEast > 180.0 ) {
    maxEast = 180.0;
  }
    
  if ( maxWest == maxEast ) {
	  maxWest = -180.0;
	  maxEast =  180.0;
  }

  if ( maxNorth == maxSouth ) {
	  maxSouth = -90.0;
    maxNorth =  90.0;
  }

  // Grid interval in minutes:

  var dLat = this.gridIntervalMins( maxNorth - maxSouth );

  var dLng; 

  if ( maxEast > maxWest ) {
	  dLng = this.gridIntervalMins( maxEast - maxWest );
  }
  else {
    dLng = this.gridIntervalMins( ( 180 - maxWest ) + ( maxEast + 180 ) );
  }

  // Round iteration limits to the computed grid interval:

  maxWest  = Math.floor( maxWest  * 60 / dLng ) * dLng / 60;
  maxSouth = Math.floor( maxSouth * 60 / dLat ) * dLat / 60;
  maxNorth = Math.ceil ( maxNorth * 60 / dLat ) * dLat / 60;
  maxEast  = Math.ceil ( maxEast  * 60 / dLng ) * dLng / 60;

  // Sanity check:

  if ( maxSouth < -90.0 ) {
    maxSouth = -90.0;
  }

  if ( maxNorth > 90.0 ) {
    maxNorth = 90.0;
  }

  if ( maxWest < -180.0 ) {
    maxWest = -180.0;
  }

  if ( maxEast > 180.0 ) {
    maxEast = 180.0;
  }

  // To whole degrees:

  dLat /= 60;
  dLng /= 60;
  
  // # digits after decimal point for decimal labels:

  var latDecs = this.gridPrecision( dLat );
  var lonDecs = this.gridPrecision( dLng );
  
  this.divs_ = new Array();

  // To count/index inserted divs:

  var i = 0;

  // Min and max x and y pixel values for graticule lines:

  var pixelBottomLeft = this.map_.fromLatLngToDivPixel( new GLatLng( maxSouth, maxWest ) );
  var pixelTopRight   = this.map_.fromLatLngToDivPixel( new GLatLng( maxNorth, maxEast ) );
  
  this.maxX =   pixelTopRight.x;
  this.maxY = pixelBottomLeft.y;
  this.minX = pixelBottomLeft.x;
  this.minY =   pixelTopRight.y;
 
  // Pixel coordinate for label:
 
  var x;

  // Put labels on second column to avoid peripheral controls:

  var y = this.map_.fromLatLngToDivPixel( new GLatLng( maxSouth + dLat + dLat, maxWest ) ).y + 2;
  
  // Pane/layer to write on; this defines the z-level that the graticule
  // will get written to on the map. G_MAP_MARKER_SHADOW_PANE is above 
  // other polyline/polygon/ground/tile overlays, but beneath markers:

  var mapDiv = this.map_.getPane( G_MAP_MARKER_SHADOW_PANE );
  
  if ( maxEast < maxWest ) {
    maxEast += 360.0;
  }

  // Vertical lines:

  var thisLon = maxWest;

  while ( thisLon <= maxEast ) {

	  var pixel = this.map_.fromLatLngToDivPixel( new GLatLng( maxSouth, thisLon ) );

	  // Line:

	  this.divs_[ i ] = this.createVLine( pixel.x );

	  mapDiv.insertBefore( this.divs_[ i ], null );

	  i++;
	
	  // Label:

	  var div = document.createElement( 'div' );

	  x = pixel.x + 3;

	  div.style.position   = 'absolute';
    div.style.left       = x.toString() + 'px';
    div.style.top        = y.toString() + 'px';
	  div.style.color      = this.color_;
	  div.style.fontFamily = 'Arial';
	  div.style.fontSize   = 'x-small';

    // Sexagesimal (base-sixty) numbers:

	  if ( this.sex_ ) {

      var dms = this.convertDD2DMS( thisLon );

		  var degs = dms[ 0 ];
		  var mins = dms[ 1 ];
      var secs = dms[ 2 ];

		  div.innerHTML = degs + '&deg;&nbsp;' + mins + '&#146;&nbsp;' + secs + '&#148;';
    }

    // Decimal numbers:

    else{
      //div.innerHTML = ( Math.abs( thisLon ) ).toFixed( lonDecs ); // only significant digits
      div.innerHTML = thisLon.toFixed( lonDecs ).toString() + '&deg;';
    }

	  mapDiv.insertBefore( div, null );

    // Save div for later removal:
	
	  this.divs_[ i ] = div;

    // Next vertical line...
	
	  i++;

	  thisLon += dLng;	

	  if ( thisLon > 180.0 ) {
		  maxEast -= 360.0;
		  thisLon -= 360.0;
	  }	
		 		
  } // while

  // Horizontal lines:
 
  // Count lines:
 
  var j = 0;
      
  // Place labels on second row to avoid peripheral controls:

  x = this.map_.fromLatLngToDivPixel( new GLatLng( maxSouth, maxWest + dLng + dLng ) ).x + 3;
 
  var thisLat = maxSouth;
 
  while ( thisLat <= maxNorth ) {

	  var pixel = this.map_.fromLatLngToDivPixel( new GLatLng( thisLat, maxWest ) );

	  // Line:

    // Draw lines across the dateline:

	  if ( maxEast < maxWest ) {
		  this.divs_[ i ] = this.createHLine3( thisLat );
		  mapDiv.insertBefore( this.divs_[ i ], null );
		  i++;
		}

    // Draw lines for world scale zooms:

	  else if ( maxEast == maxWest ) {
		  this.divs_[ i ] = this.createHLine3( thisLat );
		  mapDiv.insertBefore( this.divs_[ i ], null );
		  i++;
		}

    // Otherwise:

	  else {
		  this.divs_[ i ] = this.createHLine( pixel.y );
		  mapDiv.insertBefore( this.divs_[ i ], null );
		  i++;
		}
			
	  // Label:

	  var div = document.createElement( 'div' );

	  y = pixel.y + 2;

	  div.style.position   = 'absolute';
	  div.style.left       = x.toString() + 'px';
	  div.style.top        = y.toString() + 'px';
	  div.style.color      = this.color_;
	  div.style.fontFamily = 'Arial';
	  div.style.fontSize   = 'x-small';

    // Sexagesimal (base-sixty) numbers:
 
	  if( this.sex_ ) {

      var dms = this.convertDD2DMS( thisLat );

      var degs = dms[ 0 ];
      var mins = dms[ 1 ];
      var secs = dms[ 2 ];

      div.innerHTML = degs + '&deg;&nbsp;' + mins + '&#146;&nbsp;' + secs + '&#148;';
    }

    // Decimal numbers:

    else {
      //div.innerHTML = ( Math.abs( thisLat ) ).toFixed( latDecs );
      div.innerHTML = thisLat.toFixed( latDecs ).toString() + '&deg;';
    }

    // Don't put two labels in the same place:
 
	  if ( j != 2 ) {
		  mapDiv.insertBefore( div, null );
		  this.divs_[ i ] = div; // save for remove
		  i++;
	  }

    // Next horizontal line...
	
	  j++;

	  thisLat += dLat; 

  } // while
  
} // redraw()


/*
gridIntervalMins()
*/

LatLonGraticule.prototype.gridIntervalMins = function ( dDeg ) {
  if ( this.sex_ ) {
	  return this.gridIntervalSexMins( dDeg );
  }
  else {
	  return this.gridIntervalDecMins( dDeg );
  }
}


/*
gridIntervalDecMins()
Calculate rounded graticule interval in decimals of degrees for supplied lat/lon
span. Return is in minutes...
*/

LatLonGraticule.prototype.gridIntervalDecMins = function ( dDeg ) {

  // We want around 10 lines in the graticule:

  var dDeg = dDeg / 10;

  // To minutes * 100:

  dDeg *= 6000;

  // Minutes and hundredths of minutes:

  dDeg = Math.ceil( dDeg ) / 100;
 
  // 0.001 degrees:
 
  if ( dDeg <= 0.06 ) {
	  dDeg = 0.06;
  }

  // 0.002 degrees:

  else if ( dDeg <= 0.12 ) {
	  dDeg = 0.12;
  }

  // 0.005 degrees:

  else if ( dDeg <= 0.3 ) {
	  dDeg = 0.3;
  }

  // 0.01 degrees:

  else if ( dDeg <= 0.6 ) {
	  dDeg = 0.6;
  }

  // 0.02 degrees:

  else if ( dDeg <=  1.2 ) {
	  dDeg = 1.2;
  }

  // 0.05 degrees:

  else if ( dDeg <= 3 ) {
	  dDeg = 3;
  }

  // 0.1 degrees:

  else if ( dDeg <= 6 ) {
	  dDeg = 6;
  }

  // 0.2 degrees:

  else if ( dDeg <=  12 ) {
	  dDeg = 12;
  }

  // 0.5 degrees:

  else if ( dDeg <=  30 ) {
	  dDeg = 30;
  }

  // 1 degree:

  else if ( dDeg <=  60 ) {
	  dDeg = 60;
  }

  // 2 degrees:

  else if ( dDeg <= ( 60 * 2 ) ) {
	  dDeg = 60 * 2;
  }

  // 5 degrees:

  else if ( dDeg <= ( 60 * 5 ) ) {
	  dDeg = 60 * 5;
  }

  // 10 degrees:

  else if ( dDeg <= ( 60 * 10 ) ) {
	  dDeg = 60 * 10;
  }

  // 20 degrees:

  else if ( dDeg <= ( 60 * 20 ) ) {
	  dDeg = 60 * 20;
  }

  // 30 degrees:

  else if ( dDeg <= ( 60 * 30 ) ) {
	  dDeg = 60 * 30;
  }

  // 45 degrees:

  else {
	  dDeg = 60 * 45;
  }
 
  return dDeg;

} // gridIntervalDecMins()


/*
gridIntervalSexMins()
Calculate rounded graticule interval in Minutes for supplied lat/lon span.
Return is in minutes...
*/

LatLonGraticule.prototype.gridIntervalSexMins = function ( dDeg ) {

  // We want around 10 lines in the graticule:

  var dDeg = dDeg / 10;

  // To minutes * 100:
 
  dDeg *= 6000;

  // Minutes and hudredths of minutes:

  dDeg = Math.ceil( dDeg ) / 100;

  // 0.01 minutes:
  
  if ( dDeg <= 0.01 ) { 
    dDeg = 0.01;
  }

  // 0.02 minutes:

  else if ( dDeg <= 0.02 ) {
    dDeg = 0.02;
  }

  // 0.05 minutes:

  else if ( dDeg <= 0.05 ) { 
    dDeg = 0.05;
  }

  // 0.1 minutes:

  else if ( dDeg <= 0.1 ) { 
    dDeg = 0.1;
  }

  // 0.2 minutes:

  else if ( dDeg <= 0.2 ) { 
    dDeg = 0.2;
  }

  // 0.5 minutes:

  else if ( dDeg <= 0.5 ) { 
    dDeg = 0.5;
  }

  // 1.0 minute:

  else if ( dDeg <= 1.0 ) { 
    dDeg = 1.0;
  }

  // 0.05 degrees:

  else if ( dDeg <= 3 ) {
	  dDeg = 3;
  }

  // 0.1 degrees:

  else if ( dDeg <= 6 ) {
	  dDeg = 6;
  }
  
  // 0.2 degrees:

  else if ( dDeg <=  12 ) {
	  dDeg = 12;
  }

  // 0.5 degrees:

  else if ( dDeg <=  30 ) {
	  dDeg = 30;
  }

  // 1 degree:

  else if ( dDeg <=  60 ) {
	  dDeg = 60;
  }

  // 2 degrees:

  else if ( dDeg <= ( 60 * 2 ) ) {
	  dDeg = 60 * 2;
  }

  // 5 degrees:

  else if ( dDeg <= ( 60 * 5 ) ) {
	  dDeg = 60 * 5;
  }

  // 10 degrees:

  else if ( dDeg <= ( 60 * 10 ) ) {
	  dDeg = 60 * 10;
  }

  // 20 degrees:

  else if ( dDeg <= ( 60 * 20 ) ) {
	  dDeg = 60 * 20;
  }

  // 30 degrees:

  else if ( dDeg <= ( 60 * 30 ) ) {
	  dDeg = 60 * 30;
  }

  // 45 degrees:

  else {
	  dDeg = 60 * 45;
  }
  
  return dDeg;

} // gridIntervalSexMins()


/*
gridPrecision()
Calculate grid label precision from decimal grid interval in degrees...
*/

LatLonGraticule.prototype.gridPrecision = function( dDeg ) {

  if ( dDeg < 0.01 ) {
	  return 3;
  }
  else if ( dDeg < 0.1 ) {
	  return 2;
  }
  else if ( dDeg < 1 ) {
	  return 1;
  }
  else {
    return 0;
  }

} // gridPrecision()


/*
createVLine() 
Returns a div that is a vertical single pixel line...
*/

LatLonGraticule.prototype.createVLine = function ( x ) {

	var div = document.createElement( 'div' );

	div.style.position        = 'absolute';
	div.style.overflow        = 'hidden';
	div.style.backgroundColor = this.color_;
	div.style.left            = x + 'px';
	div.style.top             = this.minY + 'px';
	div.style.width           = '1px';
	div.style.height          = ( this.maxY - this.minY ) + 'px';

  return div;
	
} // createVLine()


/*
createHLine()
Returns a div that is a horizontal single pixel line...
*/

LatLonGraticule.prototype.createHLine = function ( y ) {

	var div = document.createElement( 'div' );

	div.style.position        = 'absolute';
	div.style.overflow        = 'hidden';
	div.style.backgroundColor = this.color_;
	div.style.left            = this.minX + 'px';
	div.style.top             = y + 'px';
	div.style.width           = ( this.maxX - this.minX ) + 'px';
	div.style.height          = '1px';

  return div;
	
} // createHLine()


/*
createHLine3()
Returns a div that is a horizontal single pixel line, across the dateline.
We find the start and width of a 180 degree line and draw the same amount
to its left and right...
*/

LatLonGraticule.prototype.createHLine3 = function( lat ) {

	var f = this.map_.fromLatLngToDivPixel( new GLatLng( lat, 0   ) );
	var t = this.map_.fromLatLngToDivPixel( new GLatLng( lat, 180 ) );		

	var div = document.createElement( 'div' );

	div.style.position        = 'absolute';
	div.style.overflow        = 'hidden';
	div.style.backgroundColor = this.color_;

	var x1 = f.x;
	var x2 = t.x;

	if ( x2 < x1 ) {
		x2 = f.x;
		x1 = t.x;
	}

	div.style.left   = ( x1 - ( x2 - x1 ) ) + 'px';
	div.style.top    = f.y + 'px';
	div.style.width  = ( ( x2 - x1 ) * 3 ) + 'px';
	div.style.height = '1px';

  return div;
	
} // createHLine3


/*
convertDD2DMS()
Converts decimal degrees (DD) to degrees minutes seconds (DMS)...
Returns array with degrees (index 0), minutes (index 1), seconds (index 2),
which are each returned as integers...
*/

LatLonGraticule.prototype.convertDD2DMS = function ( decimalDegs ) {

  var degs;
  var decimalMins;
  var mins;
  var secs;
  var degsMinsSecs = new Array();

  if ( decimalDegs >= 0 ) {

    degs        = Math.floor( decimalDegs );
    decimalMins = ( decimalDegs - degs ) * 60;
    mins        = Math.floor( decimalMins );
    secs        = Math.round( ( decimalMins - mins ) * 60 );

    if ( secs >= 60 ) {
      mins += 1;
      secs -= 60;
    }

    if ( mins >= 60 ) {
      degs += 1;
      mins -= 60;
    }

  }
  else {

    degs        = Math.ceil( decimalDegs );
    decimalMins = Math.abs( decimalDegs - degs ) * 60;
    mins        = Math.floor( decimalMins );
    secs        = Math.round( ( decimalMins - mins ) * 60 );

    if ( secs >= 60 ) {
      mins += 1;
      secs -= 60;
    }

    if ( mins >= 60 ) {
      degs -= 1;
      mins -= 60;
    }

  }

  degsMinsSecs[ 0 ] = degs;
  degsMinsSecs[ 1 ] = mins;
  degsMinsSecs[ 2 ] = secs;
 
  return degsMinsSecs;

}
