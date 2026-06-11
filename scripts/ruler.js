/*
ruler.js

Source: http://koti.mbnet.fi/ojalesa/exam/ruler.html
Author: Esa Ilmari, 2006; modified 2008

NOTE: Requires ELabel from: http://econym.org.uk/gmap/elabel.js
Assumes CSS class named "labelstyle" for ELabel in your document,
or will use default style instead.

2009, John Maurer: Minor modifications to function names and polyline
options--polyline opacity and width and geodesic = true; remove
the click listener after the ruler has been defined so that user
can return to normal map function afterwards; modify cursor over
map to question mark ("help") until first marker is set; line follows
until next click (no longer set markers and drag). Added option for
creating a multi-segment ruler instead of just two points.
*/


/*
Ruler()
Initiate Ruler object...
*/

function Ruler ( map, htmlElement, multiSegment ) {

  // Required:

  this.map = map;

  // Optional:

  this.htmlElement  = htmlElement;
  this.multiSegment = multiSegment || false;

  // Variables:

  this.activeLabel   = null;
  this.activeLine    = null;
  this.distances     = new Array();
  this.infoLabel     = null;
  this.labelOpacity  = 60;
  this.labels        = new Array();
  this.lines         = new Array();
  this.map           = map;
  this.markers       = new Array();
  this.points        = new Array();

  // Line styles:

  this.lineColor   = '#FF0000';
  this.lineWidth   = 6;
  this.lineOpacity = 0.7;
  this.finishColor = '#FFFF00';

  // Various listeners that will be used to control map events:
 
  this.mapClickListener;
  this.mapMouseMoveListener;

  // For storing whether an object has been single or double clicked:

  this.markerSingleClicked = false;
  this.markerDoubleClicked = false;

} // Ruler()


/*
addRuler()
*/

Ruler.prototype.addRuler = function () {

  // Change cursor style to a question mark when over the map:

  this.map.getDragObject().setDraggableCursor( 'help' );

  // Turn off map's double-click zooming until ruler is finished:

  this.map.disableDoubleClickZoom();

  // Add a listener to define end points by clicking on the map:

  var mapClick          = GEvent.callback( this, this.mapClick  );
  this.mapClickListener = GEvent.addListener( this.map, 'click',
    function ( overlay, point, overlayPoint ) {
      mapClick( overlay, point, overlayPoint );
    }
  );

  // Add a listener to draw line between last end point and cursor location:

  var mapMouseMove          = GEvent.callback( this, this.mapMouseMove );
  this.mapMouseMoveListener = GEvent.addListener( this.map, 'mousemove',
    function( point ) {
      mapMouseMove( point );
    }
  );
 
} // addRuler()


/*
mapclick()
*/

