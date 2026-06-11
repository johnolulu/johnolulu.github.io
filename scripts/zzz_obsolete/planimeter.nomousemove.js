/*
planimeter.js
Author: Acme Laboratories
Source: http://acme.com/planimeter/

Modified by John Maurer, 2009--used prototype-based coding, cleaned up code
style, made markers draggable, double-click to denote last end point and to
remove planimeter.

NOTE: Requires ELabel from: http://econym.org.uk/gmap/elabel.js

This JavaScript code adds a planimeter, or area calculator, to the specified
Google Map API object. Click three or more points to view the computed area.
Run ( new planimeter() ).addPlanimeter( map ) to kick it off...
*/

/*
Planimeter()
Define Planimeter object...
Define style based on user input or defaults... 
Define other variables used throughout object...
*/

function Planimeter ( map, htmlElement, lineWidth, lineColor, closerColor, finishColor, polygonFillColor, polygonFillOpacity ) {

  this.map                = map;
  this.htmlElement        = htmlElement;
  this.lineWidth          = lineWidth          || 5;
  this.lineColor          = lineColor          || '#FF0000';
  this.closerColor        = closerColor        || '#0000FF';
  this.finishColor        = finishColor        || '#FFFF00';
  this.polygonFillColor   = polygonFillColor   || '#FFFFFF';
  this.polygonFillOpacity = polygonFillOpacity || 0.5;

  this.points             = new Array();
  this.markers            = new Array();
  this.label              = null; 
  this.lines              = new Array();
  this.polygonPoints      = new Array();
  this.polygon            = null;

  // Conversion factors for various units:

  this.metersPerKm       = 1000.0;
  this.meters2PerHectare = 10000.0;
  this.feetPerMeter      = 3.2808399;
  this.feetPerMile       = 5280.0;
  this.acresPerMile2     = 640;
  this.earthRadiusMeters = 6367460.0;
  this.metersPerDegree   = 2.0 * Math.PI * this.earthRadiusMeters / 360.0;
  this.radiansPerDegree  = Math.PI / 180.0;
  this.degreesPerRadian  = 180.0   / Math.PI;

  // Define red and blue marker icons; blue will be used to designate
  // the most recently clicked point:
  
  this.redIcon                  = new GIcon( G_DEFAULT_ICON );
  this.redIcon.image            = 'http://www2.hawaii.edu/~jmaurer/icons/gmap_markers/red.png';
  this.redIcon.shadow           = 'http://www2.hawaii.edu/~jmaurer/icons/gmap_markers/shadow.png';
  this.redIcon.iconSize         = new GSize( 20, 34 );
  this.redIcon.shadowSize       = new GSize( 37, 34 );
  this.redIcon.iconAnchor       = new GPoint( 9, 34 );
  this.redIcon.infoWindowAnchor = new GPoint( 9, 2 );
  this.redIcon.infoShadowAnchor = new GPoint( 18, 25 );
  
  this.blueIcon                 = new GIcon( this.redIcon );
  this.blueIcon.image           = 'http://www2.hawaii.edu/~jmaurer/icons/gmap_markers/blue.png';

  // Various listeners that will be used to control map events:

  this.mapClickListener;
  this.markerClickListener;
  this.markerDragListener;

  // Track whether an object is single- or double-clicked:

  this.markerSingleClicked = false;
  this.markerDoubleClicked = false;

} // Planimeter()

 
/*
addPlanimeter()
Listen for clicks on the map and run mapClick() after each click...
*/

Planimeter.prototype.addPlanimeter = function () {

  // Change cursor type to question mark as a hint that user should click
  // on the map:

  this.map.getDragObject().setDraggableCursor( 'help' );

  // Add a listener to define area vertices by clicking on the map:

  var mapClick          = GEvent.callback( this, this.mapClick  );
  this.mapClickListener = GEvent.addListener( this.map, 'click',
    function ( overlay, point, overlayPoint ) {
      mapClick( overlay, point, overlayPoint ); 
    }
  );

} // addPlanimeter()


/*
mapClick()
Get click location and re-run display()...
*/

Planimeter.prototype.mapClick = function ( overlay, point, overlayPoint ) {

  // If we're not over an overlay (marker or polygon or polyline), 
  // get the click location from point:

  if ( overlay == null && point != null ) {
    this.points.push( point );
    this.display();
  }

  // Point will be undefined if overlay is defined; so
  // get point location from overlayPoint instead:

  else if ( overlay == this.polygon ) {
    this.points.push( overlayPoint );
    this.display();
  }

} // mapClick()


