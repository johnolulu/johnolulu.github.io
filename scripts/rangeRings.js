/*
rangeRings.js
Authors: Bill Chadwick, 2008; John Maurer, 2009
Source: http://www.bdcc.co.uk/Gmaps/BdccGmapBits.htm

Modified by John Maurer, 2009: Clean up code style, add marker at origin; marker
can drag to new origin, single-click to get origin lat/lng, or double-click to
remove range rings. Color of range rings can be specified differently for map
versus satellite type.

This code displays circular rings showing distance from a point on the map.
The interval between rings is user choice or automatic. Can be set to:

1: null in which case the interval is automatic depending on zoom level, showing
   several rings on screen.
2: A single number specifying a fixed interval between rings in meters.
3: An array of ring spacings in meters.

maxRings is used for auto and fixed interval to limit the number of rings drawn
(not used with an interval array). If it is null, rings will be drawn to twice
the map's diagonal distance.

If user labels are wanted, labels should be an array of length maxRings or the
length of the interval array.

If interval is an array, color can be a matching length array to give each
ring a specific color.
*/

/*
RangeRings()
*/

function RangeRings ( map, htmlElement, colorMap, colorSat, weight, opacity, interval, maxRings, labels ) {

  // Required:

  this.map = map;

  // Optional:

  this.htmlElement = htmlElement;
  this.colorMap    = colorMap || '#0000FF';  // ring color on Map or Terrain 
  this.colorSat    = colorSat || '#FFFF00'; // ring color on Satellite or Hybrid
  this.weight      = weight   || 4;
  this.opacity     = opacity  || 0.5;
  this.interval    = interval;
  this.maxRings    = maxRings;
  this.labels      = labels;

  // Variables:

  this.circles = new Array();
  this.divs    = new Array(); // labels
  this.marker  = null;
  this.origin  = null;

  // Various listeners that will be used to control map events:

  this.mapMoveEndListener     = null;
  this.mapMoveStartListener   = null;
  this.mapTypeChangedListener = null;

  // For storing whether an object has been single or double clicked:
 
  this.markerSingleClicked = false;
  this.markerDoubleClicked = false;
  this.clickTimeout        = null;

} // RangeRings()


/*
addRangeRings()
*/

RangeRings.prototype.addRangeRings = function () {

  // Change cursor style to a question mark when over the map:

  this.map.getDragObject().setDraggableCursor( 'help' );

  // Listen for click location to define center of range rings: 

  var mapClick          = GEvent.callback( this, this.mapClick );
  this.mapClickListener = GEvent.addListener( map, 'click',
    function( overlay, point, overlayPoint ) {
      mapClick( overlay, point, overlayPoint );
    }
  );
  
  // Re-draw range rings after map is moved or map type is changed:
  
  var redrawRangeRings = GEvent.callback( this, this.redrawRangeRings );
  
  this.mapMoveEndListener = GEvent.addListener( this.map, 'moveend',
    function () {
      redrawRangeRings();
    }
  );

  this.mapTypeChangedListener = GEvent.addListener( this.map, 'maptypechanged',
    function () {
      redrawRangeRings();
    }
  );

  // And undraw range rings during map moves - for speed:

  var undrawRangeRings      = GEvent.callback( this, this.undrawRangeRings );
  this.mapMoveStartListener = GEvent.addListener( this.map, 'movestart',
    function () {
      undrawRangeRings();
    }
  );

} // addRangeRings()


/*
mapClick()
*/