Ruler.prototype.mapClick = function ( overlay, point, overlayPoint ) {

  // Point will be undefined if we're on an overlay, in which case overlayPoint
  // will be defined: 
  
  var clickPoint;
  
  if ( point ) {
    clickPoint = point;
  }
  else {
  
    // Ignore clicks on existing markers:
  
    for ( var i in this.markers ) {
      if ( overlay == this.markers[ i ] ) {
        return;
      }
    }
    clickPoint = overlayPoint;
  }     
  
  this.points.push( clickPoint );

  // Get last index of points array so we know current index to use for markers,
  // labels, lines, etc.:

  var currentIndex = this.points.length - 1;

  // Add marker:

  var marker = new GMarker( clickPoint, { draggable: true } );
  this.map.addOverlay( marker );
  marker.enableDragging();

  this.markers.push( marker );

  // Add marker drag listener:

  var markerDrag = GEvent.callbackArgs( this, this.markerDrag, currentIndex  );

  GEvent.addListener( marker, 'drag',
    function () {
      markerDrag( currentIndex );
    }
  );

  // Add marker click listener:

  var markerClick = GEvent.callbackArgs( this, this.markerClick, currentIndex );

  GEvent.addListener( marker, 'click',
    function () {
      markerClick( currentIndex );
    }
  );  

  // Compute total distance along path between all points: 
    
  var totalDistance = 0;

  if ( this.points.length >= 2 ) {

    var thisDistance = this.points[ currentIndex ].distanceFrom( this.points[ currentIndex - 1 ] );

    this.distances.push( thisDistance );

    for ( var i in this.distances ) {
      totalDistance += this.distances[ i ];
    }
  }

  // Add label:

  var distanceLabel = this.distanceLabel( totalDistance );

  var label = new ELabel( clickPoint, distanceLabel, 'labelstyle', new GSize( 2, 20 ), this.labelOpacity );
  this.map.addOverlay( label );

  this.labels.push( label );

  // Add line between this and the last defined point, if any:

  var color;

  if ( this.multiSegment ) {
    color = this.lineColor;
  }
  else {
    color = this.finishColor;
  }

  if ( this.points.length >= 2 ) {
    var line = new GPolyline( [ this.points[ this.points.length - 2 ], this.points[ this.points.length - 1 ] ], color, this.lineWidth, this.lineOpacity, { geodesic: true } );
    this.map.addOverlay( line );
    this.lines.push( line );
  }

  // If this is the second click, finish the ruler if not multi-segment;
  // in either case, add a fading informative label about double-clicking:
  
  if ( this.points.length == 2 ) {

    if ( this.multiSegment ) {
      this.infoLabel = new ELabel( clickPoint, 'Double-click&nbsp;any&nbsp;marker&nbsp;to&nbsp;stop&nbsp;adding&nbsp;new&nbsp;points...', 'labelstyle', new GSize( 8, 42 ), this.labelOpacity );
    }
    else {
      this.finishRuler();
      this.infoLabel = new ELabel( clickPoint, 'Double-click&nbsp;any&nbsp;marker&nbsp;to&nbsp;remove&nbsp;distance...', 'labelstyle', new GSize( 8, 42 ), this.labelOpacity );
    }

    this.map.addOverlay( this.infoLabel );
    fadeLabel = this.makeCaller( this.fadeLabel, this );
    setTimeout( fadeLabel, 750 );
  }

} // mapClick()


/*
mapMouseMove()
*/

Ruler.prototype.mapMouseMove = function ( cursorLatLng ) {

  if ( this.points.length != 0 ) {
    
    // Remove any previously displayed active line and label:
    
    if ( this.activeLine ) {
      this.map.removeOverlay( this.activeLine );
    }

    if ( this.activeLabel ) {
      this.map.removeOverlay( this.activeLabel );
    }

    // Set start point to location of most recent marker:

    var start = this.points[ this.points.length - 1 ];
    
    // Define new polyline:
  
    var color;

    if ( this.multiSegment ) {
      color = this.lineColor;
    }
    else {
      color = this.finishColor;
    }
  
    this.activeLine = new GPolyline( [ start, cursorLatLng ], color, this.lineWidth, this.lineOpacity, { geodesic: true } );
    this.map.addOverlay( this.activeLine );

    // Compute current total distance along path between all points: 

    var totalDistance    = 0;

    var cursorDistance = this.points[ this.points.length - 1 ].distanceFrom( cursorLatLng );

    var previousDistance = 0;

    for ( var i = 1; i < this.points.length; i++ ) {
      var thisDistance = this.points[ i ].distanceFrom( this.points[ i - 1 ] );
      previousDistance += thisDistance;
    }

    totalDistance = previousDistance + cursorDistance;

    // Define new label:

    var distanceLabel = this.distanceLabel( totalDistance );

    this.activeLabel = new ELabel( cursorLatLng, distanceLabel, 'labelstyle', new GSize( 30, 20 ), this.labelOpacity );
    this.map.addOverlay( this.activeLabel );

  }

} // mapMouseMove() 


/*
markerDrag()
*/