/*
display()
Initiate and display results:
*/
 
Planimeter.prototype.display =  function () {

  // Clear all previously displayed planimeter markers:

  for ( var i = 0; i < this.markers.length; i++ ) {
    this.map.removeOverlay( this.markers[ i ] );
  }

  this.markers = [];

  // Clear previously displayed planimeter marker label:

  if ( this.label ) {
    this.map.removeOverlay( this.label );
  }

  this.label = null;

  // Clear all previously displayed planimeter lines:

  for( var i = 0; i < this.lines.length; i++ ) {
    this.map.removeOverlay( this.lines[ i ] );
  }

  this.lines = [];

  // Clear any previously displayed planimeter polygon:

  if ( this.polygon != null ) {
    this.map.removeOverlay( this.polygon );
    this.polygon = null;
  }

  this.polygonPoints = [];

  // Display a clickable marker at each selected point:

  for ( var i = 0; i < this.points.length; i++ ) {

    var marker;

    // Make the most recently selected point blue:

    if ( i == this.points.length - 1 && this.mapClickListener ) {
      marker = new GMarker( this.points[ i ], { icon: this.blueIcon, draggable: true } );
    }

    // Make all previously selected points red:

    else {
      marker = new GMarker( this.points[ i ], { icon: this.redIcon, draggable: true } );
    }

    // Overlay this marker onto the map:

    this.map.addOverlay( marker );

    // Save an array of all of our marker objects:

    this.markers.push( marker );

    // Call markerDrag() function when marker is dragged; this function will
    // dynamically re-compute and re-display the area as the marker is dragged:

    var markerDrag         = GEvent.callbackArgs( this, this.markerDrag, i );
    var markerDragListener = GEvent.addListener( marker, 'drag', this.makeCaller( markerDrag, i ) );

    // Call markerClick() function when the marker is clicked; this function
    // rotates the active marker to the clicked one, to help modify the
    // selected polygon region for previous markers:

    var markerClick         = GEvent.callbackArgs( this, this.markerClick, i );
    var markerClickListener = GEvent.addListener( marker, 'click', this.makeCaller( markerClick, i ) );

    // If there are at least three points, also connect the points with red
    // lines, drawn on a great circle; and give a label with the currently
    // computed area of the enclosed region:

    if ( i > 0 && this.points.length >= 3 ) {
      this.addPolyline( this.greatCirclePoints( this.points[ i - 1 ], this.points[ i ] ), this.lineColor, this.lineWidth );
    }

  } // for

  // Make the line between the two most recent points blue instead of red:

  if ( this.points.length >= 2 ) {
    this.addPolyline( this.greatCirclePoints( this.points[ this.points.length - 1 ], this.points[ 0 ] ), this.closerColor, this.lineWidth );
  }

  // When at least three points, add a semi-transparent polygon:

  if ( this.points.length >= 3 ) {
    this.polygon = new GPolygon( this.polygonPoints, null, 0, this.polygonFillColor, this.polygonFillOpacity );
    this.map.addOverlay( this.polygon );
  }

  // Add a label to the last point with the computed area amount:

  if ( this.points.length >= 3 ) {

    // Compute the area using spherical geometry:

    var areaMeters2 = this.sphericalPolygonAreaMeters2( this.points );

    // For smaller regions, compute area using planar geometry for increased accuracy:

    if ( this.areaMeters2 < 1000000.0 ) {
      areaMeters2 = this.planarPolygonAreaMeters2( this.points );
    }

    var areaLabel = areaMeters2.toPrecision( 4 );
    areaLabel = areaLabel.replace( /e\+/, '&times;10<sup>' ); // convert e notation to scientific notation
    areaLabel += '</sup>&nbsp;m<sup>2</sup>';

    this.label = new ELabel( this.points[ this.points.length - 1 ], areaLabel, "labelstyle", new GSize( 2, 20 ), 60 );
    this.map.addOverlay( this.label  );
  }

} // display() 


/*
addPolyline()
Add a polyline for the specified array of points:
*/