RangeRings.prototype.mapClick = function ( overlay, point, overlayPoint ) {

  // Point will be undefined if we're on an overlay, in which case overlayPoint
  // will be defined: 

  var clickPoint;

  if ( point ) {
    clickPoint = point;
  }
  else {
    clickPoint = overlayPoint;
  }

  // Draw range rings centered at click point:

  this.drawRangeRings( clickPoint );

  // Add a marker at the clicked point:

  this.marker = new GMarker( clickPoint, { title: 'Range rings center point', draggable: true } );
  this.map.addOverlay( this.marker );

  // Add marker click listener:

  var markerClick = GEvent.callback( this, this.markerClickTest );

  GEvent.addListener( this.marker, 'click',
    function () {
      markerClick();
    }
  );
 
  // Add marker drag start/end listeners:

  var undrawRangeRings = GEvent.callback( this, this.undrawRangeRings );

  GEvent.addListener( this.marker, 'dragstart',
    function () {
      undrawRangeRings();
    }
  );

  var drawRangeRings = GEvent.callback( this, this.drawRangeRings );

  GEvent.addListener( this.marker, 'dragend',
    function ( point ) {
      drawRangeRings( point );
    }
  );

  // Remove the map click listener now that the range rings are displayed:

  GEvent.removeListener( this.mapClickListener );
  this.mapClickListener = null;

  // Change the cursor back to its default:

  this.map.getDragObject().setDraggableCursor( "url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default" );
  
} // mapClick()


/*
drawRangeRings()

Redraw the rings based on the current projection and zoom level.
*/

RangeRings.prototype.drawRangeRings = function( origin ) {

  this.origin = origin;
 
  // Draw rings:
 
  var bnds    = this.map.getBounds();
  var sz      = this.map.getSize();
  var pxDiag  = Math.sqrt( ( sz.width * sz.width ) + ( sz.height * sz.height ) );
  var diagKm  = bnds.getNorthEast().distanceFrom( bnds.getSouthWest() ) / 1000.0;
  var pxPerKm = pxDiag / diagKm;
  var d; // km initial/min interval

  if ( this.interval == null ) {

    // Auto interval:
    
    var width  = sz.width  / pxPerKm;
    var height = sz.height / pxPerKm;  
    var ww     = Math.max( width, height ); 
  
    if ( ww < 1.0) {
      d = 0.1;
    }
    else if ( ww < 2.0 ) {
      d = 0.2;
    }
    else if ( ww < 5.0 ) {
      d = 0.5;
    }
    else if ( ww < 10.0 ) {
      d = 1.0;
    }
    else if ( ww < 20.0 ) {
      d = 2.0;
    }
    else if ( ww < 50.0 ) {
      d = 5.0;
    }
    else if ( ww < 100.0 ) {
      d = 10.0;
    }
    else if ( ww < 200.0 ) {
      d = 20.0;
    }
    else if ( ww < 500.0 ) {
      d = 50.0;
    }
    else if ( ww < 1000.0 ) {
      d = 100.0;
    }
    else if ( ww < 2000.0 ) {
      d = 200.0;
    }
    else if ( ww < 5000.0 ) {
      d = 500.0;
    }
    else {
      d = 1000.0;
    }
  }
  else if ( this.interval.constructor.toString().indexOf( 'Array' ) == -1 ) {

    // Convert from meters to kilometers:

    d = this.interval / 1000.0;
  }
  else {

    // An array of distances:

    d = this.interval;
  }
  
  if ( d.constructor.toString().indexOf( 'Array' ) == -1 ) {

    // Precision for label distances in kilometers:

    var p;

    if ( d >= 10.0 ) {
      p = 0;
    }
    else {
      p = 1;
    }

    if ( this.maxRings == null ) {

      // Draw the rings to no more than twice the screen diagonal, auto or
      // fixed interval; no custom labels as # rings drawn varies:

      for ( var r = d; ( r < ( diagKm * 2 ) ); r += d ) {
        this.drawCircle( r, r.toFixed( p ) + '&nbsp;km', this.colorMap, this.colorSat );
      }
    }
    else {

      // Draw maxRings rings auto or fixed interval:

		  var r = d;

      for ( var i = 0; i < this.maxRings; i++ ) {
        if ( this.labels == null ) {
          this.drawCircle( r, r.toFixed( p ) + '&nbsp;km', this.colorMap, this.colorSat ); 
        }
        else {
          this.drawCircle( r, this.labels[ i ], this.colorMap, this.colorSat );
        }
        r += d;
      }
    }
  }

  // Interval array used:

  else {

    for ( var i = 0; i < d.length; i++ ) {

      var cMap;

      if ( this.colorMap.constructor.toString().indexOf( 'Array' ) == -1 ) {
        cMap = this.colorMap;
      }
      else {
        cMap = this.colorMap[ i ];
      }

      var cSat;

      if ( this.colorSat.constructor.toString().indexOf( 'Array' ) == -1 ) {
        cSat = this.colorSat;
      }
      else {
        cSat = this.colorSat[ i ];
      }

      if ( this.labels == null ) {
        this.drawCircle( d[ i ] / 1000.0, d[ i ].toFixed( p ) + 'km', cMap, cSat ); 
      }
      else {
        this.drawCircle( d[ i ] / 1000.0, this.labels[ i ], cMap, cSat );
      }

    } // for

  } // else

} // drawRangeRings()


