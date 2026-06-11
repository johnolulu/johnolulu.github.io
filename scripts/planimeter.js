/*
planimeter.js
Author: Acme Laboratories
Source: http://acme.com/planimeter/

Modified by John Maurer, 2009--used prototype-based coding, cleaned up code
style, made markers draggable, double-click to denote last end point and to
remove planimeter; new lines move with cursor.

NOTE: Requires ELabel from: http://econym.org.uk/gmap/elabel.js
Assumes CSS class named "labelstyle" for ELabel in your document,
or will use default style instead.

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

function Planimeter ( map, htmlElement, lineWidth, lineColor, lineOpacity, finishColor, polygonFillColor, polygonFillOpacity ) {

  this.map                = map;
  this.htmlElement        = htmlElement;
  this.lineWidth          = lineWidth          || 5;
  this.lineColor          = lineColor          || '#FF0000';
  this.lineOpacity        = lineOpacity        || 0.7;
  this.finishColor        = finishColor        || '#FFFF00';
  this.polygonFillColor   = polygonFillColor   || '#000000';
  this.polygonFillOpacity = polygonFillOpacity || 0.2;

  this.activeLabel        = null;
  this.activeLine1        = null;
  this.activeLine2        = null;
  this.infoLabel          = null;
  this.label              = null;
  this.labelOpacity       = 60; // 0 to 100
  this.lines              = new Array(); 
  this.markers            = new Array();
  this.points             = new Array();
  this.polygon            = null;
  this.polygonPoints      = new Array();

  // Conversion factors for various units:

  this.acresPerMile2     = 640;
  this.degreesPerRadian  = 180.0   / Math.PI;
  this.earthRadiusMeters = 6367460.0;
  this.feetPerMeter      = 3.2808399;
  this.feetPerMile       = 5280.0;
  this.meters2PerHectare = 10000.0;
  this.metersPerDegree   = 2.0 * Math.PI * this.earthRadiusMeters / 360.0;
  this.metersPerKm       = 1000.0;
  this.radiansPerDegree  = Math.PI / 180.0;

  // Various listeners that will be used to control map events:

  this.mapClickListener;
  this.mapMouseMoveListener;
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

  // Add a listener to draw line between last end point and cursor location:

  var mapMouseMove          = GEvent.callback( this, this.mapMouseMove );
  this.mapMouseMoveListener = GEvent.addListener( this.map, 'mousemove',
    function( point ) {
      mapMouseMove( point );
    }
  );

} // addPlanimeter()


/*
mapClick()
Get click location and re-run display()...
*/

Planimeter.prototype.mapClick = function ( overlay, point, overlayPoint ) {

  var clickPoint;

  // If we're not over an overlay (marker or polygon or polyline), 
  // get the click location from point:

  if ( overlay == null && point != null ) {
    clickPoint = point;
  }

  // Point will be undefined if overlay is defined; so
  // get point location from overlayPoint instead:

  else {
  
    // Ignore clicks on existing markers:

    for ( var i in this.markers ) {
      if ( overlay == this.markers[ i ] ) {
        return;
      }
    }

    clickPoint = overlayPoint;
  }

  if ( clickPoint ) {

    this.points.push( clickPoint );
    this.display();

    // On the third click a polygon will form; display info label about how
    // to stop adding points:

    if ( this.points.length == 3 ) {
      this.infoLabel = new ELabel( clickPoint, 'Double-click&nbsp;any&nbsp;marker&nbsp;to&nbsp;complete&nbsp;the&nbsp;shape...', 'labelstyle', new GSize( 8, 42 ), this.labelOpacity );
      this.map.addOverlay( this.infoLabel );
      fadeLabel = this.makeCaller( this.fadeLabel, this );
      setTimeout( fadeLabel, 750 );
    }

  }

} // mapClick()


/*
mapMouseMove()
*/