Planimeter.prototype.addPolyline =  function ( points, lineColor, lineWidth ) {

  // If the map is no longer listening for new vertices, make all lines
  // finishColor instead of specified lineColor:

  if ( !this.mapClickListener ) {
    lineColor = this.finishColor;
  }
 
  // Define a new polyline for the specified array of points:

  var line = new GPolyline( points, lineColor, lineWidth );

  // Save an array of all of our line objects:

  this.lines.push( line );

  // Add an overlay for this polyline onto the map:

  this.map.addOverlay( line );

  // Add a click listener to the polyline:

  //GEvent.addListener( line, 'click', function () {
  //    alert( 'test!' );
  //  }
  //);
 
  // Save an array of all points in our compiled polygon:

  for ( var i = 0; i < points.length; i++ ) {
    this.polygonPoints.push( points[ i ] );
  }

} // addPolyline()


/*
convertArea()
Convert area in meters^2 to the specified unit of area:
*/

Planimeter.prototype.convertArea =  function ( areaMeters2, unit ) {

  var areaHectares = areaMeters2 / meters2PerHectare;
  var areaKm2      = areaMeters2 / metersPerKm  / metersPerKm;
  var areaFeet2    = areaMeters2 * feetPerMeter * feetPerMeter;
  var areaMiles2   = areaFeet2   / feetPerMile  / feetPerMile;
  var areaAcres    = areaMiles2  * acresPerMile2;

  if ( unit == 'areaHectares' ) {
    return areaHectares;
  }
  else if ( unit == 'areaKm2' ) {
    return areaKm2;
  }
  else if ( unit == 'areaFeet2' ) {
    return areaFeet2;
  }
  else if ( unit == 'areaMiles2' ) {
    return areaMiles2;
  }
  else if ( unit == 'areaAcres' ) {
    return areaAcres;
  }

} // convertArea()


/*
greatCirclePoints()
Return an array of points for a polyline that represents the
great circle of the Earth between the specified start and
end point if they are far enough apart to warrant it:
*/

Planimeter.prototype.greatCirclePoints =  function ( point1, point2 ) {

  var maxDistanceMeters = 200000.0; // 200 km
  var points            = [];

  // Only compute great circle if distance between the two points
  // is greater than 200 km; otherwise, just return a straight line:

  if ( point1.distanceFrom( point2 ) <= maxDistanceMeters ) {
    points.push( point1 );
    points.push( point2 );
  }
  else {

    var theta1 = point1.lng() * this.radiansPerDegree;
    var phi1   = ( 90.0 - point1.lat() ) * this.radiansPerDegree;
    var x1     = this.earthRadiusMeters * Math.cos( theta1 ) * Math.sin( phi1 );
    var y1     = this.earthRadiusMeters * Math.sin( theta1 ) * Math.sin( phi1 );
    var z1     = this.earthRadiusMeters * Math.cos( phi1 );

    var theta2 = point2.lng() * this.radiansPerDegree;
    var phi2   = ( 90.0 - point2.lat() ) * this.radiansPerDegree;
    var x2     = this.earthRadiusMeters * Math.cos( theta2 ) * Math.sin( phi2 );
    var y2     = this.earthRadiusMeters * Math.sin( theta2 ) * Math.sin( phi2 );
    var z2     = this.earthRadiusMeters * Math.cos( phi2 );

    // Compute midpoint (point3) on great circle:

    var x3     = ( x1 + x2 ) / 2.0;
    var y3     = ( y1 + y2 ) / 2.0;
    var z3     = ( z1 + z2 ) / 2.0;
    var r3     = Math.sqrt( ( x3 * x3 ) + ( y3 * y3 ) + ( z3 * z3 ) );
    var theta3 = Math.atan2( y3, x3 );
    var phi3   = Math.acos( z3 / r3 );
    var point3 = new GLatLng( 90.0 - ( phi3 * this.degreesPerRadian ), theta3 * this.degreesPerRadian );
 
    // Run recursively for each section before and after point3:
 
    var section1Points = this.greatCirclePoints( point1, point3 );
    var section2Points = this.greatCirclePoints( point3, point2 );

    for( var i = 0; i < section1Points.length; i++ ) {
      points.push( section1Points[ i ] );
    }

    for( var i = 1; i < section2Points.length; i++ ) {
      points.push( section2Points[ i ] );
    }
  }

  // Return the new array of points for the polyline:

  return points;

} // greatCirclePoints()


/*
planarPolygonAreaMeters2()
Compute area using planar geometry:
*/

