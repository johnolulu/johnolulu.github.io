;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  gpr_cursor_info
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to track the depth and distance of the current
;;  cursor location as it is moved over any image window of a RAMAC ground-penetrating
;;  radar (GPR) data file. As an interactive user-defined ENVI motion routine, this procedure
;;  has access to information about the position of the current pixel (i.e. the pixel
;;  under the cursor cross-hairs). In order for ENVI to know that it must pass cursor information
;;  to this procedure, you must first define this procedure in the ENVI Configuration File.
;;  Under the main ENVI "File" menu, select "Preferences". Next, under the tab entitled
;;  "User Defined Files", enter the name of this procedure (i.e. "gpr_cursor_info") into
;;  the text box labelled "User Defined Motion Routine" at the bottom of the form. Then
;;  press "OK" to save the new configuration. See "User Move Routines" in the ENVI Online
;;  Help document for further details on ENVI user-defined move and motion routines.
;;
;;  This procedure will then be supplied with cursor location information as you steer the
;;  mouse over an image window of RAMAC GPR data. This information is then used by the helper
;;  procedure entitled "cursor_depth_distance.pro" (which should reside in the ENVI "save_add"
;;  directory) to display a widget that will display the depth (y-axis) and distance (x-axis)
;;  (both in meters) of the current cursor location. To compute the depth and distance, it uses
;;  input parameters from the user supplied in a widget displayed by "cursor_depth_distance.pro"
;;  that get saved in global variables and passed to two routines for calculation:
;;  "get_gpr_depth.pro" and "get_gpr_distance.pro", respectively (both of which also
;;  should reside in the ENVI "save_add" directory). Although the current procedure (i.e.
;;  "gpr_cursor_info") generates the final widget that displays the cursor location, depth
;;  and distance, this widget will not appear until "cursor_depth_distance.pro" is called
;;  by the user: this helper procedure gets called when the user selects "Cursor Depth/Distance..."
;;  from the "GPR" pull-down menu on the image window. Before the information can be displayed,
;;  the user must first enter information about the current GPR file before it can be computed;
;;  namely, the time window, ground velocity, start distance, and end distance. See
;;  "cursor_depth_distance.pro" for further details.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, open the
;;  ENVI "Preferences" menu from the main ENVI "File" menu. On the main tab entitled "User
;;  Defined Files", enter "gpr_cursor_info" in the bottom text box that is labelled "User
;;  Defined Motion Routine". Click "OK" to save the new preference and choose to save these
;;  updated preferences to a file if you wish them to be saved after you close and restart
;;  ENVI. The information from this procedure will not be displayed, however, until the
;;  associated "cursor_depth_distance.pro" procedure is called. See "cursor_depth_distance.pro"
;;  for further details.
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

; All user-defined ENVI functions are technically "event handlers," a special class of
; IDL procedures that are executed in response to a "widget event" occuring. In the case
; of a user-defined ENVI function, the widget event occurs when the user chooses the user
; function's button from the ENVI menu. The procedure definition statement for an ENVI
; user-defined function must therefore include a positional parameter to receive ENVI's
; event structure variable, which is why the procedure statement below includes the
; "event" parameter. Furthermore, as an ENVI user-defined motion routine, the display
; number of the current image window (dn), as well as the current cursor location (xloc,
; yloc) and the start pixels of the image window (xstart, ystart) are also stored in
; variables:

PRO gpr_cursor_info, dn, xloc, yloc, xstart = xstart, ystart = ystart, event = event

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ; The first time the motion routine is called, it creates a common block (i.e. a block of
    ; global variables accessible across multiple procedures and procedure calls) called
    ; "motion_exist" and puts the widget ID of the text widget that displays the current
    ; pixel depth and distance into the variable "data". Reference this common block here
    ; so that the widget ID can be re-used to update the information that it displays as
    ; the cursor moves:

    COMMON motion_exist, data

    ; Reference another common block that is created by the "cursor_depth_distance.pro" helper
    ; procedure, which collects information about the GPR file's time window (ns), ground velocity (m/ns),
    ; first arrival (sample number, y-dimension, where 0 is top of image), direct wave adjustment ("yes" or "no"),
    ; adjustment velocity (m/ns), antenna separation (m), start distance (m), and end distance (m):

    COMMON gpr_file_info, time_window, ground_velocity, first_arrival, direct_wave_adjustment, $
        adjustment_velocity, antenna_separation, start_distance, end_distance

    ; If the "motion_exist" common block doesn't exist yet, then the variable "data" will be undefined--if
    ; this is the case, then set the "data" variable to an invalid widget ID:

    IF ( N_ELEMENTS( data ) EQ 0 ) THEN BEGIN

        data = -1L

    ENDIF

    ; Check to see if the text widget ID in the "data" variable is valid--if it isn't, then
    ; the widget doesn't exist yet and needs to be created here:

    IF ( WIDGET_INFO( data, /VALID ) EQ 0 ) THEN BEGIN

        ; Get the centering offsets for the widget that will be displayed:

        ENVI_CENTER, xoff, yoff

        ; Define the widget that will be displayed:

        motion_base = WIDGET_BASE( /row, title = "Cursor Depth / Distance", xoff = xoff, yoff = yoff, $
            group = ENVI_MAIN_BASE() )
        location_info = WIDGET_TEXT( motion_base, xs = 40, ys = 6 )

        ; By default, the widget is not displayed (map = 0). The helper program, "cursor_depth_distance.pro",
        ; changes the map setting to 1 to display the widget only when the user has selected to view it
        ; from the "GPR" pull-down menu of the image display:

        WIDGET_CONTROL, motion_base, map = 0

        WIDGET_CONTROL, motion_base, /realize

        ; Create the common block with the widget ID of the text widget in the variable
        ; "data" so that the next time this motion routine is called, it will be able
        ; to check if the text widget exists already or not:

        data = location_info
        COMMON motion_exist, data

    ENDIF

    ; If the "gpr_file_info" common block doesn't exist yet, then exit this function:

    IF ( N_ELEMENTS( time_window ) EQ 0 OR N_ELEMENTS( ground_velocity ) EQ 0 OR $
        N_ELEMENTS( start_distance ) EQ 0 OR N_ELEMENTS( end_distance ) EQ 0 ) THEN RETURN

    ; Collect information about this GPR file, including its number of samples (vertical
    ; dimension, or y-axis), and the number of traces (horizontal dimension, or x-axis).
    ; [NOTE: In ENVI-terminology, "samples" are counted in the horizontal dimension ("ns")
    ; and "lines" are counted in the vertical dimension ("nl"), but we use GPR-terminology
    ; here instead to avoid confusion.]:

    ENVI_DISP_QUERY, dn, fid = file_id, nl = num_samples, ns = num_traces

    ; Get the data value of the current pixel location:

    data_value = ENVI_GET_DATA( fid = file_id, dims = [ -1, xloc, xloc, yloc, yloc ], pos = 0 )

    ; Get the depth (in meters) of the current pixel location:

    current_depth = GET_GPR_DEPTH( current_sample = yloc, num_samples = num_samples, $
        time_window = time_window, ground_velocity = ground_velocity, first_arrival = first_arrival, $
        direct_wave_adjustment = direct_wave_adjustment, adjustment_velocity = adjustment_velocity, $
        antenna_separation = antenna_separation )

    ; Get the distance (in meters) of the current pixel location:

    current_distance = GET_GPR_DISTANCE( current_trace = xloc, num_traces = num_traces, $
        start_distance = start_distance, end_distance = end_distance )

    ; Create the message string that will go into the text widget:

    msg = [ "Disp #" + STRTRIM( dn + 1, 2 ), $
        "Pixel coordinate: (" + STRTRIM( xloc + xstart + 1, 2 ) + ", " + STRTRIM( yloc + ystart + 1, 2 ) + ")", $
        "Depth (m): " + STRTRIM( STRING( current_depth, FORMAT = '(F0.2)' ), 2), $
        "Distance (m): " + STRTRIM( STRING( current_distance, FORMAT = '(F0.2)' ), 2), $
        "Data: " + STRTRIM( data_value, 2 ) ]

    ; Update the text widget that holds the message:

    WIDGET_CONTROL, data, set_value = msg, /no_copy

END