;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  create_xyz_file
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure creates an XYZ file (latitude, longitude, depth) of a linear feature
;;  identified within one or more RAMAC ground-penetrating radar (GPR) data files. An "XYZ
;;  file" is a text file with three space-delimited columns: the first column (X) contains
;;  a latitude (in decimal degrees: e.g. 78.0167778), the second column (Y) contains a longitude
;;  (also in decimal degrees: e.g. 33.9808222), and the third column (Z) contains a depth
;;  measurement (in negative meters: e.g. -0.661157). Such a file can be used to create a
;;  regularly-gridded data file that can then be visualized in three-dimensions. Both IDL's
;;  "iTools" and the Surfer software package (http://goldensoftware.com) are examples of tools
;;  that can be easily used to both grid and view the XYZ text file in three dimensions.
;;
;;  In order to output the XYZ file, this procedure gets the pixel location of each specified
;;  ROI file and uses further input from the user (i.e. ground radar velocity, sample number [y-
;;  dimension] of first arrival, whether to adjust for the direct wave, etc.) to compute the
;;  depth of each of these pixel locations (using "get_gpr_depth.pro"). Each pixel location
;;  can also be associated with an associated trace number (x-dimension) in the RAMAC
;;  GPS coordinates file (.cor), for which the coordinates are converted from degree:minutes:seconds
;;  format to double-precision floating-point decimal degrees. The user is also asked
;;  for an output file location at which to write the XYZ output to.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  create_xyz_file, gpr_files = gpr_files, roi_files = roi_files, header_file = header_file, $
;;      gps_file = gps_file
;;
;;  Return Value:
;;
;;  Does not return anything to IDL. Outputs a text file with three space-delimited columns at a file
;;  location specified by the user before processing. The first column (X) contains a latitude (in
;;  decimal degrees: e.g. 78.0167778), the second column (Y) contains a longitude (also in decimal
;;  degrees: e.g. 33.9808222), and the third column (Z) contains a depth measurement (in negative
;;  meters: e.g. -0.661157). Latitude and longitude are reported as double-precision floating-point
;;  values with seven decimal places while depth is reported as a single-precision floating-point
;;  value with six decimal places. For example:
;;
;;      78.0167778     33.9808222      -0.695942
;;      78.0167694     33.9808361      -0.666542
;;      78.0167556     33.9807333      -0.681242
;;      78.0167694     33.9808694      -0.784144
;;      78.0167639     33.9808694      -0.784144
;;
;;  Keywords:
;;
;;  gpr_files (string array) = The data file(s) for which to generate an XYZ file. Each file should be
;;      specified with its full path and filename.
;;
;;  roi_files (string array) = The associated ENVI polyline region-of-interest (ROI) files (*.roi) that
;;      identify a linear feature of interest within the data files (e.g. annual snow
;;      accumulation layer, bottom of a floating ice tongue, etc.). There must be
;;      one ROI file selected per data file. Also, in order for the "create_xyz_file.pro"
;;      to know which ROI file goes with which data file, the ROI files must be listed
;;      in alphabetical order in the same manner as the associated data files. Each file should
;;      be specified with its full path and filename.
;;
;;  header_file (string) = The associated RAMAC header file (*.rad) so that the two-way time window (ns),
;;      transmitter-to-receiver antenna separation (m), and total number of traces
;;      (x-dimension) can be passed to the depth-computing procedure (i.e. "get_gpr_depth.pro"). When
;;      specifying multiple data files (e.g. spatial subsets/transects of an original RAMAC *.rd3 data file),
;;      therefore, each must conform to the same time window and antenna separation. The header file
;;      should be specified with its full path and filename.
;;
;;  gps_file (string) = The RAMAC GPS coordinates file (*.cor) that contains the latitude and longitude
;;      for every trace (x-dimension) in the original *.rd3 RAMAC data file. RAMAC
;;      "GroundVision" software can be set to collect GPS data in the GroundVision Standard
;;      (*.cor) format during data acquisition. At this time, other GPS file formats are not
;;      accepted. The GroundVision Standard format (*.cor) is a comma-delimited text file with
;;      latitude and longitude in the 4th and 5th columns respectively, where both
;;      are expressed in units of degrees:minutes:seconds as in the following example:
;;
;;          78:01:00.42 NN,33:58:50.96 WW
;;
;;      When selecting multiple data files (e.g. spatial subsets/transects of an original RAMAC
;;      *.rd3 data file), therefore, each must be contained by the selected *.cor GPS coordinates
;;      file. When subsetting, therefore, it is necessary to record the "xstart" location of every
;;      subset/transect so that these files record their location within the original
;;      *.rd3 RAMAC data file and can thereby find their associated GPS coordinates in the *.cor file.
;;      The GPS file should be specified with its full path and filename.
;;
;;  Examples:
;;
;;  create_xyz_file, gpr_files = [ 'C:\GPR_data\GPR_data_file1.rd3' ], roi_files = [ 'C:\GPR_data\GPR_layer1.roi' ], $
;;      header_file = 'C:\GPR_data\GPR_data_file1.rad', gps_file = 'C:\GPR_data\GPR_data_file1.cor'
;;
;;  create_xyz_file, gpr_files = [ 'C:\GPR_data\GPR_transect1.bin', 'C:\GPR_data\GPR_transect2.bin' ], $
;;      roi_files = [ 'C:\GPR_data\GPR_transect1.roi', 'C:\GPR_data\GPR_transect2.roi' ], $
;;      header_file = 'C:\GPR_data\GPR_data_file1.rad', gps_file = 'C:\GPR_data\GPR_data_file1.cor'
;;
;;  -------------------------------------------------------------------------------------
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI:
;;
;;  To use this procedure within ENVI, refer to the documentation for the following two
;;  IDL procedures:
;;
;;      1. collect_input_create_xyz_file.pro
;;      2. collect_input_bulk_xyz_file.pro
;;
;;  The above procedures can be used to gather the necessary input and call this procedure
;;  (i.e. "create_xyz_file.pro") on either a single file that is already open in ENVI
;;  or on multiple files, respectively.
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

PRO create_xyz_file, gpr_files = gpr_files, roi_files = roi_files, header_file = header_file, gps_file = gps_file

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

    IF ( N_ELEMENTS( gpr_files ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: No RAMAC GPR files (*.rd3) (e.g. gpr_files=gpr_files) were specified."
    ENDIF

    IF ( N_ELEMENTS( roi_files ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: No ROI files (*.roi) (e.g. roi_files=roi_files) were specified."
    ENDIF

    IF ( N_ELEMENTS( header_file ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: A RAMAC header file (*.rad) (e.g. header_file=header_file) was not specified."
    ENDIF

    IF ( N_ELEMENTS( gps_file ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: A RAMAC GPS file (*.cor) (e.g. gps_file=gps_file) was not specified."
    ENDIF

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 1:
    ;;
    ;;  Get time-to-depth conversion settings.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Get the time window and antenna separation from the specified header file so that this
    ; information can be passed to the "collect_input_get_gpr_depth.pro" procedure:

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

    ; Get the total number of traces (x-dimension) from the header array to be used for
    ; reading in the GPS file (*.cor) below:

    num_traces = header_file_contents[ 22 ]
    num_traces = ULONG64( STRMID( num_traces, 11 ) )

    ; Get the first sample number and total number of samples (vertical- or y- dimension) of the
    ; first specified GPR file. All GPR files specified in the "gpr_files" array need to have these
    ; same settings in order for this procedure to work properly:

    ; ...Get the file ID associated with the first GPR file:

    ENVI_OPEN_FILE, gpr_files[ 0 ], r_fid = gpr_file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

    ; ...Determine the number of the first sample (y-dimension) for this GPR file as well as the
    ; total number of samples (y-dimension):

    ENVI_FILE_QUERY, gpr_file_id, ystart = ystart, nl = num_samples

    ; Gather input from the user for the time-to-depth conversion settings to be applied to each
    ; of the specified ROI files:

    result = COLLECT_INPUT_GET_GPR_DEPTH( ystart = ystart, num_samples = num_samples, time_window = time_window, $
        antenna_separation = antenna_separation )

    ; If the user pressed "Cancel" then exit:

    IF ( result.accept EQ 0 ) THEN RETURN

    ; Set the following result structure fields to their own variables:

    ground_velocity = result.ground_velocity
    first_arrival = result.first_arrival
    direct_wave_adjustment = result.direct_wave_adjustment
    adjustment_velocity = result.adjustment_velocity

    ; The first arrival is returned in image coordinates (ystart=1 is top pixel and num_samples is
    ; bottom pixel). Convert this to file coordinates (i.e. top pixel is 0) for use by the
    ; "get_gpr_depth.pro" procedure and adjust by the ystart (which may not be greater than 1):

    first_arrival = first_arrival - ystart

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 2:
    ;;
    ;;  Open an output file for writing to.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Determine the directory of the first GPR data file so that we can use that as the default directory
    ; to output to:

    header_directory = FILE_DIRNAME( header_file, /MARK_DIRECTORY )

    ; Determine the base of the header filename so that we can construct a default output filename from this:

    header_basename = FILE_BASENAME( header_file, '.rad' )

    ; Put together a default directory and filename to output the XYZ data to:

    default_file = header_directory + header_basename + '_xyz.txt'

    ; Ask the user where to create the output file:

    TLB = WIDGET_AUTO_BASE( title = "Select an output file to write the XYZ data to:" )
    row1 = WIDGET_OUTF( TLB, /auto_manage, default = default_file, uvalue = 'output_file', xsize = 75 )
    result = AUTO_WID_MNG( TLB )

    ; If the user pressed "Cancel" then exit:

    IF ( result.accept EQ 0 ) THEN RETURN

    output_file = result.output_file

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 3:
    ;;
    ;;  Open and read in GPS file contents.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Open the GPS file:

    OPENR, lun, gps_file, /GET_LUN

    ; Create a string array to read the coordinates file into. A RAMAC "*.cor" coordinates file
    ; has 7 comma-separated columns of information with as many rows as there are traces (x-dimension)
    ; in the corresponding data (*.rd3) file. In particular, the 3rd and 4th columns contain latitude
    ; and longitude, respectively, in the following format: 78:01:00.42 NN,33:58:50.96 W:

    gps_file_contents = STRARR( num_traces )

    ; Read the "*.cor" coordinates file contents into the string array as free-format ASCII:

    READF, lun, gps_file_contents
    FREE_LUN, lun

    ; Create separate arrays to hold each of the latitude and longitude columns:

    latitudes = DBLARR( num_traces )
    longitudes = DBLARR( num_traces )

    ; Set up a status window to show what percentage of the GPS file has been
    ; read in so far:

    ENVI_REPORT_INIT, [ 'Reading in RAMAC GPS coordinates file (*.cor):', gps_file ], base = status_base, /interrupt, $
        title = 'Reading in GPS coordinates file...'

    FOR i = 0, num_traces - 1 DO BEGIN

        row_contents = STRSPLIT( gps_file_contents[ i ], ',', /EXTRACT )
        latitude = row_contents[ 3 ]
        longitude = row_contents[ 4 ]

        ; Convert degrees:minutes:seconds format (e.g. 78:01:00.42 NN) to decimal degrees:

        latitude_degrees = DOUBLE( STRMID( latitude, 0, 2 ) )
        latitude_minutes = DOUBLE( STRMID( latitude, 3, 2 ) )
        latitude_seconds = DOUBLE( STRMID( latitude, 6, 5 ) )
        latitude_hemisphere = STRMID( latitude, 12, 1 )

        latitudes[ i ] = latitude_degrees + ( latitude_minutes / 60 ) + ( latitude_seconds / 60 / 60 )

        longitude_degrees = DOUBLE( STRMID( longitude, 0, 2 ) )
        longitude_minutes = DOUBLE( STRMID( longitude, 3, 2 ) )
        longitude_seconds = DOUBLE( STRMID( longitude, 6, 5 ) )
        longitude_hemisphere = STRMID( longitude, 12, 1 )

        longitudes[ i ] = longitude_degrees + ( longitude_minutes / 60 ) + ( longitude_seconds / 60 / 60 )

        ; Update the status window with the current percentage of completion:

        ENVI_REPORT_STAT, status_base, i, num_traces - 1, cancel = cancel

        ; If the user chooses to cancel processing from the status window, delete the
        ; status window and exit the program:

        IF ( cancel EQ 1 ) THEN BEGIN
            ENVI_REPORT_INIT, base = status_base, /finish
            RETURN
        ENDIF

    ENDFOR

    ; Close the status window:

    ENVI_REPORT_INIT, base = status_base, /finish

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 4:
    ;;
    ;;  Process each ROI file individually.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Open a text file for writing the XYZ data to at the user-specified output filename:

    OPENW, lun, output_file, /GET_LUN

    ; Determine how many GPR files are in the "gpr_files" array:

    num_gpr_files = N_ELEMENTS( gpr_files )

    ; Determine how many ROI files were selected:

    num_roi_files = N_ELEMENTS( roi_files )

    ; Cause an error if the number of GPR files does not match the number of ROI files:

    IF ( num_gpr_files NE num_roi_files ) THEN BEGIN
       MESSAGE, "ERROR!: The number of specified GPR data files does not match the number of ROI files (*.roi)."
    ENDIF

    ; Set up a status window to show what percentage of the ROI files have been processed so far:

    IF ( num_gpr_files GT 1 ) THEN BEGIN
        ENVI_REPORT_INIT, [ 'Processing ' + STRTRIM( num_roi_files, 2 ) + ' ROI files...', '', $
            'Output file: ', output_file ], base = status_base, /interrupt, title = 'Generating XYZ file...'
    ENDIF

    ; Process each ROI file individually:

    FOR i = 0, num_roi_files - 1 DO BEGIN

        ; Restore the desired ROI file into ENVI's memory; this is necessary in order to use
        ; ENVI_GET_ROI_IDS below:

        ENVI_RESTORE_ROIS, roi_files[ i ]

        ; Get the file ID associated with this GPR file:

        ENVI_OPEN_FILE, gpr_files[ i ], r_fid = gpr_file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

        ; Determine the number of the first trace (x-dimension) and sample (y-dimension)
        ; for this GPR file as well as the total number of samples (y-dimension) and traces (x-dimension):

        ENVI_FILE_QUERY, gpr_file_id, xstart = xstart, ystart = ystart, nl = num_samples, ns = num_traces

        ; Get the ROI ID associated with this GPR file ID:

        roi_id = ENVI_GET_ROI_IDS( fid = gpr_file_id )

        ; Get the pixel addresses associated with this ROI. ROI addresses are one-dimensional
        ; spatial addresses that need to be converted to (x,y) locations below:

        roi_pixel_addresses = ENVI_GET_ROI( roi_id )

        ; For every pixel in this ROI, output the latitude, longitude, and depth to the output file:

        FOR j = 0, N_ELEMENTS( roi_pixel_addresses ) - 1 DO BEGIN

            ; First, compute x and y file coordinates for each pixel address. File coordinates
            ; always begin with 0. (0, 0) in file coordinates represents the upper-left-hand
            ; corner of the data image:

            y_file_coordinate = roi_pixel_addresses[ j ] / num_traces
            x_file_coordinate = roi_pixel_addresses[ j ] - ( y_file_coordinate * num_traces )

            ; Next, convert the file coordinates to image coordinates by adding the
            ; "xstart" and "ystart" locations identified in the current GPR file.
            ; Because "xstart" and "ystart" are zero-based, furthermore, add 1 so
            ; that they are one-based instead. For more information on file coordinates
            ; versus image coordinates, see the "Coordinate Systems in ENVI" page of
            ; the ENVI Online Help:

            y_image_coordinate = y_file_coordinate + ystart + 1
            x_image_coordinate = x_file_coordinate + xstart + 1

            ; Compute the depth for this pixel (note: assumes zero-based y-coordinate, so subtracts 1):

            depth = GET_GPR_DEPTH( current_sample = y_image_coordinate - 1, num_samples = num_samples, $
                time_window = time_window, ground_velocity = ground_velocity, first_arrival = first_arrival, $
                direct_wave_adjustment = direct_wave_adjustment, adjustment_velocity = adjustment_velocity, $
                antenna_separation = antenna_separation )

            ; Convert the depth to a negative number so that the surface plot shows
            ; concave depths instead of convex depths:

            depth -= ( 2 * depth )

            ; Print the latitude, longitude, and computed depth (i.e. XYZ data) to the output file:

            PRINTF, lun, latitudes[ x_image_coordinate ], longitudes[ x_image_coordinate ], $
                depth, FORMAT = '( D15.7, D15.7, F15.6 )'

        ENDFOR

        ; Delete the ROI from ENVI memory now that we are done with it:

        ENVI_DELETE_ROIS, roi_id

        ; Update the status window with the current percentage of completion:

        IF ( num_gpr_files GT 1 ) THEN BEGIN
            ENVI_REPORT_STAT, status_base, i, num_roi_files - 1, cancel = cancel

            ; If the user chooses to cancel processing from the status window, delete the
            ; status window and exit the program:

            IF ( cancel EQ 1 ) THEN BEGIN
                ENVI_REPORT_INIT, base = status_base, /finish
                RETURN
            ENDIF
        ENDIF

    ENDFOR

    ; Close the status window:

    IF ( num_gpr_files GT 1 ) THEN BEGIN
        ENVI_REPORT_INIT, base = status_base, /finish
    ENDIF

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 5:
    ;;
    ;;  Close the output file.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    FREE_LUN, lun

    ; Inform the user that processing is complete (otherwise, they may wonder if
    ; anything was done or not):

    ENVI_INFO_WID, [ '  Processing complete!', '', '  See output file at: ', '  ' + output_file ], $
        xs = 50, title = 'XYZ file completed'

END