Planimeter.prototype.planarPolygonAreaMeters2 = function ( points ) {

  var a = 0.0;

  for ( var i = 0; i < points.length; i++ ) {

    var j  = ( i + 1 ) % points.length;
    var xi = points[ i ].lng() * this.metersPerDegree * Math.cos( points[ i ].lat() * this.radiansPerDegree );
    var yi = points[ i ].lat() * this.metersPerDegree;
    var xj = points[ j ].lng() * this.metersPerDegree * Math.cos( points[ j ].lat() * this.radiansPerDegree );
    var yj = points[ j ].lat() * this.metersPerDegree;

    a += ( xi * yj ) - ( xj * yi );
  }

  return Math.abs( a / 2.0 );

} // planarPolygonAreaMeters2()


/*
sphericalPolygonAreaMeters2()
Compute area using spherical geometry:
*/

Planimeter.prototype.sphericalPolygonAreaMeters2 = function ( points ) {

  var totalAngle = 0.0;

  for ( i = 0; i < points.length; i++ ) {
    var j = ( i + 1 ) % points.length;
    var k = ( i + 2 ) % points.length;
    totalAngle += this.computeAngle( points[ i ], points[ j ], points[ k ] );
  }

  var planarTotalAngle = ( points.length - 2 ) * 180.0;
  var sphericalExcess  = totalAngle - planarTotalAngle;

  if ( sphericalExcess > 420.0 ) {
    totalAngle      = ( points.length * 360.0 ) - totalAngle;
    sphericalExcess = totalAngle - planarTotalAngle;
  }
  else if ( sphericalExcess > 300.0 && sphericalExcess < 420.0 ) {
    sphericalExcess = Math.abs( 360.0 - sphericalExcess );
  }

  return sphericalExcess * this.radiansPerDegree * ( this.earthRadiusMeters * this.earthRadiusMeters );

} // sphericalPolygonAreaMeters2()


/*
computeAngle()
*/

Planimeter.prototype.computeAngle =  function ( points1, points2, points3 ) {

  var bearing21 = this.computeBearing( points2, points1 );
  var bearing23 = this.computeBearing( points2, points3 );
  var angle     = bearing21 - bearing23;

  if ( angle < 0.0 ) {
    angle += 360.0;
  }

  return angle;

} // computeAngle()


/*
markerDrag()
Set point at specified index to the new point location:
*/