Ruler.prototype.markerDrag = function ( index ) {

  // Set the new location for this marker in the points array:

  var dragPoint = this.markers[ index ].getPoint();
  this.points[ index ] = dragPoint;

  // Update label(s) with new distance(s):

  if ( this.points.length >= 2 ) {

    // Reset the distances array:

    this.distances = [];

    var totalDistance = 0;
    
    for ( var i = 1; i < this.points.length; i++ ) {

      var thisDistance = this.points[ i ].distanceFrom( this.points[ i - 1 ] );

      this.distances.push( thisDistance );

      totalDistance += thisDistance;

      var distanceLabel = this.distanceLabel( totalDistance );

      this.labels[ i ].setContents( distanceLabel );
    }
  } 

  // Move label to drag location:

  this.labels[ index ].setPoint( dragPoint );

  // Replace line(s), if any:

  if ( this.lines ) {

    var newLine;
    var newLineColor;

    if ( this.mapClickListener ) {
      newLineColor = this.lineColor;
    }
    else {
      newLineColor = this.finishColor;
    }

    // Redefine line after first point:

    if ( index == 0 ) {
      this.map.removeOverlay( this.lines[ 0 ] );    
      newLine = new GPolyline( [ this.points[ 0 ], this.points[ 1 ] ], newLineColor, this.lineWidth, this.lineOpacity, { geodesic: true } );
      this.lines[ 0 ] = newLine;
      this.map.addOverlay( newLine );
    }

    // Redefine line before current point and the line after it, if any:

    else {

      // Line before current point:

      this.map.removeOverlay( this.lines[ index - 1 ] );
      newLine = new GPolyline( [ this.points[ index - 1 ], this.points[ index ] ], newLineColor, this.lineWidth, this.lineOpacity, { geodesic: true } );
      this.lines[ index - 1 ] = newLine; 
      this.map.addOverlay( newLine );

      // Line after current point, if any:

      if ( this.lines[ index ] ) {

        this.map.removeOverlay( this.lines[ index ] );
        newLine = new GPolyline( [ this.points[ index ], this.points[ index + 1 ] ], newLineColor, this.lineWidth, this.lineOpacity, { geodesic: true } );
        this.lines[ index ] = newLine;
        this.map.addOverlay( newLine );
      } 

    } // else

  } // if

} // markerDrag()


/*
markerClick()
Make an info window appear when a marker is clicked, and clear the ruler
when either is double-clicked. GoogleMaps doesn't work to give a marker
both a click and a double-click listener, so we're going to listen for a
double-click by using a 250 millisecond setTimeout():
*/

Ruler.prototype.markerClick = function ( index ) {

  if ( this.markerSingleClicked ) {
    this.markerDoubleClicked = true;
  }
  else {
    this.markerSingleClicked = true;
    this.markerDoubleClicked = false;
    setTimeout( this.makeCaller( this.markerClickAction, this, index ), 250 );
  }

} // markerClick()


/*
markerClickAction()
*/

Ruler.prototype.markerClickAction =  function ( object, index ) {

  // If double-clicked, prevent ruler from having additional vertices;
  // change style of lines, markers, and cursor; if this has already been
  // done, then double-clicking will remove ruler instead: 

  if ( object.markerDoubleClicked ) {
    
    if ( object.mapClickListener ) {

      object.finishRuler();
 
      // Add fading label about double-clicking:
 
      object.infoLabel = new ELabel( object.points[ index ], 'Double-click&nbsp;any&nbsp;marker&nbsp;to&nbsp;remove&nbsp;distance...', 'labelstyle', new GSize( 8, 42 ), object.labelOpacity );
      object.map.addOverlay( object.infoLabel );
      fadeLabel = object.makeCaller( object.fadeLabel, object );
      setTimeout( fadeLabel, 750 );
    }
    else {
      object.removeRuler();
    }

  }

  // If single-clicked, define and display info pop-up window:

  else {

    // Get location of the marker at this index:

    var latLng = object.markers[ index ].getLatLng();

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

    var doubleClickInfo;

    if ( object.mapClickListener ) {
      doubleClickInfo = 'Double-click marker to stop adding new vertices...';
    }
    else {
      doubleClickInfo = 'Double-click marker to remove ruler from the map...';
    }

    var markerHtml;
    var markerHeading;

    if ( index == 0 ) {
      markerHeading = 'Distance start point';
    }
    else if ( index == object.markers.length - 1 ) {
      markerHeading = 'Distance end point';
    }
    else {
      markerHeading = 'Distance vertex';
    }
 
    markerHtml = '<p><font class="googleMapMarkerText">' + markerHeading + '</font></p><br/>'
               + '<p><font class="googleMapMarkerText">lat, lon: </font>'
               + '<font color="#000000">'
               + lat + ', ' + lon
               + '</font></p>'
               + '<br/><p><font class="SmallTextGray"><i>NOTE: ' + doubleClickInfo + '<br>'
               + 'NOTE: Drag marker to move to a new location...</i></font></p>';

    object.map.openInfoWindowHtml( latLng, markerHtml );
  } 

  // Reset the clicked/double-clicked status:

  object.markerSingleClicked = false;
  object.markerDoubleClicked = false;

} // markerClickAction()


/*
distanceLabel()
Define label to use for specified distance in meters.
*/