/*
pointAtRangeAndBearing()

Get a new GLatLng distanceMeters away on the compass bearing azimuthDegrees
from the GLatLng point - accurate to better than 200m in 140km (20m in 14km)
in the UK.
*/

RangeRings.prototype.pointAtRangeAndBearing = function ( point, distanceMeters, azimuthDegrees ) {

  var latr     = point.lat() * Math.PI / 180.0;
  var lonr     = point.lng() * Math.PI / 180.0;
  var coslat   = Math.cos( latr ); 
  var sinlat   = Math.sin( latr ); 
  var az       = azimuthDegrees * Math.PI / 180.0;
  var cosaz    = Math.cos( az ); 
  var sinaz    = Math.sin( az ); 
  var dr       = distanceMeters / 6378137.0; // distance in radians using WGS84 Equatorial Radius
  var sind     = Math.sin( dr ); 
  var cosd     = Math.cos( dr );
  var newLat   = Math.asin( ( sinlat * cosd ) + ( coslat * sind * cosaz ) ) * 180.0 / Math.PI;
  var newLon   = ( Math.atan2( ( sind * sinaz ), ( coslat * cosd ) - ( sinlat * sind * cosaz ) ) + lonr ) * 180.0 / Math.PI;
  var newPoint = new GLatLng( newLat, newLon );

  return newPoint; 
}


/*
drawCircle()
*/

