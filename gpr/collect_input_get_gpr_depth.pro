;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  collect_input_get_gpr_depth
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL function is called to collect user input related to converting time to
;;  depth conversion settings for a RAMAC ground-penetrating radar (GPR) data file.
;;  In addition, this function may also collect start and end distance settings.
;;  It displays a window for the user to enter various parameters necessary for
;;  computing depth (and optionally distance), which are ultimately passed to the
;;  "get_gpr_depth.pro" procedure for a given pixel location.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  result = collect_input_get_gpr_depth( ystart = ystart, num_samples = num_samples, $
;;   time_window = time_window, antenna_separation = antenna_separation, [/COLLECT_DISTANCE_INFO] )
;;
;;  Return Value:
;;
;;  result.accept = 1 if user selects "OK", 0 if "Cancel".
;;
;;  return.ground_velocity (float) = the velocity (in meters per nanosecond) at which radar would travel
;;      through the imaged subsurface medium/media.  Ground velocities range from slow
;;      (e.g. 0.03 m/ns for fresh water) to fast (e.g. 0.3 m/ns for air) and the user should
;;      refer to a GPR textbook or manual for the proper value related to the media being imaged.
;;
;;  return.first_arrival (integer) = the number of the sample (vertical- or y-dimension) at which the first
;;      radar pulse has reached the subsurface in the data file. This will be the zero-depth point,
;;      without direct wave adjustment. This first arrival is returned in image coordinates (ystart is
;;      top pixel and num_samples is bottom pixel).
;;
;;  return.direct_wave_adjustment (0 = no; 1 = yes) = a flag to specify whether or not to adjust the
;;      reported depth measurement by the direct wave.
;;
;;  return.adjustment_velocity (double) = the velocity (in meters per nanosecond) at which radar
;;      would travel the direct wave. Most frequently this will be the velocity of air (0.3 m/ns). This only
;;      needs to be supplied if the direct_wave_adjustment is set to 1.
;;
;;  return.start_distance (optional) (float) = The start distance (in meters) of the data file. Will not
;;      be supplied unless /COLLECT_DISTANCE_INFO is set.
;;
;;  return.end_distance (optional) (float) = The estimated end distance (in meters) of the data file. Will
;;      not be supplied unless /COLLECT_DISTANCE_INFO is set.
;;
;;  Keywords:
;;
;;  ystart (integer) = the first sample (vertical- or y- dimension) in the file being filtered (i.e. at the
;;      very top of the file). This is a zero-based number, so unless the data have been subsetted,
;;      it is likely that ystart = 0.
;;
;;  num_samples (integer) = total number of samples (vertical- or y- dimension) in the file
;;      being filtered. Used to provide a slider between the first sample and the last sample
;;      for the user to select a first arrival sample.
;;
;;  time_window (double) = the amount of time in nanoseconds (10^-9 seconds) that the GPR instrument
;;      was set to "listen" for radar pulses per trace at the time of data acquisition. This
;;      value can be found in the "*.rad" file associated with a particular RAMAC GPR data
;;      file ("*.rd3") in the row labelled "TIMEWINDOW".
;;
;;  antenna_separation (double) = the separation in meters between the transmitter and
;;      receiver antennae. This value can be found in the "*.rad" file associated with a particular
;;      RAMAC GPR data file ("*.rd3") in the row labelled "ANTENNA SEPARATION". This keyword only
;;      needs to be supplied if the direct_wave_adjustment is set to 1.
;;
;;  COLLECT_DISTANCE_INFO (optional) = when this keyword is set, the widget will ask the user for an
;;      an estimated start distance and end distance (in meters) in addition to the time-to-depth
;;      conversion settings.
;;
;;  Examples:
;;
;;  result = collect_input_get_gpr_depth( ystart = 0, num_samples = 1024, time_window = 42.5, $
;;      antenna_separation = 0.1, /COLLECT_DISTANCE_INFO )
;;  result = collect_input_get_gpr_depth( ystart = 0, num_samples = 1024, time_window = 42.5, $
;;      antenna_separation = 0.1 )
;;  -------------------------------------------------------------------------------------
;;
;;  Author:
;;  John Maurer (john.maurer@colorado.edu)
;;  M.A. - Department of Geography
;;  Cooperative Institute for Research in Environmental Sciences (CIRES)
;;  University of Colorado at Boulder
;;  http://cires.colorado.edu/~maurerj
;;  Advisor: Dr. Konrad Steffen (konrad.steffen@colorado.edu)
;;  http://cires.colorado.edu/science/groups/steffen/
;;  ©2005-2006 University of Colorado
;;
;;  This program is free software; you can redistribute it and/or modify it under the terms of the
;;  GNU General Public License as published by the Free Software Foundation; either version 2 of the
;;  License, or (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
;;  even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;  General Public License for more details (GNU_License.txt).
;;
;;  You should have received a copy of the GNU General Public License along with this program
;;  (GNU_License.txt); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
;;  Boston, MA  02111-1307  USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
; Putting the above documentation between ";+" and ";-" allows it to be accessed in IDL via
; "DOC_LIBRARY, 'procedure_name'".

FUNCTION collect_input_get_gpr_depth, ystart = ystart, num_samples = num_samples, time_window = time_window, $
    antenna_separation = antenna_separation, collect_distance_info = collect_distance_info

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ; Make sure all of the necessary parameters have been provided; otherwise, cause an error.
    ; The MESSAGE procedure issues error and informational messages using the same mechanism
    ; employed by built-in IDL routines. By default, the message is issued as an error, the
    ; message is output, and execution is haulted. See IDL's help page for information on
    ; controlling errors using CATCH or ON_ERROR:

    IF ( N_ELEMENTS( ystart ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The first sample (y-dimension) (e.g. ystart=0) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( num_samples ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The number of samples (y-dimension) (e.g. num_samples=1024) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( time_window ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The time window (ns) (e.g. time_window=42.5) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( antenna_separation ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The antenna sepation (m) (e.g. antenna_separation=0.1) was not supplied."
    ENDIF

    ; Create an IDL "widget" to allow user input...

    ; Define the widget "Top Level Base" (TLB) and title:

    IF ( KEYWORD_SET( collect_distance_info ) ) THEN BEGIN
        TLB = WIDGET_AUTO_BASE( title = "Depth / Distance Settings" )
    ENDIF ELSE BEGIN
       TLB = WIDGET_AUTO_BASE( title = "Time to depth conversion settings" )
    ENDELSE

    ; Create a new base within TLB to frame and contain all of the input fields below
    ; related to time-to-depth conversion:

    sub_base1 = WIDGET_BASE( TLB, /col, /frame )

    ; Provide a row to the above widget to define this section of the widget:

    row_base1 = WIDGET_BASE( sub_base1, /row )
    now_used = WIDGET_LABEL( row_base1, value = "Time to depth conversion settings:" )

    ; Provide a row to the above widget that displays the data file's "time window":

    row_base2 = WIDGET_BASE( sub_base1, /row )

    display_time_window = 'Time window: ' + STRCOMPRESS( STRING( time_window ), /REMOVE_ALL ) + ' (ns)'

    not_used = WIDGET_LABEL( row_base2, value = display_time_window )

    ; Provide a row to the widget for explaining to the user what common ground velocity
    ; values are:

    row_base3 = WIDGET_BASE( sub_base1, /row )

    ground_velocity_explanation = 'The ground velocity is a measure of how fast the radar signal ' + $
        'travels through the subsurface medium:'

    not_used = WIDGET_LABEL( row_base3, value = ground_velocity_explanation )

    ; Provide another row to the widget for setting the ground velocity of the radar
    ; signal through the subsurface medium in meters per nanoseconds (m/ns). The data
    ; type is floating-point ("dt=4")

    row_base4 = WIDGET_BASE( sub_base1, /row )

    ground_velocity = WIDGET_PARAM( row_base4, /auto_manage, dt = 4, prompt = 'Ground velocity (m/ns):', $
        floor = 0.001, ceil = 0.301, field = 3, uvalue = 'ground_velocity' )

    not_used = WIDGET_LABEL( row_base4, value = ' (e.g. 0.300 m/ns = air; 0.167 m/ns = ice; 0.033 m/ns = fresh water)' )

    ; Provide a row to the widget for explaining to the user what the first arrival is:

    row_base5 = WIDGET_BASE( sub_base1, /row )

    first_arrival_explanation = 'First arrival at sample (y-dimension) (i.e. depth calculation will begin here):'

    not_used = WIDGET_LABEL (row_base5, value = first_arrival_explanation )

    ; Provide a slider between the first and last sample (y-dimension) to determine the sample of the
    ; first arrival (i.e. where the radar first meets the subsurface):

    row_base6 = WIDGET_BASE( sub_base1, /row )

    first_arrival = WIDGET_SSLIDER( row_base6, /auto_manage, title = '', $
        min = ystart + 1, max = ystart + num_samples, floor = ystart + 1, ceil = ystart + num_samples, $
        value = 1, dt = 2, uvalue = 'first_arrival' )

    ; Provide a row to the widget for explaining to the user what the direct wave adjustment is for:

    row_base7 = WIDGET_BASE( sub_base1, /row )

    direct_wave_explanation = 'The direct wave travel time is the time it takes for the radar wave to ' + $
        'travel in a straight line between the transmitter and receiver:'

    not_used = WIDGET_LABEL (row_base7, value = direct_wave_explanation )

    ; Ask the user whether to adjust for direct wave travel time (e.g. air before signal reached subsurface):

    row_base8 = WIDGET_BASE( sub_base1, /row )

    direct_wave_adjustment = WIDGET_MENU( row_base8, /auto_manage, list = [ "no", "yes" ], /exclusive, $
        prompt = 'Adjust for direct wave travel time:', default_ptr = 1, uvalue = 'direct_wave_adjustment' )

    ; Provide a row to the widget that displays the data file's antenna separation (from the "*.rad" header file):

    row_base9 = WIDGET_BASE( sub_base1, /row )

    display_antenna_separation = 'Antenna separation: ' + STRCOMPRESS( STRING( antenna_separation ), /REMOVE_ALL ) + $
        ' (m)'

    not_used = WIDGET_LABEL( row_base9, value = display_antenna_separation )

    ; Provide another row to the widget for setting the adjustment velocity of the radar
    ; signal for the direct wave in meters per nanoseconds (m/ns):

    row_base10 = WIDGET_BASE( sub_base1, /row )

    adjustment_velocity = WIDGET_PARAM( row_base10, /auto_manage, dt = 4, prompt = 'Adjustment velocity (m/ns):', $
        default = 0.300, floor = 0.001, ceil = 0.301, field = 3, uvalue = 'adjustment_velocity' )

    not_used = WIDGET_LABEL( row_base10, value = ' (usually 0.300 m/ns, for air)' )

    ; If the user has selected to collect distance information in addition to depth information,
    ; create a new base within TLB to frame and contain all of the input fields below
    ; related to distance:

    IF ( KEYWORD_SET( collect_distance_info ) ) THEN BEGIN

        sub_base2 = WIDGET_BASE( TLB, /col, /frame )

        ; Provide a row to the above widget to define this section of the widget:

        row_base11 = WIDGET_BASE( sub_base2, /row )
        now_used = WIDGET_LABEL( row_base11, value = "Estimated distance settings:" )

        ; Provide another row to the widget for setting the start distance:

        row_base12 = WIDGET_BASE( sub_base2, /row )

        start_distance = WIDGET_PARAM( row_base12, /auto_manage, dt = 4, prompt = 'Start distance (m):', $
            default = 0.0, uvalue = 'start_distance' )

        ; Provide another row to the widget for setting the estimated end distance:

        row_base13 = WIDGET_BASE( sub_base2, /row )

        end_distance = WIDGET_PARAM( row_base13, /auto_manage, dt = 4, prompt = 'End distance (m):', $
            uvalue = 'end_distance' )

    ENDIF

    ; The "AUTO_WID_MNG" function automatically performs event handling of ENVI widgets, without
    ; the need to write an event-handler procedure. The function returns an anonymous structure ("result")
    ; whose tag names are defined by the user values ("uvalue") of the widgets being managed. AUTO_WID_MNG
    ; automatically creates an "OK" and "Cancel" button on the widget unless the optional keyword
    ; NO_BUTTONS is set. In all cases, if the "OK" button is selected, the field "result.accept" (where
    ; "result" is the name of the structure returned by AUTO_WID_MNG) is set to one. Otherwise, if the
    ; "Cancel" button is selected then "result.accept" is set to zero:

    result = AUTO_WID_MNG( TLB )

    RETURN, result

END