Ruler.prototype.distanceLabel = function ( distance ) {

  // Strip off any decimal places:

  distance = distance.toFixed( 0 ) + '&nbsp;m';

  // Convert to kilometers if greater than 10,000 meters:

  if ( parseInt( distance ) > 10000 ) {
    distance = ( parseInt( distance ) / 1000 ).toFixed( 1 ) + '&nbsp;km';
  }

  return distance;

} // distanceLabel()


/*
finishRuler()
Stop adding new vertices to the ruler...
*/

Ruler.prototype.finishRuler = function () {

  if ( this.mapClickListener ) {
    GEvent.removeListener( this.mapClickListener );
    this.mapClickListener = null;
  } 

  if ( this.mapMouseMoveListener ) {
    GEvent.removeListener( this.mapMouseMoveListener );
    this.mapMouseMoveListener = null;
  }

  if ( this.activeLine ) {
    this.map.removeOverlay( this.activeLine );
    this.activeLine = null;
  }

  if ( this.activeLabel ) {
    this.map.removeOverlay( this.activeLabel );
    this.activeLabel = null;
  }

  if ( this.infoLabel ) {
    this.map.removeOverlay( this.infoLabel );
    this.infoLabel = null;
  }

  for ( var i = 0; i < this.lines.length; i++ ) {
    this.lines[ i ].setStrokeStyle( { color: this.finishColor } );
  }

  this.map.getDragObject().setDraggableCursor( 'url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default' );

  this.map.enableDoubleClickZoom();

  // Set user-specified html style back to normal (optional):

  if ( this.htmlElement ) {
    this.htmlElement.style.color     = 'GOLD';
    this.htmlElement.style.fontStyle = 'normal';
    this.htmlElement.title           = 'Measure distance between two or more points; click on map to set points...';
  }

} // finishRuler()


/*
removeRuler()
*/

Ruler.prototype.removeRuler = function () {

  // Remove map click listener:

  if ( this.mapClickListener != null ) {
    GEvent.removeListener( this.mapClickListener );
    this.mapClickListener = null;
  }

  // Remove map mousemove listener:

  if ( this.mapMouseMoveListener != null ) {
    GEvent.removeListener( this.mapMouseMoveListener );
    this.mapMouseMoveListener = null;
  }

  // Remove all markers and labels:
  
  for ( var i in this.markers ) {
    this.map.removeOverlay( this.markers[ i ] );
    this.map.removeOverlay( this.labels[ i ]  );
  }

  // Remove all lines:

  for ( var i in this.lines ) {
    this.map.removeOverlay( this.lines[ i ] );
  }

  // Remove active line and label:

  if ( this.activeLine ) {
    this.map.removeOverlay( this.activeLine );
  }

  if ( this.activeLabel ) {
    this.map.removeOverlay( this.activeLabel );
  }

  if ( this.infoLabel ) {
    this.map.removeOverlay( this.infoLabel );
  }

} // removeRuler()


/*
fadeLabel()
Successively increases opacity of infoLabel ELabel until it disappears...
*/

Ruler.prototype.fadeLabel = function ( object ) {

  var milliseconds = 450;

  for ( var newOpacity = object.labelOpacity; newOpacity >= 0; newOpacity -= 5 ) {

    var setOpacity = object.makeCaller( object.setOpacity, object, newOpacity );
    setTimeout( setOpacity, milliseconds += 50 );

    // When opacity is 0 (all transparent), hide the label entirely:

    if ( newOpacity == 0 ) {
      var hideLabel = object.makeCaller( object.hideLabel, object );
      setTimeout( hideLabel, milliseconds += 50 );
    }

  }

} // fadeLabel()


/*
setOpacity()
Set opacity (0-100) of infoLabel...
*/

Ruler.prototype.setOpacity = function ( object, opacity ) {
  object.infoLabel.setOpacity( opacity );
}


/*
hideLabel()
Set infoLabel ELabel to hidden...
*/

Ruler.prototype.hideLabel = function ( object ) {
  object.infoLabel.hide();
}


/*
makerCaller()
This fuction turns the first argument into a function with up to 10 optional
arguments. Used in event listeners like GEvent.addListener() and setTimeout() so
they properly handle arguments.
*/

Ruler.prototype.makeCaller = function ( func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ) {
  return function () {
    func( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 );
  };
}