Planimeter.prototype.markerDrag =  function ( pointIndex ) {

  // Set the new location for this marker in the points array:

  var dragPoint = this.markers[ pointIndex ].getPoint();
  this.points[ pointIndex ] = dragPoint;

  // If there's only one point so far, do nothing more:

  if ( this.points.length == 1 ) {
    return;
  }

  // If there's only two points so far, re-draw the only line and return:

  else if ( this.points.length == 2 ) {

    var oldLine      = this.lines[ 0 ];
    var oldLineStart = oldLine.getVertex( 0 );
    var oldLineEnd   = oldLine.getVertex( oldLine.getVertexCount() - 1 );

    var newLineStart = dragPoint;

    this.map.removeOverlay( oldLine );

    var color;

    if ( this.mapClickListener ) {
      color = this.closerColor;
    }
    else {
      color = this.finishColor;
    }

    var newLine = new GPolyline( this.greatCirclePoints( newLineStart, oldLineEnd ), color, this.lineWidth );

    this.lines[ 0 ] = newLine;

    this.map.addOverlay( newLine );

    return;

  }

  // Otherwise, if three or more points, redraw the lines and the underlying
  // polygon that connects them:

  else {

    // Get the two polylines connecting this marker at its old location:

    var oldLine1Index = pointIndex;

    var oldLine2Index;

    // If current index is zero, use last line in array for second line:

    if ( pointIndex == 0 ) {
      oldLine2Index = this.lines.length - 1;
    }

    // Otherwise, use the previous line in the array for the second line:

    else {
      oldLine2Index = pointIndex - 1;
    }

    var oldLine1 = this.lines[ oldLine1Index ];
    var oldLine2 = this.lines[ oldLine2Index ];

    // Get color of the two polylines so we can preserve which one is
    // highlighted with "closerColor":

    var lineColor1 = this.lineColor;
    var lineColor2 = this.lineColor;

    if ( oldLine1Index == this.lines.length - 1 ) {
      lineColor1 = this.closerColor;
    }

    if ( oldLine2Index == this.lines.length - 1 ) {
      lineColor2 = this.closerColor;
    }

    if ( !this.mapClickListener ) {
      lineColor1 = this.finishColor;
      lineColor2 = this.finishColor;
    }

    // Get the start and end vertices of the old polylines:

    var oldLine1Start = oldLine1.getVertex( 0 );
    var oldLine1End   = oldLine1.getVertex( oldLine1.getVertexCount() - 1 );

    var oldLine2Start = oldLine2.getVertex( 0 );
    var oldLine2End   = oldLine2.getVertex( oldLine2.getVertexCount() - 1 );

    // Define the new start/end of the polylines:

    var newLine1Start = dragPoint;
    var newLine2End   = dragPoint;

    // Remove the old polylines:

    this.map.removeOverlay( oldLine1 );
    this.map.removeOverlay( oldLine2 );

    // Define the new polylines:

    var newLine1 = new GPolyline( this.greatCirclePoints( newLine1Start, oldLine1End ), lineColor1, this.lineWidth );
    var newLine2 = new GPolyline( this.greatCirclePoints( oldLine2Start, newLine2End ), lineColor2, this.lineWidth );

    // Update the lines array with the new polylines:

    this.lines[ pointIndex ] = newLine1;

    if ( pointIndex == 0 ) {
      this.lines[ this.lines.length - 1 ] = newLine2;
    }
    else {
      this.lines[ pointIndex - 1 ] = newLine2;
    }

    // Add the new polylines to the map:

    this.map.addOverlay( newLine1 );
    this.map.addOverlay( newLine2 );

    // Compute the new area using spherical geometry:

    var areaMeters2 = this.sphericalPolygonAreaMeters2( this.points );

    // For smaller regions, compute area using planar geometry for increased accuracy:

    if ( areaMeters2 < 1000000.0 ) {
      areaMeters2 = this.planarPolygonAreaMeters2( this.points );
    }

    // Remove previous area label and make new one at current marker index:

    this.map.removeOverlay( this.label );

    var areaLabel = areaMeters2.toPrecision( 4 );
    areaLabel = areaLabel.replace( /e\+/, '&times;10<sup>' ); // convert e notation to scientific notation
    areaLabel += '</sup>&nbsp;m<sup>2</sup>';

    this.label = new ELabel( this.points[ pointIndex ], areaLabel, "labelstyle", new GSize( 2, 20 ), 60 );
    this.map.addOverlay( this.label  );

    // Remove previous polygon overlay, define polygon points array, and
    // re-display the new polygon:

    this.map.removeOverlay( this.polygon );
    this.polygonPoints = [];

    for ( var i = 0; i < this.points.length; i++ ) {
      this.polygonPoints.push( this.points[ i ] );
    }
 
    this.polygon = new GPolygon( this.polygonPoints, null, 0, this.polygonFillColor, this.polygonFillOpacity );
    this.map.addOverlay( this.polygon ); 

  } // else

} // markerDrag()


/*
markerClick()
Rotate active point to the clicked marker and re-display:
*/

Planimeter.prototype.markerClick = function ( pointIndex ) {

  if ( this.markerSingleClicked ) {
    this.markerDoubleClicked = true;
  }
  else {
    this.markerSingleClicked = true;
    this.markerDoubleClicked = false;
    setTimeout( this.makeCaller( this.markerClickAction, this, pointIndex ), 250 );
  }
}


/*
markerClickAction()
*/

