;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  collect_input_compute_depth_statistics
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to collect the necessary input parameters for
;;  and then call the associated "compute_depth_statistics.pro" IDL procedure for computing
;;  depth statistics of a linear feature identified within a RAMAC ground-penetrating radar
;;  (GPR) data file. The computed statistics are displayed in a widget window for the user to
;;  view. Please see the documentation for "compute_depth_statistics.pro" for further details
;;  on the statistics that get generated.
;;
;;  In order to produce such statistics, the "compute_depth_statistics.pro" procedure needs to
;;  know the following input parameters:
;;
;;   1. The data file (i.e. the currently viewed GPR data file).
;;
;;   2. The associated ENVI polyline region-of-interest (ROI) file (*.roi) that
;;      identifies a linear feature of interest within the data file (e.g. annual snow
;;      accumulation layer, bottom of a floating ice tongue, etc.).
;;
;;   3. The associated RAMAC header file (*.rad) so that the two-way time window (ns),
;;      transmitter-to-receiver antenna separation (m), and total number of traces
;;      (x-dimension) can be passed to the depth-computing procedure (i.e. "get_gpr_depth.pro")
;;      called within "compute_depth_statistics.pro".
;;
;;  The above parameters are collected by this procedure and then passed to "compute_depth_statistics.pro"
;;  to generate the statistics and display the results to the user.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's function menu configuration file (display.men) located in
;;  ENVI's "menu" directory:
;;
;;      0 {GPR}
;;        1 {Compute Depth Statistics...} {not used} {collect_input_compute_depth_statistics}
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

PRO collect_input_compute_depth_statistics, event

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ; Get the display number of the image window that was used to call this IDL procedure:

    WIDGET_CONTROL, event.top, get_uvalue = display_num

    ; Determine the file ID associated with this file:

    ENVI_DISP_QUERY, display_num, fid = file_id

    ; Determine the filename (including the full path) of this file:

    ENVI_FILE_QUERY, file_id, fname = gpr_file

    ; Determine the directory of this file so that we can use that as the default directory
    ; to search for an associated header file (*.rad):

    gpr_directory = FILE_DIRNAME( gpr_file, /MARK_DIRECTORY )

    ; Let the user select the ROI file associated with this GPR data file:

    roi_file = ENVI_PICKFILE( title = "Select the ROI file associated with this GPR layer:", $
        default = gpr_directory, filter = "*.roi" )

    ; If the user pressed "Cancel" then exit:

    IF ( roi_file EQ '' ) THEN RETURN

    ; Let the user select the RAMAC header file (*.rad) associated with this GPR file:

    header_file = ENVI_PICKFILE( title = "Select the RAMAC header file (*.rad) associated with this GPR file:", $
        default = gpr_directory, filter = "*.rad" )

    ; If the user pressed "Cancel" then exit:

    IF ( header_file EQ '' ) THEN RETURN

    ; Determine the directory of the header file so that we can use that as the default directory
    ; to search for an associated GPS file (*.cor):

    header_directory = FILE_DIRNAME( header_file, /MARK_DIRECTORY )

    ; Compute depth statistics using the above inputs:

    stats = COMPUTE_DEPTH_STATISTICS( gpr_files = [ gpr_file ], roi_files = [ roi_file ], header_file = header_file )

    stddev_depth_percent = ( stats.stddev_depth_meters / stats.mean_depth_meters ) * 100

    ; Display the results to the user; only display SWE results if SWE is a valid number (it will
    ; be set to NaN if the user did not want to display the SWE information):

    IF ( FINITE( stats.mean_swe_gcm2 ) EQ 1 ) THEN BEGIN

        ENVI_INFO_WID, [ '', $
            '  # of measurements: ' + STRTRIM( stats.total_measurements, 2 ), $
            '', $
            '  Mean depth: ' + STRTRIM( stats.mean_depth_meters, 2 ) + ' m', $
            '  Standard deviation, depth: ' + STRTRIM( stats.stddev_depth_meters, 2 ) + ' m' + $
                ' (' + STRTRIM( stddev_depth_percent, 2 ) + '% of mean)', $
            '  Minimum depth: ' + STRTRIM( stats.min_depth_meters, 2 ) + ' m', $
            '  Maximum depth: ' + STRTRIM( stats.max_depth_meters, 2 ) + ' m', $
            '', $
            '  Mean SWE: ' + STRTRIM( stats.mean_swe_gcm2, 2 ) + ' g/(cm^2)' + $
                ' (' + STRTRIM( stats.mean_swe_gcm2 * 10, 2 ) + ' mm)', $
            '  Standard deviation, SWE: ' + STRTRIM( stats.stddev_swe_gcm2, 2 ) + ' g/(cm^2)' + $
                ' (' + STRTRIM( stats.stddev_swe_gcm2 * 10, 2 ) + ' mm)', $
            '  Minimum SWE: ' + STRTRIM( stats.min_swe_gcm2, 2 ) + ' g/(cm^2)' + $
                ' (' + STRTRIM( stats.min_swe_gcm2 * 10, 2 ) + ' mm)', $
            '  Maximum SWE: ' + STRTRIM( stats.max_swe_gcm2, 2 ) + ' g/(cm^2)' + $
                ' (' + STRTRIM( stats.max_swe_gcm2 * 10, 2 ) + ' mm)' ], $
            xs = 62, ys = 13, title = 'GPR Depth Statistics'

    ENDIF ELSE BEGIN

        ENVI_INFO_WID, [ '', $
            '  # of measurements: ' + STRTRIM( stats.total_measurements, 2 ), $
            '', $
            '  Mean depth: ' + STRTRIM( stats.mean_depth_meters, 2 ) + ' m', $
            '  Standard deviation, depth: ' + STRTRIM( stats.stddev_depth_meters, 2 ) + ' m' + $
                ' (' + STRTRIM( stddev_depth_percent, 2 ) + '% of mean)', $
            '  Minimum depth: ' + STRTRIM( stats.min_depth_meters, 2 ) + ' m', $
            '  Maximum depth: ' + STRTRIM( stats.max_depth_meters, 2 ) + ' m' ], $
            xs = 62, ys = 8, title = 'GPR Depth Statistics'

    ENDELSE

END