;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  collect_input_create_xyz_file
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to collect the necessary input parameters for
;;  and then call the associated "create_xyz_file.pro" IDL procedure for creating an
;;  XYZ file (latitude, longitude, depth) of a layer identified within a RAMAC ground-
;;  penetrating radar (GPR) data file. An "XYZ file" is a text file with three space-
;;  delimited columns: the first column (X) contains a latitude (in decimal degrees:
;;  e.g. 78.0167778), the second column (Y) contains a longitude (also in decimal degrees:
;;  e.g. 33.9808222), and the third column (Z) contains a depth measurement (in negative
;;  meters: e.g. -0.661157). Such a file can be used to create a regularly-gridded data
;;  file that can then be visualized in three-dimensions. Both IDL's "iTools" and Surfer
;;  software (http://goldensoftware.com) are examples of tools that can be easily used
;;  to both grid and view the XYZ text file in three dimensions.
;;
;;  In order to produce such an XYZ file, the "create_xyz_file.pro" procedure needs to
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
;;      called within "create_xyz_file.pro".
;;
;;   4. The RAMAC GPS coordinates file (*.cor) that contains the latitude and longitude
;;      for every trace (x-dimension) in the data file. RAMAC "GroundVision" software
;;      can be set to collect GPS data in the GroundVision Standard (*.cor) format during
;;      data acquisition. At this time, other GPS file formats are not acceptable.
;;      The GroundVision Standard format (*.cor) is a comma-delimited text file with
;;      latitude and longitude in the 4th and 5th columns respectively, where both
;;      are expressed in units of degrees:minutes:seconds as in the following example:
;;
;;          78:01:00.42 NN,33:58:50.96 WW
;;
;;  The above parameters are collected by this procedure and then passed to "create_xyz_file.pro"
;;  to generate an XYZ file at a user-specified file location.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's function menu configuration file (display.men) located in
;;  ENVI's "menu" directory:
;;
;;      0 {GPR}
;;        1 {Create XYZ File...} {not used} {collect_input_create_xyz_file}
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

PRO collect_input_create_xyz_file, event

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

    ; Let the user select the RAMAC GPS file (*.cor) associated with this GPR file:

    gps_file = ENVI_PICKFILE( title = "Select the RAMAC GPS file (*.cor) associated with this GPR file:", $
        default = header_directory, filter = "*.cor" )

    ; If the user pressed "Cancel" then exit:

    IF ( gps_file EQ '' ) THEN RETURN

    ; Create an XYZ file using the above inputs:

    CREATE_XYZ_FILE, gpr_files = [ gpr_file ], roi_files = [ roi_file ], header_file = header_file, $
        gps_file = gps_file

END