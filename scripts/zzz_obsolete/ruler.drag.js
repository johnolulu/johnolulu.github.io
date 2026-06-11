/////////////////////// Ruler code by Esa 2006
// some cleaning 2008
// Source: http://koti.mbnet.fi/ojalesa/exam/ruler.html
// Author: Esa Ilmari
// NOTE: Requires ELabel from: http://econym.org.uk/gmap/elabel.js
//
// 2009, John Maurer: Minor modifications to function names and polyline
// options--polyline opacity and width and geodesic = true; remove
// the click listener after the rule has been defined so that user
// can return to normal map function afterwards; modify cursor over
// map to question mark ("help") until first marker is set. 

function addRuler() {

  var marker1;
  var marker2;
  var label1;
  var label2;
  var button = 0;
  var dist   = 0;
  var line;
  var poly;

  // For storing whether a marker has been single or double clicked:

  var markerSingleClicked = false;
  var markerDoubleClicked = false;

  var mapClickListenerID;

  // Change cursor style to a question mark when over the map:

  map.getDragObject().setDraggableCursor( "help" );

  function measure() {

    // If start and end points defined, define polyline and distance:

    if ( marker1 && marker2 ) {
      line = [ marker1.getPoint(), marker2.getPoint() ];
      dist = marker1.getPoint().distanceFrom( marker2.getPoint() );
      dist = dist.toFixed( 0 ) + "m";
    }

    // Convert to kilometers if greater than 10,000 meters:

    if ( parseInt( dist ) > 10000 ) {
      dist = ( parseInt( dist ) / 1000 ).toFixed( 1 ) + "km";
    }

    // Define labels; the same for both start and end points:

    label1.setContents( dist );
    label2.setContents( dist );

    label1.setPoint( marker1.getPoint() );
    label2.setPoint( marker2.getPoint() );

    // If there's a previous ruler/polyline displayed, remove it:

    if ( poly ) {
      map.removeOverlay( poly );
    }

    // Define and display the new ruler/polyline:

    poly = new GPolyline( line, "#FFFF00", 6, 0.7, { geodesic: true } );
    map.addOverlay( poly );

    // Remove the click listener now that we're done:

    GEvent.removeListener( mapClickListenerID );
  }

  mapClickListenerID = GEvent.addListener( map, "click", function( overlay, pnt ) {
    if ( pnt && button == 0 ) {

      // Add start point:

      marker1 = new GMarker( pnt, { draggable: true } );
      map.addOverlay( marker1 );
      marker1.enableDragging();

      var text1;

      if ( dist == 0 ) {
        text1 = 'Drag...';
      }
      else {
        text1 = dist;
      }

      label1 = new ELabel( pnt, text1, "labelstyle", new GSize( 2, 20 ), 60 );
      map.addOverlay(label1);

      // Change the cursor back to its default:

      map.getDragObject().setDraggableCursor( "url( http://maps.google.com/intl/en_us/mapfiles/openhand.cur ), default" );

      // Add end point:

      marker2 = new GMarker( pnt, { draggable: true } );
      map.addOverlay( marker2 );
      marker2.enableDragging();

      var text2;
      if ( dist == 0 ) {
        text2 = '';
      }
      else {
        text2 = dist;
      }

      label2 = new ELabel( pnt, text2, "labelstyle", new GSize( 2,20 ), 60 );
      map.addOverlay(label2);
    }

    // Add listeners to drag the start and end points:

    GEvent.addListener( marker1, "drag",     function() { measure();    } );
    GEvent.addListener( marker2, "drag",     function() { measure();    } );

    // Make an info window appear when a marker is clicked, and
    // clear the ruler when either is double-clicked. Google
    // Maps doesn't work to give a marker both a click and a double-
    // click listener, so we're going to listen for a double-click
    // by using a 250 millisecond setTimeout():

    GEvent.addListener( marker1, 'click',
      function ( latlng ) {
        if ( markerSingleClicked ) {
          markerDoubleClicked = true;
        }
        else {
          markerSingleClicked = true;
          markerDoubleClicked = false;
          setTimeout( makeCaller( markerAction, marker1, latlng ), 250 );
        }
      }
    );

    GEvent.addListener( marker2, 'click',
      function ( latlng ) {
        if ( markerSingleClicked ) {
          markerDoubleClicked = true;
        }
        else {
          markerSingleClicked = true;
          markerDoubleClicked = false;
          setTimeout( makeCaller( markerAction, marker2, latlng ), 250 );
        }
      }
    );

    button++;
  } );

  function clearRuler() {
    map.removeOverlay( poly    );
    map.removeOverlay( marker1 );
    map.removeOverlay( marker2 );
    map.removeOverlay( label1  );
    map.removeOverlay( label2  );
    button = 0;
    dist   = 0;
  }

  function markerAction ( marker, latLon ) {

    // If double-clicked, remove ruler:

    if ( markerDoubleClicked ) {
      clearRuler();
    }

    // If single-clicked, define and display info pop-up window:

    else {

      // Convert GLatLng object to string:

      latLonStr = latLon.toString();

      // Split marker location into lat and lon:

      latLonStr.match( /^\((.+), (.+)\)$/ );

      var lat = RegExp.$1;
      var lon = RegExp.$2;

      // Reduce number of digits in map center lat/long:

      var numDecimals = 4;

      var lat = lat.substr( 0, lat.indexOf( '.' ) + 1 + numDecimals );
      var lon = lon.substr( 0, lon.indexOf( '.' ) + 1 + numDecimals );

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

      map.openInfoWindowHtml( latLon, markerHtml );
    } 

    // Reset the clicked/double-clicked status:

    markerSingleClicked = false;
  }
 
  /*
  This fuction turns the first argument into a function with up to 10 optional
  arguments. Used in event listeners like GEvent.addListener() and setTimeout() so
  they properly handle arguments.
  */

  function makeCaller ( func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ) {
    return function () {
      func( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 );
    };
  }

}