Planimeter.prototype.mapMouseMove = function ( cursorLatLng ) {

  if ( this.points.length != 0 ) {
    
    // Remove any previously displayed active lines and label:
    
    if ( this.activeLine1 ) {
      this.map.removeOverlay( this.activeLine1 );
      this.activeLine1 = null;
    }

    if ( this.activeLine2 ) {
      this.map.removeOverlay( this.activeLine2 );
      this.activeLine2 = null;
    }

    if ( this.activeLabel ) {
      this.map.removeOverlay( this.activeLabel );
      this.activeLabel = null;
    }

    // Set start point to location of most recent marker:

    var start = this.points[ this.points.length - 1 ];
    
    // Define first active polyline:
    
    this.activeLine1 = new GPolyline( [ start, cursorLatLng ], this.lineColor, this.lineWidth, this.lineOpacity, { geodesic: true } );
    this.map.addOverlay( this.activeLine1 );

    if ( this.points.length >= 2 ) {

      // Set end point to location of first marker:

      var end = this.points[ 0 ];

      // Define second active polyline:

      this.activeLine2 = new GPolyline( [ cursorLatLng, end ], this.lineColor, this.lineWidth, this.lineOpacity, { geodesic: true } );
      this.map.addOverlay( this.activeLine2 );

      // Get array of points including cursorLatLng:

      var activePoints = new Array();

      for ( var i in this.points ) {
        activePoints.push( this.points[ i ] );
      }

      activePoints.push( cursorLatLng );

      // Compute active area:

      var areaMeters2 = this.computeAreaMeters2( activePoints );

      // Create new area label:

      var areaLabel = this.areaLabel( areaMeters2 );

      this.activeLabel = new ELabel( cursorLatLng, areaLabel, 'labelstyle', new GSize( 30, 22 ), this.labelOpacity );
      this.map.addOverlay( this.activeLabel ); 
       
    } // if 

  } // if any points

} // mapMouseMove() 


/*
display()
Initiate and display results:
*/
 
Planimeter.prototype.display =  function () {

  // Clear all previously displayed active (cursor-following) lines and labels:

  if ( this.activeLine1 ) {
    this.map.removeOverlay( this.activeLine1 );
    this.activeLine1 = null;
  }

  if ( this.activeLine2 ) {
    this.map.removeOverlay( this.activeLine2 );
    this.activeLine2 = null;
  }

  if ( this.activeLabel ) {
    this.map.removeOverlay( this.activeLabel );
    this.activeLabel = null;
  }

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

    var marker = new GMarker( this.points[ i ], { draggable: true } );
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
      this.addPolyline( this.greatCirclePoints( this.points[ i - 1 ], this.points[ i ] ), this.lineColor, this.lineWidth, this.lineOpacity );
    }

  } // for

  // Make the line between the two most recent points:

  if ( this.points.length >= 2 ) {
    this.addPolyline( this.greatCirclePoints( this.points[ this.points.length - 1 ], this.points[ 0 ] ), this.lineColor, this.lineWidth, this.lineOpacity );
  }

  // When at least three points, add a semi-transparent polygon:

  if ( this.points.length >= 3 ) {
    this.polygon = new GPolygon( this.polygonPoints, null, 0, 0, this.polygonFillColor, this.polygonFillOpacity );
    this.map.addOverlay( this.polygon );
  }

  // Add a label to the last point with the computed area amount:

  if ( this.points.length >= 3 ) {

    // Compute the area:

    var areaMeters2 = this.computeAreaMeters2( this.points );

    // Add label:

    var areaLabel = this.areaLabel( areaMeters2 );

    this.label = new ELabel( this.points[ this.points.length - 1 ], areaLabel, 'labelstyle', new GSize( 8, 22 ), this.labelOpacity );

    this.map.addOverlay( this.label  );
  }

} // display() 


/*
addPolyline()
Add a polyline for the specified array of points:
*/

