;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  cursor_depth_distance
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to track the depth and distance of the current
;;  cursor location as it is moved over any image window of a RAMAC ground-penetrating
;;  radar (GPR) data file. The current procedure gets called by selecting the "Cursor
;;  Depth/Distance..." option from the "GPR" pull-down menu of the image window. A widget
;;  will then appear that asks the user to define certain characteristics about the currently
;;  displayed GPR file so that the cursor depth and distance can be computed. Namely, the
;;  time window (in nanoseconds), ground velocity (in meters per nanosecond), start distance
;;  of the left-most pixel in the data file (in meters), and the end distance of the right-most
;;  pixel in the data file (in meters). The time window is automatically determined from
;;  the ENVI header file (*.rad) associated with the current data file (*.rd3) after asking
;;  the user where the header file (*.rad) is located.
;;
;;  The time window and ground velocity terminology and usage is modelled after RAMAC
;;  GroundVision software, which similarly requires the user to enter these parameters in
;;  order to convert time to depth for the scale bars that are displayed to the right and left
;;  of the data imagery in GroundVision. The time window is the amount of time (in nanoseconds)
;;  that the radar receiver was set to "listen" for the return pulse after each radar pulse was
;;  released from the transmitting antenna during data acquisition. If the time window is set to
;;  40 ns, for example, that means an individual radar pulse has a maximum time duration of 20 ns
;;  to reach a reflector and 20 more ns to reflect back to the receiver in order to be recorded in
;;  the data file. The bottom of the data file therefore represents a maximum duration of 20 ns for
;;  a time window of 40 ns. The ground velocity represents (in meters per nanosecond) how fast the
;;  radar pulses travelled through the subsurface medium being imaged in the data file. Ground
;;  velocities range from slow (e.g. 0.03 m/ns for fresh water) to fast (e.g. 0.3 m/ns for air)
;;  and the user should refer to a GPR textbook or manual for the proper value related to the media
;;  being imaged. For dry snow on the Greenland ice sheet, for example, an average value of 0.236 m/ns
;;  may suffice if the value has not been measured in a snow pit, based on an average dry snow density
;;  of 0.3 grams per cubic centimeter that has been empirically related to a dry snow permittivity of
;;  1.62 by the following publication:
;;
;;      Mätzler, C. (1996), Microwave permittivity of dry snow. IEEE Transactions on Geoscience
;;      and Remote Sensing. 34(2): 573-581.
;;
;;  Given an average dry snow permittivity of 1.62, an average radar velocity of 0.236 m/ns
;;  can be derived by dividing the speed of light in a vaccuum (0.3 m/ns) by the square root
;;  of this permittivity.
;;
;;  The user may also select the sample of the "first arrival" of the radar pulse reaching
;;  the subsurface: depth computations will start at this sample number (y-axis). Often
;;  in GPR data, there is an obvious lack of backscatter at the top of the file that results
;;  from the empty space that occurred between the antenna and the surface. The first arrival
;;  begins at the point where obvious backscatter begins. The user may also select whether or
;;  not to adjust the first arrival travel time by the "direct wave." The direct wave is the
;;  part of the transmitted energy that travels the shortest distance between the transmitter
;;  and receiver. Due to antenna separation, the wave traveling from the transmitter directly
;;  to the receiver (i.e. the direct wave) is received some time after the actual transmission.
;;  This means that the transmitted pulse has already penetrated the medium a certain distance
;;  before the direct wave is received. The result of this is that the depth scale zero must
;;  be corrected to be accurate. The zero for the depth scale is calculated using the first
;;  arrival value, the antenna separation, and the first arrival adjustment velocity. The
;;  adjustment velocity can be set to any value. Practically however, it can be the ground
;;  velocity, the air velocity (most common), or anything in between depending on the antenna
;;  configuration.
;;
;;  The start and end distances may only be educated guess-timates if you have not measured the
;;  distance of your GPR survey in the field. In most cases, the start distance will be 0 meters
;;  but can be set differently. The distance of the current cursor location will be interpolated
;;  between the provided start and end distances. If you do not know the distance of your survey,
;;  you may provide 0 for both distances, or just make something up and ignore the distance
;;  field in the output widget.
;;
;;  These input parameters are then stored in global ("common") variables that are accessible by
;;  a user-defined ENVI motion routine named "gpr_cursor_info.pro" that is responsible for
;;  displaying a widget window that updates the current depth (y-axis) and distance (x-axis)
;;  (both in meters) of the cursor as the mouse is moved over the surface of an image display of any
;;  RAMAC GPR file. See "gpr_cursor_info.pro" for further details and on how to set that procedure up
;;  as a viable ENVI user-defined motion routine (NOTE: this requires changes to the ENVI Preferences).
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's function menu configuration file (display.men) located in
;;  ENVI's "menu" directory:
;;
;;      0 {GPR}
;;        1 {Cursor Depth/Distance...} {not used} {cursor_depth_distance}
;;
;;  This procedure can then be run from the pull-down menu labelled "GPR" on a GPR
;;  file that you have already opened in ENVI.
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
; "event" parameter:

PRO cursor_depth_distance, event

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ; Set certain variables into a common block (i.e. a block of global variables accessible
    ; across multiple procedures and procedure calls) so that the "gpr_cursor_info.pro"
    ; ENVI motion routine has access to them, which are needed in order to compute the
    ; current cursor location's depth and distance by that routine:

    COMMON gpr_file_info, time_window, ground_velocity, first_arrival, direct_wave_adjustment, $
        adjustment_velocity, antenna_separation, start_distance, end_distance

    ; Ask the user for the RAMAC "*.rad" header file that corresponds to the image being viewed.
    ; This is needed to figure out the time window (ns) and antenna separation (m) for the
    ; current GPR data:

    ; Ask the user to select a RAMAC GPR header file:

    header_file = ENVI_PICKFILE( title = "Select the RAMAC header file (*.rad) that is associated with this GPR image:", $
        filter = "*.rad" )

    ; If the user pressed "Cancel" then exit:

    IF ( header_file[0] EQ '' ) THEN RETURN

    ; Open the header file into IDL:

    OPENR, lun, header_file, /GET_LUN

    ; Create a string array to read the header file into. A RAMAC "*.rad" header file has
    ; one column of information with 38 rows each containing a single "PARAMETER:VALUE"
    ; string (e.g. "SAMPLES:1024"):

    header_file_contents = STRARR( 38 )

    ; Read the "*.rad" header file contents into the string array as free-format ASCII:

    READF, lun, header_file_contents
    FREE_LUN, lun

    ; Get the time window (ns) and antenna separation (m) from the header array for this data file:

    time_window = header_file_contents[ 18 ] ; two-way travel time (TWT) in nanoseconds (ns)
    time_window = DOUBLE( STRMID( time_window, 11 ) )

    antenna_separation = header_file_contents[ 16 ]
    antenna_separation = DOUBLE( STRMID( antenna_separation, 19 ) )

    ; Get the first and last sample numbers of the image window that was used to call this
    ; IDL procedure; this will be sent to the call for "collect_input_get_gpr_depth":

    WIDGET_CONTROL, event.top, get_uvalue = display_num
    ENVI_DISP_QUERY, display_num, fid = file_id
    ENVI_FILE_QUERY, file_id, ystart = ystart, nl = num_samples

    ; Create an IDL "widget" to allow user input for distance and depth conversion settings:

    result = COLLECT_INPUT_GET_GPR_DEPTH( ystart = ystart, num_samples = num_samples, time_window = time_window, $
        antenna_separation = antenna_separation, /COLLECT_DISTANCE_INFO )

    ; If the user pressed "Cancel" then exit:

    IF ( result.accept EQ 0 ) THEN RETURN

    ; Set the following result structure fields to their own variables:

    ground_velocity = result.ground_velocity
    first_arrival = result.first_arrival
    direct_wave_adjustment = result.direct_wave_adjustment
    adjustment_velocity = result.adjustment_velocity
    start_distance = result.start_distance
    end_distance = result.end_distance

    ; The first arrival is returned in image coordinates (ystart=1 is top pixel and num_samples is
    ; bottom pixel). Convert this to file coordinates (i.e. top pixel is 0) for use by the
    ; "get_gpr_depth.pro" procedure and adjust by the ystart (which may not be greater than 1):

    first_arrival = first_arrival - ystart

    ; Reference a common block (i.e. a block of global variables accessible across multiple
    ; procedures and procedure calls) called "motion_exist" that is defined by the ENVI
    ; motion routine "gpr_cursor_info.pro" and stores the widget ID of the text
    ; widget that displays the current pixel depth and distance into the variable "data".
    ; Use this to make the widget visible by setting the "map" variable to 1:

    COMMON motion_exist, data

    WIDGET_CONTROL, data, map = 1

END