Planimeter.prototype.markerClickAction = function ( object, pointIndex ) {

  // If double-clicked, prevent planimeter from having additional vertices;
  // change style of lines, markers, and cursor; if this has already been
  // done, then double-clicking will remove planimeter:

  if ( object.markerDoubleClicked ) {

    if ( object.mapClickListener ) {

      GEvent.removeListener( object.mapClickListener );
      object.mapClickListener = null;

      for ( var i = 0; i < object.lines.length; i++ ) {
        object.lines[ i ].setStrokeStyle( { color: object.finishColor } );
      }

      for ( var i = 0; i < object.markers.length; i++ ) {
        object.markers[ i ].setImage( object.redIcon.image );
      }

      object.map.getDragObject().setDraggableCursor( 'url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default' );

    }
    else {
      object.removePlanimeter();
    }
  }

  // If single-clicked, rotate active point to the clicked marker and re-
  // display; also display an informative pop-up window with marker location
  // and further instructions:

  else {

    // Convert GLatLng object to string:

    var latLon    = object.markers[ pointIndex ].getLatLng();
    var latLonStr = latLon.toString();

    // Split marker location into lat and lon:

    latLonStr.match( /^\((.+), (.+)\)$/ );

    var lat = RegExp.$1;
    var lon = RegExp.$2;

    // Reduce number of digits in map center lat/long:

    var numDecimals = 4;

    lat = lat.substr( 0, lat.indexOf( '.' ) + 1 + numDecimals );
    lon = lon.substr( 0, lon.indexOf( '.' ) + 1 + numDecimals );

    // Define text to be displayed when marker is clicked:

    var doubleClickInfo;

    if ( object.mapClickListener ) {
      doubleClickInfo = 'Double-click marker to stop adding new vertices...';
    }
    else {
      doubleClickInfo = 'Double-click marker to remove area meter from the map...';
    }
    
    var markerHtml;

    markerHtml = '<p><font class="googleMapMarkerText">Area vertex</font></p><br/>'
               + '<p><font class="googleMapMarkerText">lat, lon: </font>' 
               + '<font color="#000000">'
               + lat + ', ' + lon
               + '</font></p>'
               + '<br/><p><font class="SmallTextGray"><i>NOTE: ' + doubleClickInfo + '<br>'
               + 'NOTE: Drag marker to move to a new location...</i></font></p><br/>'
               + '<p class="googleMapMarker"><font size="-1"><a class="googleMapMarker" href="#" onClick="this.blur(); map.panTo( new GLatLng( ' + lat + ',' + lon + ' ) )">Center map here</a></font></p>';

    object.map.openInfoWindowHtml( latLon, markerHtml );

    // Rotate points array to make clicked marker active and re-display:

    object.rotatePoints( pointIndex + 1 );
    object.display();
  }

  // Reset the clicked/double-clicked status:

  object.markerSingleClicked = false;
  object.markerDoubleClicked = false;

} // markerClickAction()


/*
rotatePoints()
Rotate the points so the specified point is the most recent one:
*/

Planimeter.prototype.rotatePoints =  function ( n ) {

  var t = [];

  for ( var i = 0; i < this.points.length; ++i ) {
    t.push( this.points[ ( i + n ) % this.points.length ] );
  }

  this.points = t;
}


/*
deleteLastPoint()
Delete the last/most-recent point from the array and re-display:
*/

Planimeter.prototype.deleteLastPoint = function () {
  if ( this.points.length > 0 ) {
    this.points.length--;
    this.display();
  }
}


/*
clearAllPoints()
Clear all points and re-display:
*/

Planimeter.prototype.clearAllPoints =  function () {
  this.points = [];
  this.display();
}


/*
makerCaller()
Turn a function into a caller: used in event listeners like
GEvent.addListener() and setTimeout(). Allow up to 10 optional arguments:
*/

Planimeter.prototype.makeCaller = function ( func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ) {
  return function () {
    func( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 );
  };
}


/*
computeBearing()
*/

Planimeter.prototype.computeBearing =  function ( from, to ) {

  var lat1 = from.lat() * this.radiansPerDegree;
  var lon1 = from.lng() * this.radiansPerDegree;
  var lat2 = to.lat()   * this.radiansPerDegree;
  var lon2 = to.lng()   * this.radiansPerDegree;

  var angle = -( Math.atan2( Math.sin( lon1 - lon2 ) * Math.cos( lat2 ), ( Math.cos( lat1 ) * Math.sin( lat2 ) ) - ( Math.sin( lat1 ) * Math.cos( lat2 ) * Math.cos( lon1 - lon2 ) ) ) );

  if ( angle < 0.0 ) {
    angle += Math.PI * 2.0;
  }

  angle *= this.degreesPerRadian;

  return angle;

} // computeBearing()

/*
removePlanimeter()
Clear all overlays (markers, polylines, polygon)...
Clear map click listener...
*/

Planimeter.prototype.removePlanimeter = function () {

  this.clearAllPoints();

  if ( this.mapClickListener != null ) {
    GEvent.removeListener( this.mapClickListener );
  }

  // Switch map's cursor style back to default:

  this.map.getDragObject().setDraggableCursor( 'url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default' ); 

  // Set user-specified html style back to normal (optional):

  if ( this.htmlElement ) {
    this.htmlElement.style.color     = 'GOLD';
    this.htmlElement.style.fontStyle = 'normal';
    this.htmlElement.title           = 'Measure area between three or more points; click on map to set points...';
  }
}