Planimeter.prototype.addPolyline =  function ( points, lineColor, lineWidth, lineOpacity ) {

  // If the map is no longer listening for new vertices, make all lines
  // finishColor instead of specified lineColor:

  if ( !this.mapClickListener ) {
    lineColor = this.finishColor;
  }
 
  // Define a new polyline for the specified array of points:

  var line = new GPolyline( points, lineColor, lineWidth, lineOpacity );

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
computeAreaMeters2()
*/

Planimeter.prototype.computeAreaMeters2 = function ( points ) {

  var areaMeters2 = this.sphericalPolygonAreaMeters2( points );

  // For smaller regions, compute area using planar geometry for increased accuracy:

  if ( areaMeters2 < 1000000.0 ) {
    areaMeters2 = this.planarPolygonAreaMeters2( points );
  }

  return areaMeters2;

} // computeAreaMeters2()


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
areaLabel()
Define HTML string used to label the area on the map:
*/

Planimeter.prototype.areaLabel = function ( areaMeters2 ) {

  var areaLabel = areaMeters2.toPrecision( 4 );

  // If e notation, convert to scientific notation:

  areaLabel = areaLabel.replace( /e\+/, '&times;10<sup>' );

  // Add units after the number:

  areaLabel += '</sup>&nbsp;m<sup>2</sup>';

  return areaLabel;

} // areaLabel()

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
      color = this.lineColor;
    }
    else {
      color = this.finishColor;
    }

    var newLine = new GPolyline( this.greatCirclePoints( newLineStart, oldLineEnd ), color, this.lineWidth, this.lineOpacity );

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

    // Define color of the two polylines:

    var color;

    if ( this.mapClickListener ) {
      color = this.lineColor;
    }
    else {
      color = this.finishColor;
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

    var newLine1 = new GPolyline( this.greatCirclePoints( newLine1Start, oldLine1End ), color, this.lineWidth, this.lineOpacity );
    var newLine2 = new GPolyline( this.greatCirclePoints( oldLine2Start, newLine2End ), color, this.lineWidth, this.lineOpacity );

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

    // Compute the new area:

    var areaMeters2 = this.computeAreaMeters2( this.points );

    // Remove previous area label and make new one at current marker index:

    this.map.removeOverlay( this.label );

    var areaLabel = this.areaLabel( areaMeters2 );

    this.label = new ELabel( this.points[ pointIndex ], areaLabel, 'labelstyle', new GSize( 8, 22 ), this.labelOpacity );

    this.map.addOverlay( this.label  );

    // Replace the polygon:

    this.map.removeOverlay( this.polygon );
    this.polygonPoints = [];

    // Define polygon edges as great circles between existing vertices:

    for ( var i = 0; i < this.points.length; i++ ) {

      var geodesicPoints = new Array();

      if ( i == 0 ) {
        geodesicPoints = this.greatCirclePoints( this.points[ this.points.length - 1 ], this.points[ i ] );
      }
      else {
        geodesicPoints = this.greatCirclePoints( this.points[ i - 1 ], this.points[ i ] );
      }

      for ( var j in geodesicPoints ) {
        this.polygonPoints.push( geodesicPoints[ j ] );
      }
    }

    this.polygon = new GPolygon( this.polygonPoints, null, 0, 0, this.polygonFillColor, this.polygonFillOpacity );
    this.map.addOverlay( this.polygon ); 

  } // else

} // markerDrag()


