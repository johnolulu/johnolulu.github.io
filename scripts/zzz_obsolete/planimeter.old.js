// planimeter.js
// Author: Acme Laboratories
// Source: http://acme.com/planimeter/
// Modified by John Maurer, 2009.
// NOTE: Requires ELabel from: http://econym.org.uk/gmap/elabel.js
// This JavaScript code adds a planimeter, or area calculator, to the specified
// Google Map API object. Click three or more points to view the computed area.
// Run addPlanimeter( map ) to kick it off...

// Call this top function from within your own HTML page, passing it a previously
// defined Google Map "map" variable:

function addPlanimeter () {

  var points             = [];
  var markers            = [];
  var label              = [];
  var lines              = [];
  var polygonPoints      = [];
  var polygon            = null;
  var polygonFillColor   = '#FFFFFF';
  var polygonFillOpacity = 0.5;
  var lineWidth          = 5;
  var lineColor          = '#FF0000';
  var closerColor        = '#0000FF';
  var fillColor          = '#009900';

  // Define red and blue marker icons; blue will be used to designate
  // the most recently clicked point:

  var redIcon;
  var blueIcon;

  redIcon                  = new GIcon( G_DEFAULT_ICON );
  redIcon.image            = 'http://www2.hawaii.edu/~jmaurer/icons/gmap_markers/red.png';
  redIcon.shadow           = 'http://www2.hawaii.edu/~jmaurer/icons/gmap_markers/shadow.png';
  redIcon.iconSize         = new GSize( 20, 34 );
  redIcon.shadowSize       = new GSize( 37, 34 );
  redIcon.iconAnchor       = new GPoint( 9, 34 );
  redIcon.infoWindowAnchor = new GPoint( 9, 2 );
  redIcon.infoShadowAnchor = new GPoint( 18, 25 );

  blueIcon                 = new GIcon( redIcon );
  blueIcon.image           = 'http://www2.hawaii.edu/~jmaurer/icons/gmap_markers/blue.png';

  // Add a listener to define area vertices by clicking on the map:

  GEvent.addListener( map, 'click', function ( overlay, point, overlayPoint ) {

      // If we're not over an overlay (marker or polygon or polyline), 
      // get the click location from point:

      if ( overlay == null && point != null ) {
        points.push( point );
        display();
      }

      // Point will be undefined if overlay is defined; so
      // get point location from overlayPoint instead:

      else if ( overlay == polygon ) {
        points.push( overlayPoint );
        display();
      }
    }
  );

  // Initiate and display results:
 
  function display () {

    // Clear all previously displayed planimeter markers:

    for ( var i = 0; i < markers.length; i++ ) {
      map.removeOverlay( markers[ i ] );
    }

    markers = [];

    // Clear previously displayed planimeter marker label:

    map.removeOverlay( label );

    // Clear all previously displayed planimeter lines:

    for( var i = 0; i < lines.length; i++ ) {
      map.removeOverlay( lines[ i ] );
    }

    lines = [];

    // Clear any previously displayed planimeter polygon:

    if ( polygon != null ) {
      map.removeOverlay( polygon );
      polygon = null;
    }

    polygonPoints = [];

    // Display a clickable marker at each selected point:

    for ( var i = 0; i < points.length; i++ ) {

      var marker;

      // Make the most recently selected point blue:

      if ( i == points.length - 1 ) {
        marker = new GMarker( points[ i ], { icon: blueIcon, draggable: true } );
      }

      // Make all previously selected points red:

      else {
        marker = new GMarker( points[ i ], { icon: redIcon, draggable: true } );
      }

      // Overlay this marker onto the map:

      map.addOverlay( marker );

      // Save an array of all of our marker objects:

      markers.push( marker );

      // Call markerDrag() function when marker is dragged; this function will
      // dynamically re-compute and re-display the area as the marker is dragged:

      GEvent.addListener( marker, 'drag', makeCaller( markerDrag, i ) ); 

      // Call markerClick() function when the marker is clicked; this function
      // rotates the active marker to the clicked one, to help modify the
      // selected polygon region for previous markers:

      GEvent.addListener( marker, 'click', makeCaller( markerClick, i ) );

      // If there are at least three points, also connect the points with red
      // lines, drawn on a great circle; and give a label with the currently
      // computed area of the enclosed region:

      if ( i > 0 && points.length >= 3 ) {
        addPolyline( lines, greatCirclePoints( points[ i - 1 ], points[ i ] ), lineColor, lineWidth );
      }
    }

    // Make the line between the two most recent points blue instead of red:

    if ( points.length >= 2 ) {
      addPolyline( lines, greatCirclePoints( points[ points.length - 1 ], points[ 0 ] ), closerColor, lineWidth );
    }

    if ( points.length >= 3 ) {
      polygon = new GPolygon( polygonPoints, null, 0, polygonFillColor, polygonFillOpacity );
      map.addOverlay( polygon );
    }

    // Add a label to the last point with the computed area amount:

    if ( points.length >= 3 ) {

      // Compute the area using spherical geometry:

      var areaMeters2 = sphericalPolygonAreaMeters2( points );

      // For smaller regions, compute area using planar geometry for increased accuracy:

      if ( areaMeters2 < 1000000.0 ) {
        areaMeters2 = planarPolygonAreaMeters2( points );
      }

      label = new ELabel( points[ points.length - 1 ], areaMeters2.toPrecision( 4 ) + "m<sup>2</sup>", "labelstyle", new GSize( 2, 20 ), 60 );
      map.addOverlay( label  );
    }

  } // display() 

  // Add a polyline for the specified array of points:

  function addPolyline ( lines, points, lineColor, lineWidth ) {

    // Define a new polyline for the specified array of points:

    var line = new GPolyline( points, lineColor, lineWidth );

    // Save an array of all of our line objects:

    lines.push( line );

    // Add an overlay for this polyline onto the map:

    map.addOverlay( line );

    // Add a click listener to the polyline:

    //GEvent.addListener( line, 'click', function () {
    //    alert( 'test!' );
    //  }
    //);
 
    // Save an array of all points in our compiled polygon:

    for ( var i = 0; i < points.length; i++ ) {
      polygonPoints.push( points[ i ] );
    }
  }

  // Conversion factors for various units:

  var metersPerKm       = 1000.0;
  var meters2PerHectare = 10000.0;
  var feetPerMeter      = 3.2808399;
  var feetPerMile       = 5280.0;
  var acresPerMile2     = 640;

  // Convert area in meters^2 to the specified unit of area:

  function convertArea ( areaMeters2, unit ) {

    var areaHectares = areaMeters2 / meters2PerHectare;
    var areaKm2      = areaMeters2 / metersPerKm / metersPerKm;
    var areaFeet2    = areaMeters2 * feetPerMeter * feetPerMeter;
    var areaMiles2   = areaFeet2 / feetPerMile / feetPerMile;
    var areaAcres    = areaMiles2 * acresPerMile2;

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
  }

  var earthRadiusMeters = 6367460.0;
  var metersPerDegree   = 2.0 * Math.PI * earthRadiusMeters / 360.0;
  var radiansPerDegree  = Math.PI / 180.0;
  var degreesPerRadian  = 180.0   / Math.PI;

  // Return an array of points for a polyline that represents the
  // great circle of the Earth between the specified start and
  // end point if they are far enough apart to warrant it:

  function greatCirclePoints ( point1, point2 ) {

    var maxDistanceMeters = 200000.0; // 200 km
    var points            = [];

    // Only compute great circle if distance between the two points
    // is greater than 200 km; otherwise, just return a straight line:

    if ( point1.distanceFrom( point2 ) <= maxDistanceMeters ) {
      points.push( point1 );
      points.push( point2 );
    }
    else {

      var theta1 = point1.lng() * radiansPerDegree;
      var phi1   = ( 90.0 - point1.lat() ) * radiansPerDegree;
      var x1     = earthRadiusMeters * Math.cos( theta1 ) * Math.sin( phi1 );
      var y1     = earthRadiusMeters * Math.sin( theta1 ) * Math.sin( phi1 );
      var z1     = earthRadiusMeters * Math.cos( phi1 );

      var theta2 = point2.lng() * radiansPerDegree;
      var phi2   = ( 90.0 - point2.lat() ) * radiansPerDegree;
      var x2     = earthRadiusMeters * Math.cos( theta2 ) * Math.sin( phi2 );
      var y2     = earthRadiusMeters * Math.sin( theta2 ) * Math.sin( phi2 );
      var z2     = earthRadiusMeters * Math.cos( phi2 );

      // Compute midpoint (point3) on great circle:

      var x3     = ( x1 + x2 ) / 2.0;
      var y3     = ( y1 + y2 ) / 2.0;
      var z3     = ( z1 + z2 ) / 2.0;
      var r3     = Math.sqrt( ( x3 * x3 ) + ( y3 * y3 ) + ( z3 * z3 ) );
      var theta3 = Math.atan2( y3, x3 );
      var phi3   = Math.acos( z3 / r3 );
      var point3 = new GLatLng( 90.0 - ( phi3 * degreesPerRadian ), theta3 * degreesPerRadian );
 
      // Run recursively for each section before and after point3:
 
      var section1Points = greatCirclePoints( point1, point3 );
      var section2Points = greatCirclePoints( point3, point2 );

      for( var i = 0; i < section1Points.length; i++ ) {
        points.push( section1Points[ i ] );
      }

      for( var i = 1; i < section2Points.length; i++ ) {
        points.push( section2Points[ i ] );
      }
    }

    // Return the new array of points for the polyline:

    return points;
  }

  // Compute area using planar geometry:

  function planarPolygonAreaMeters2 ( points ) {

    var a = 0.0;

    for ( var i = 0; i < points.length; i++ ) {

      var j  = ( i + 1 ) % points.length;
      var xi = points[ i ].lng() * metersPerDegree * Math.cos( points[ i ].lat() * radiansPerDegree );
      var yi = points[ i ].lat() * metersPerDegree;
      var xj = points[ j ].lng() * metersPerDegree * Math.cos( points[ j ].lat() * radiansPerDegree );
      var yj = points[ j ].lat() * metersPerDegree;

      a += ( xi * yj ) - ( xj * yi );
    }

    return Math.abs( a / 2.0 );
  }

  // Compute area using spherical geometry:

  function sphericalPolygonAreaMeters2 ( points ) {

    var totalAngle = 0.0;

    for ( i = 0; i < points.length; i++ ) {
      var j = ( i + 1 ) % points.length;
      var k = ( i + 2 ) % points.length;
      totalAngle += computeAngle( points[ i ], points[ j ], points[ k ] );
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

    return sphericalExcess * radiansPerDegree * earthRadiusMeters * earthRadiusMeters;
  }

  function computeAngle ( points1, points2, points3 ) {

    var bearing21 = computeBearing( points2, points1 );
    var bearing23 = computeBearing( points2, points3 );
    var angle     = bearing21 - bearing23;

    if ( angle < 0.0 ) {
      angle += 360.0;
    }

    return angle;
  }

  // Set point at specified index to the new point location:

  function markerDrag ( pointIndex ) {

    // Set the new location for this marker in the points array:

    var dragPoint = markers[ pointIndex ].getPoint();
    points[ pointIndex ] = dragPoint;

    // If there's only one point so far, do nothing more:

    if ( points.length == 1 ) {
      return;
    }

    // If there's only two points so far, re-draw the only line and return:

    else if ( points.length == 2 ) {
      var oldLine = lines[ 0 ];
      var oldLineStart = oldLine.getVertex( 0 );
      var oldLineEnd   = oldLine.getVertex( oldLine.getVertexCount() - 1 );
      var newLineStart = dragPoint;
      map.removeOverlay( oldLine );
      var newLine = new GPolyline( greatCirclePoints( newLineStart, oldLineEnd ), closerColor, lineWidth );
      lines[ 0 ] = newLine;
      map.addOverlay( newLine );
      return;
    }

    // Get the two polylines connecting this marker at its old location:

    var oldLine1Index = pointIndex;

    var oldLine2Index;

    if ( pointIndex == 0 ) {
      oldLine2Index = lines.length - 1; // if current index is zero, use last line in array
    }
    else {
      oldLine2Index = pointIndex - 1;   // otherwise, use previous line in array
    }

    var oldLine1 = lines[ oldLine1Index ];
    var oldLine2 = lines[ oldLine2Index ];

    // Get color of the two polylines so we can preserve which one is
    // highlighted with "closerColor":

    lineColor1 = lineColor;
    lineColor2 = lineColor;

    if ( oldLine1Index == lines.length - 1 ) {
      lineColor1 = closerColor;
    }

    if ( oldLine2Index == lines.length - 1 ) {
      lineColor2 = closerColor;
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

    map.removeOverlay( oldLine1 );
    map.removeOverlay( oldLine2 );

    // Define the new polylines:

    var newLine1 = new GPolyline( greatCirclePoints( newLine1Start, oldLine1End ), lineColor1, lineWidth );
    var newLine2 = new GPolyline( greatCirclePoints( oldLine2Start, newLine2End ), lineColor2, lineWidth );

    // Update the lines array with the new polylines:

    lines[ pointIndex ] = newLine1;

    if ( pointIndex == 0 ) {
      lines[ lines.length - 1 ] = newLine2;
    }
    else {
      lines[ pointIndex - 1 ] = newLine2;
    }

    // Add the new polylines to the map:

    map.addOverlay( newLine1 );
    map.addOverlay( newLine2 );

    // Compute the new area using spherical geometry:

    var areaMeters2 = sphericalPolygonAreaMeters2( points );

    // For smaller regions, compute area using planar geometry for increased accuracy:

    if ( areaMeters2 < 1000000.0 ) {
      areaMeters2 = planarPolygonAreaMeters2( points );
    }

    // Remove previous area label and make new one at current marker index:

    map.removeOverlay( label );

    label = new ELabel( points[ pointIndex ], areaMeters2.toPrecision( 4 ) + "m<sup>2</sup>", "labelstyle", new GSize( 2, 20 ), 60 );
    map.addOverlay( label  );

    // Remove previous polygon overlay, define polygon points array, and
    // re-display the new polygon:

    map.removeOverlay( polygon );
    polygonPoints = [];

    for ( var i = 0; i < points.length; i++ ) {
      polygonPoints.push( points[ i ] );
    }
 
    polygon = new GPolygon( polygonPoints, null, 0, polygonFillColor, polygonFillOpacity );
    map.addOverlay( polygon ); 
  }

  // Rotate active point to the clicked marker and re-display:

  function markerClick ( pointIndex ) {
    rotatePoints( pointIndex + 1 );
    display();
  }

  // Rotate the points so the specified point is the most recent one:

  function rotatePoints ( n ) {

    var t = [];

    for ( var i = 0; i < points.length; ++i ) {
      t.push( points[ ( i + n ) % points.length ] );
    }

    points = t;
  }

  // Delete the last/most-recent point from the array and re-display:

  function deleteLastPoint () {
    if ( points.length > 0 ) {
      points.length--;
      display();
    }
  }

  // Clear all points and re-display:

  function clearAllPoints () {
    points = [];
    display();
  }

  // Turn a function into a caller: used in event listeners like
  // GEvent.addListener() and setTimeout(). Allow up to 10 optional arguments:

  function makeCaller ( func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ) {
    return function () {
      func( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 );
    };
  }

  function computeBearing ( from, to ) {

    var lat1 = from.lat() * radiansPerDegree;
    var lon1 = from.lng() * radiansPerDegree;
    var lat2 = to.lat()   * radiansPerDegree;
    var lon2 = to.lng()   * radiansPerDegree;

    var angle = -( Math.atan2( Math.sin( lon1 - lon2 ) * Math.cos( lat2 ), ( Math.cos( lat1 ) * Math.sin( lat2 ) ) - ( Math.sin( lat1 ) * Math.cos( lat2 ) * Math.cos( lon1 - lon2 ) ) ) );

    if ( angle < 0.0 ) {
      angle += Math.PI * 2.0;
    }

    angle *= degreesPerRadian;

    return angle;
  }

}