RangeRings.prototype.drawCircle = function ( rKm, label, colorMap, colorSat ) {

  if ( r < 0 ) {
    return;
  }

  if ( r > ( 6378137.0 * Math.PI * 2 ) ) {
    return;
  }

  // Select color of rings based on current map type:

  var color;
  var mapType = this.map.getCurrentMapType().getName();

  if ( mapType == 'Map' || mapType == 'Terrain' ) {
    color = colorMap;
  }
  else {
    color = colorSat;
  }

  var b;
  var c;
  var mapDiv = this.map.getPane( G_MAP_MARKER_SHADOW_PANE );
  var pts    = new Array();
  var r      = rKm * 1000.0;

  // Use 40 segment polyline to approximate a circle:

  for ( b = 0; b <= 360; b += 9 ) {

    pts.push( this.pointAtRangeAndBearing( this.origin, r, b ) );

    if ( ( b % 45 == 0 ) && ( b != 360 ) ) {

      // Draw a label every 45 degrees:

      var p  = this.map.fromLatLngToDivPixel( pts[ pts.length - 1 ] );
      var dv = document.createElement( 'div' );

      mapDiv.insertBefore( dv, null );

      dv.style.position        = 'absolute';
      dv.style.border          = 'none';
      //dv.style.color           = '#000000';
      //dv.style.backgroundColor = '#FFFFFF';
      //dv.style.fontWeight      = 'bold';
      //dv.style.opacity         = this.opacity; 
      dv.style.color           = color;
      //dv.style.fontFamily      = 'Arial';
      dv.style.fontSize        = 'x-small';
      dv.innerHTML             = label;

      var dx;
      var dy;

      // Offset the labels to be just outside the ring:

      if ( b == 0 ) {
        dx = -( dv.offsetWidth ) * 0.5;
        dy = -( dv.offsetHeight );
      }
      else if ( b == 45 ) {
        dx = 3;
        dy = -( dv.offsetHeight );
      }
      else if ( b == 90 ) {
        dx = 3;
        dy = -( dv.offsetHeight ) * 0.5;
      }
      else if ( b == 135 ) {
        dx = 3;
        dy = 3;
      }
      else if ( b == 180 ) {
        dx = -( dv.offsetWidth ) * 0.5;
        dy = 3;
      }
      else if ( b == 225 ) {
        dx = -( dv.offsetWidth ) - 3;
        dy = 3;
      }
      else if ( b == 270 ) {
        dx = -( dv.offsetWidth ) - 3;
        dy = -( dv.offsetHeight ) * 0.5;
      }
      else if ( b == 315 ) {
        dx = -( dv.offsetWidth ) - 3;
        dy = -( dv.offsetHeight );
      }
			
      dv.style.left = ( p.x + dx ).toString() + 'px';
      dv.style.top  = ( p.y + dy ).toString() + 'px';

      this.divs.push( dv );

    } // if
  } // for

  var c = new GPolyline( pts, color, this.weight, this.opacity );

  this.map.addOverlay( c );
  this.circles.push( c );

} // drawCircle()


/*
markerClickTest()
*/

RangeRings.prototype.markerClickTest = function () {
  var thisObject = this;
  if ( window.clickTimeoutTest ) {
    this.markerDoubleClickAction();
  }
  else {
    window.clickTimeoutTest = setTimeout( function () { thisObject.markerSingleClickAction(); }, 250 );
  }
}

RangeRings.prototype.markerDoubleClickAction = function () {
  clearTimeout( window.clickTimeoutTest );
  this.removeRangeRings();
}

/*
markerClick()
Make an info window appear when the marker is clicked, and make the marker and
rings disappear when it is double-clicked. Google Maps doesn't work to give a 
marker both a click and a double-click listener, so we're going to listen for a
double-click by using a 250 millisecond setTimeout()...
*/

window.rrSingleClicked = false;
window.rrClickTimeout  = null;

RangeRings.prototype.markerClick = function () {

  /*
  if ( this.markerSingleClicked ) {
    clearTimeout( this.clickTimeout );
    this.removeRangeRings();
    alert( 'anything' );
    this.markerSingleClicked = false;
  }
  else {
    this.markerSingleClicked = true;
    this.clickTimeout = setTimeout( this.makeCaller( this.markerSingleClickAction, this ), 250 );
  }
  */
 
  //alert( 'markerClick #1: ' + rrSingleClicked );
 
  if ( window.rrSingleClicked ) {
    alert( 'markerClick #3a: ' + window.rrSingleClicked );
    clearTimeout( window.rrClickTimeout );
    this.removeRangeRings();
    window.rrSingleClicked = false;
    //alert( 'markerClick #3b: ' + window.rrSingleClicked );
  }
  else {
    //alert( 'markerClick #2a: ' + window.rrSingleClicked );
    window.rrSingleClicked = true;
    //alert( 'markerClick #2b: ' + window.rrSingleClicked );
    var thisObj = this;
    var singleClickedTest = window.rrSingleClicked;
    window.rrClickTimeout = setTimeout( function () { thisObj.markerSingleClickAction(); }, 250 );
    //alert( 'markerClick #2c: ' + window.rrSingleClicked );
  }

} // markerClick()


/*
markerSingleClickAction()
*/

