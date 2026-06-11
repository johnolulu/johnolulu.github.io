/*
ruler.js

Source: http://koti.mbnet.fi/ojalesa/exam/ruler.html
Author: Esa Ilmari, 2006; modified 2008

NOTE: Requires ELabel from: http://econym.org.uk/gmap/elabel.js

2009, John Maurer: Minor modifications to function names and polyline
options--polyline opacity and width and geodesic = true; remove
the click listener after the rule has been defined so that user
can return to normal map function afterwards; modify cursor over
map to question mark ("help") until first marker is set. 
*/


/*
Ruler()
Initiate Ruler object...
*/

function Ruler ( map ) {

  this.dist   = 0;
  this.label1;
  this.label2;
  this.line;
  this.map = map;
  this.marker1;
  this.marker2;
  this.poly;

  // For storing whether a marker has been single or double clicked:

  this.markerSingleClicked = false;
  this.markerDoubleClicked = false;
   
  this.mapClickListener;

} // Ruler()


/*
addRuler()
*/

Ruler.prototype.addRuler = function () {

  // Change cursor style to a question mark when over the map:

  this.map.getDragObject().setDraggableCursor( 'help' );

  // Add a listener to define end points by clicking on the map:

  var mapClick          = GEvent.callback( this, this.mapClick  );
  this.mapClickListener = GEvent.addListener( this.map, 'click',
    function ( overlay, point, overlayPoint ) {
      mapClick( overlay, point, overlayPoint );
    }
  );

} // addRuler()


/*
mapClick()
*/

Ruler.prototype.mapClick = function ( overlay, point, overlayPoint ) {

  // Point will be undefined if we're on an overlay, in which case overlayPoint
  // will be defined: 

  var clickPoint;

  if ( point ) {
    clickPoint = point;
  }
  else {
    clickPoint = overlayPoint;
  }     

  // Add start point:

  this.marker1 = new GMarker( clickPoint, { draggable: true } );
  this.map.addOverlay( this.marker1 );
  this.marker1.enableDragging();

  var text1;

  if ( this.dist == 0 ) {
    text1 = 'Drag...';
  }
  else {
    text1 = this.dist;
  }

  this.label1 = new ELabel( clickPoint, text1, 'labelstyle', new GSize( 2, 20 ), 60 );
  this.map.addOverlay( this.label1 );

  // Change the cursor back to its default:

  this.map.getDragObject().setDraggableCursor( "url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default" );

  // Add end point:

  this.marker2 = new GMarker( clickPoint, { draggable: true } );
  this.map.addOverlay( this.marker2 );
  this.marker2.enableDragging();

  var text2;

  if ( this.dist == 0 ) {
    text2 = '';
  }
  else {
    text2 = this.dist;
  }

  this.label2 = new ELabel( clickPoint, text2, 'labelstyle', new GSize( 2,20 ), 60 );
  this.map.addOverlay( this.label2 );

  // Add listeners to drag the start and end points:

  var measure = GEvent.callback( this, this.measure  );

  GEvent.addListener( this.marker1, 'drag',
    function () {
      measure();
    }
  );

  GEvent.addListener( this.marker2, 'drag',
    function () {
      measure();
    }
  );

  // Make an info window appear when a marker is clicked, and clear the ruler
  // when either is double-clicked. GoogleMaps doesn't work to give a marker
  // both a click and a double-click listener, so we're going to listen for a
  // double-click by using a 250 millisecond setTimeout():

  var markerClick = GEvent.callback( this, this.markerClick );

  GEvent.addListener( this.marker1, 'click',
    function ( latLon ) {
      markerClick( latLon );
    }
  );

  GEvent.addListener( this.marker2, 'click',
    function ( latLon ) {
      markerClick( latLon );
    }
  );

} // mapClick()


/*
measure()
*/

Ruler.prototype.measure = function () {

  // If start and end points defined, define polyline and distance:

  if ( this.marker1 && this.marker2 ) {
    this.line = [ this.marker1.getPoint(), this.marker2.getPoint() ];
    this.dist = this.marker1.getPoint().distanceFrom( this.marker2.getPoint() );
    this.dist = this.dist.toFixed( 0 ) + 'm';
  }

  // Convert to kilometers if greater than 10,000 meters:

  if ( parseInt( this.dist ) > 10000 ) {
    this.dist = ( parseInt( this.dist ) / 1000 ).toFixed( 1 ) + 'km';
  }

  // Define labels; the same for both start and end points:

  this.label1.setContents( this.dist );
  this.label2.setContents( this.dist );

  this.label1.setPoint( this.marker1.getPoint() );
  this.label2.setPoint( this.marker2.getPoint() );

  // If there's a previous ruler/polyline displayed, remove it:

  if ( this.poly ) {
    this.map.removeOverlay( this.poly );
  }

  // Define and display the new ruler/polyline:

  this.poly = new GPolyline( this.line, '#FFFF00', 6, 0.7, { geodesic: true } );
  this.map.addOverlay( this.poly );

  // Remove the click listener now that we're done:

  GEvent.removeListener( this.mapClickListener );

} // measure()


/*
clearRuler()
*/

Ruler.prototype.clearRuler = function () {

  this.map.removeOverlay( this.poly    );
  this.map.removeOverlay( this.marker1 );
  this.map.removeOverlay( this.marker2 );
  this.map.removeOverlay( this.label1  );
  this.map.removeOverlay( this.label2  );

  this.dist   = 0;

} // clearRuler()


/*
markerClick()
*/

Ruler.prototype.markerClick = function ( latLon ) {

  if ( this.markerSingleClicked ) {
    this.markerDoubleClicked = true;
  }
  else {
    this.markerSingleClicked = true;
    this.markerDoubleClicked = false;
    setTimeout( this.makeCaller( this.markerClickAction, this, latLon ), 250 );
  }

} // markerClick()


/*
markerClickAction()
*/

Ruler.prototype.markerClickAction =  function ( object, latLon ) {

  // If double-clicked, remove ruler:

  if ( object.markerDoubleClicked ) {
    object.clearRuler();
  }

  // If single-clicked, define and display info pop-up window:

  else {

    // Convert GLatLng object to string:

    var latLonStr = latLon.toString();

    // Split marker location into lat and lon:

    latLonStr.match( /^\((.+), (.+)\)$/ );

    var lat = RegExp.$1;
    var lon = RegExp.$2;

    // Reduce number of digits in map center lat/long:

    lat = parseFloat( lat ).toFixed( 4 );
    lon = parseFloat( lon ).toFixed( 4 );

    // Define text to be displayed when marker is clicked:

    var markerHtml;

    markerHtml = '<p><font class="googleMapMarkerText">Distance end point</font></p><br/>'
               + '<p><font class="googleMapMarkerText">lat, lon: </font>'
               + '<font color="#000000">'
               + lat + ', ' + lon
               + '</font></p>'
               + '<br/><p><font class="SmallTextGray"><i>NOTE: Double-click marker to remove ruler...<br>'
               + 'NOTE: Drag marker to move to a new location...</i></font></p><br/>'
               + '<p class="googleMapMarker"><font size="-1"><a class="googleMapMarker" href="#" onClick="this.blur(); map.panTo( new GLatLng( ' + lat + ',' + lon + ' ) )">Center map here</a></font></p>';

    object.map.openInfoWindowHtml( latLon, markerHtml );
  } 

  // Reset the clicked/double-clicked status:

  object.markerSingleClicked = false;
  object.markerDoubleClicked = false;

} // markerClickAction()

 
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