/*
markerClick()
Determine if marker was single-clicked or double-clicked using a setTimeout...
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

      object.finishPlanimeter();

      // Add a fading info label to tell user that double-clicking markers will
      // now remove the area from the map:
  
      object.infoLabel = new ELabel( object.points[ pointIndex ], 'Double-click&nbsp;any&nbsp;marker&nbsp;to&nbsp;remove&nbsp;area...', 'labelstyle', new GSize( 8, 42 ), object.labelOpacity );
      object.map.addOverlay( object.infoLabel );
      fadeLabel = object.makeCaller( object.fadeLabel, object );
      setTimeout( fadeLabel, 750 );

    }
    else {
      object.removePlanimeter();
    }
  }

  // If single-clicked, display an informative pop-up window with marker
  // location and further instructions:

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
               + 'NOTE: Drag marker to move to a new location...</i></font></p>';

    object.map.openInfoWindowHtml( latLon, markerHtml );

  } // else

  // Reset the clicked/double-clicked status:

  object.markerSingleClicked = false;
  object.markerDoubleClicked = false;

} // markerClickAction()


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
fadeLabel()
Successively increases opacity of infoLabel ELabel until it disappears...
*/

Planimeter.prototype.fadeLabel = function ( object ) {

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

Planimeter.prototype.setOpacity = function ( object, opacity ) {
  object.infoLabel.setOpacity( opacity );
}


/*
hideLabel()
Set infoLabel ELabel to hidden...
*/

Planimeter.prototype.hideLabel = function ( object ) {
  object.infoLabel.hide();
}


/*
finishPlanimeter()
Clear map listeners in order to stop adding vertices...
*/

Planimeter.prototype.finishPlanimeter = function () {

  // Remove map listeners:
    
  GEvent.removeListener( this.mapClickListener );
  this.mapClickListener = null;

  if ( this.mapMouseMoveListener ) {
    GEvent.removeListener( this.mapMouseMoveListener );
    this.mapMouseMoveListener = null;
  }

  // Remove overlays associated with above listeners:

  if ( this.activeLine1 ) {
    this.map.removeOverlay( this.activeLine1 );
    this.activeLine1 = null;
  } 
      
  if ( this.activeLine2 ) {
    this.map.removeOverlay( this.activeLine2 );
    this.activeLine2 = null;
  }
      
  if ( this.activeLabel ) {
    this.map.removeOverlay( this.activeLabel );
    this.activeLabel = null;
  }
    
  if ( this.infoLabel ) {
    this.map.removeOverlay( this.infoLabel );
    this.infoLabel = null;
  }

  // Change color of lines to indicate shape is completed:

  for ( var i = 0; i < this.lines.length; i++ ) {
    this.lines[ i ].setStrokeStyle( { color: this.finishColor } );
  }

  // Change cursor back to default:

  this.map.getDragObject().setDraggableCursor( 'url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default' );
  
  // Set user-specified html style back to normal (optional):
  
  if ( this.htmlElement ) {
    this.htmlElement.style.color     = 'GOLD';
    this.htmlElement.style.fontStyle = 'normal';
    this.htmlElement.title           = 'Measure area between three or more points; click on map to set points...';
  }

} // finishPlanimeter()


/*
removePlanimeter()
Clear all overlays (markers, polylines, polygon)...
Clear map listeners...
*/

Planimeter.prototype.removePlanimeter = function () {

  this.clearAllPoints();

  if ( this.mapClickListener != null ) {
    GEvent.removeListener( this.mapClickListener );
    this.mapClickListener = null;
  }

  if ( this.mapMouseMoveListener != null ) {
    GEvent.removeListener( this.mapMouseMoveListener );
    this.mapMouseMoveListener = null;
  }

  if ( this.activeLine1 ) {
    this.map.removeOverlay( this.activeLine1 );
    this.activeLine1 = null;
  }
  
  if ( this.activeLine2 ) {  
    this.map.removeOverlay( this.activeLine2 );
    this.activeLine2 = null;
  }

  if ( this.activeLabel ) {
    this.map.removeOverlay( this.activeLabel );
    this.activeLabel = null;
  }

  if ( this.infoLabel ) {
    this.map.removeOverlay( this.infoLabel );
    this.infoLabel = null;
  }

  // Switch map's cursor style back to default:

  this.map.getDragObject().setDraggableCursor( 'url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default' ); 

}