RangeRings.prototype.markerSingleClickAction = function () {

  // Get location of marker:

  var latLng = this.marker.getLatLng();

  // Convert GLatLng object to string:

  var latLngStr = latLng.toString();

  // Split marker location into lat and lon:

  latLngStr.match( /^\((.+), (.+)\)$/ );

  var lat = RegExp.$1;
  var lon = RegExp.$2;

  // Reduce number of digits in map center lat/long:

  lat = parseFloat( lat ).toFixed( 4 );
  lon = parseFloat( lon ).toFixed( 4 );

  // Define text to be displayed when marker is clicked:

  var markerHtml;

  markerHtml = '<p><font class="googleMapMarkerText">Range rings center point</font></p><br/>'
             + '<p><font class="googleMapMarkerText">lat, lon: </font>'
             + '<font color="#000000">'
             + lat + ', ' + lon
             + '</font></p>'
             + '<br/><p><font class="SmallTextGray"><i>NOTE: Double-click marker to remove range rings...<br>'
             + 'NOTE: Drag marker to move to a new location...</i></font></p><br/>'
             + '<p class="googleMapMarker"><font size="-1"><a class="googleMapMarker" href="#" onClick="this.blur(); map.panTo( new GLatLng( ' + lat + ',' + lon + ' ) )">Center map here</a></font></p>';

  this.map.openInfoWindowHtml( latLng, markerHtml );

  // Reset the marker click status:

  rrSingleClicked = false;
  window.clickTimeoutTest = 0;

} // markerSingleClickAction()


/*
redrawRangeRings()
*/

RangeRings.prototype.redrawRangeRings = function () {

  this.undrawRangeRings();
  this.drawRangeRings( this.origin );

}


/*
undrawRangeRings()
*/

RangeRings.prototype.undrawRangeRings = function () {

  var div = this.map.getPane( G_MAP_MARKER_SHADOW_PANE );

  try {

    var i = 0;

    for ( i = 0; i < this.circles.length; i++ ) {
      this.map.removeOverlay( this.circles[ i ] );
    }
  }
  catch( e ) {
    // Do nothing...
  }

  try {

    var i = 0;

    for ( i = 0; i < this.divs.length; i++ ) {
      div.removeChild( this.divs[ i ] );
    }

  }
  catch( e ) {
    // Do nothing...
  }

  this.circles = new Array();
  this.divs    = new Array();

} // undrawRangeRings()


/*
removeRangeRings()
*/

RangeRings.prototype.removeRangeRings = function () {

  // Undraw range rings:

  this.undrawRangeRings();

  // Remove marker at origin:

  if ( this.marker ) {
    this.map.removeOverlay( this.marker );
  }

  // Remove all map listeners:

  if ( this.mapClickListener ) {
    GEvent.removeListener( this.mapClickListener );
    this.mapClickListener = null;
  } 

  if ( this.mapMoveEndListener ) {
    GEvent.removeListener( this.mapMoveEndListener );
    this.mapMoveEndListener = null;
  }

  if ( this.mapMoveStartListener ) {
    GEvent.removeListener( this.mapMoveStartListener );
    this.mapMoveStartListener = null;
  }

  if ( this.mapTypeChangedListener ) {
    GEvent.removeListener( this.mapTypeChangedListener );
    this.mapTypeChangedListener = null;
  }

  // Set user-specified html style back to normal (optional):

  if ( this.htmlElement ) {
    this.htmlElement.style.color     = 'GOLD';
    this.htmlElement.style.fontStyle = 'normal';
    this.htmlElement.title           = 'Click a point on the map to display the distance from that point in a series of rings...';
  }

} // removeRangeRings()

/*
makerCaller()
This fuction turns the first argument into a function with up to 10 optional
arguments. Used in event listeners like GEvent.addListener() and setTimeout() so
they properly handle arguments.
*/

RangeRings.prototype.makeCaller = function ( func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ) {
  return function () {
    func( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 );
  };
}
