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

  var clickListenerID;

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

    GEvent.removeListener( clickListenerID );
  }

  clickListenerID = GEvent.addListener( map, "click", function( overlay, pnt ) {
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

    // Add listeners to drag and close the start and end points:

    GEvent.addListener( marker1, "drag",     function() { measure();    } );
    GEvent.addListener( marker1, "dblclick", function() { clearRuler(); } );

    GEvent.addListener( marker2, "drag",     function() { measure();    } );
    GEvent.addListener( marker2, "dblclick", function() { clearRuler(); } );

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
}
