;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  compute_depth_statistics
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure computes statistics for the depth of a linear feature within a RAMAC
;;  ground-penetrating radar (GPR) data file or files. This linear feature (e.g. annual snow
;;  accumulation layer, bottom of a floating ice tongue, etc.) should be previously digitized
;;  in an ENVI polyline region-of-interest (ROI) file (*.roi) or files. The statistics reported
;;  are the mean, max, and min depths (in meters) and the standard deviation of the depth (in meters).
;;  In addition, these depth statistics can also be expressed in terms of snow water equivalent (SWE)
;;  if the subsurface in the GPR data is snow/ice. In order to accomplish this, the user is presented
;;  with a window to input the average density of the subsurface (in grams per cubic centimeter).
;;  The SWE is then returned in grams per squared centimeter; this can be converted by the end-user
;;  to units of millimeters simply by dividing by the density of water (1 g/(cm^3)) and multiplying by
;;  10.
;;
;;  In order to output these statistics, this procedure gets the pixel location of each specified
;;  ROI file and uses further input from the user (i.e. ground radar velocity, sample number [y-
;;  dimension] of first arrival, whether to adjust for the direct wave, etc.) to compute the
;;  depth of each of these pixel locations (using "get_gpr_depth.pro").
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  statistics = compute_depth_statistics( gpr_files = gpr_files, roi_files = roi_files, header_file = header_file )
;;
;;  Return Value:
;;
;;  statistics.total_measurements (integer) = The total number of pixel addresses in the polyline region-of-interest
;;      (ROI) used in the depth/SWE statistics reported below. Note that this may be greater than the number of
;;      pixels in the x-dimension in the corresonding data file(s) since the polyline may include multiple
;;      samples (y-dimension) at a particular trace (x-dimension).
;;
;;  statistics.mean_depth_meters (float) = The mean depth in meters of the selected linear feature.
;;
;;  statistics.stddev_depth_meters (float) = The standard deviation in meters of the selected linear feature.
;;
;;  statistics.min_depth_meters (float) = The minimum depth in meters of the selected linear feature.
;;
;;  statistics.max_depth_meters (float) = The maximum depth in meters of the selected linear feature.
;;
;;  statistics.mean_swe_gcm2 (float or NaN) = The mean snow water equivalent (SWE) in units of grams per
;;      squared centimeter (g/(cm^2)) of the selected linear feature. If the user did not provide a subsurface
;;      density because SWE is irrelevant to the subsurface being measured, this value will be an invalid value
;;      (IDL's "NaN", for "not a number").
;;
;;  statistics.stddev_swe_gcm2 (float or NaN) = The standard deviation of SWE in units of grams per
;;      squared centimeter (g/(cm^2)) of the selected linear feature. If the user did not provide a subsurface
;;      density because SWE is irrelevant to the subsurface being measured, this value will be an invalid value
;;      (IDL's "NaN", for "not a number").
;;
;;  statistics.min_swe_gcm2 (float or NaN) = The minimum SWE in units of grams per squared centimeter (g/(cm^2))
;;      of the selected linear feature. If the user did not provide a subsurface density because SWE is irrelevant
;;      to the subsurface being measured, this value will be an invalid value (IDL's "NaN", for "not a number").
;;
;;  statistics.max_swe_gcm2 (float or NaN) = The maximum SWE in units of grams per squared centimeter (g/(cm^2))
;;      of the selected linear feature. If the user did not provide a subsurface density because SWE is irrelevant
;;      to the subsurface being measured, this value will be an invalid value (IDL's "NaN", for "not a number").
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
;;  Examples:
;;
;;  statistics = compute_depth_statistics( gpr_files = [ 'C:\GPR_data\GPR_data_file1.rd3' ], $
;;      roi_files = [ 'C:\GPR_data\GPR_layer1.roi' ], header_file = 'C:\GPR_data\GPR_data_file1.rad' )
;;
;;  statistics = compute_depth_statistics( gpr_files = [ 'C:\GPR_data\GPR_transect1.bin', $
;;      'C:\GPR_data\GPR_transect2.bin' ], roi_files = [ 'C:\GPR_data\GPR_transect1.roi', $
;;      'C:\GPR_data\GPR_transect2.roi' ], header_file = 'C:\GPR_data\GPR_data_file1.rad' )
;;
;;  -------------------------------------------------------------------------------------
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI:
;;
;;  To use this procedure within ENVI, refer to the documentation for the following two
;;  IDL procedures:
;;
;;      1. collect_input_compute_depth_statistics.pro
;;      2. collect_input_bulk_depth_statistics.pro
;;
;;  The above procedures can be used to gather the necessary input and call this procedure
;;  (i.e. "compute_depth_statistics.pro") on either a single file that is already open in ENVI
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

FUNCTION compute_depth_statistics, gpr_files = gpr_files, roi_files = roi_files, header_file = header_file

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

    IF ( result.accept EQ 0 ) THEN BEGIN
        RETURN, ''
    ENDIF

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
    ;;  Get the density of the subsurface for computing
    ;;  snow water equivalent (SWE) (if relevant).
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Ask the user for the average density (in units of grams per cubic centimeter):

    TLB = WIDGET_AUTO_BASE( title = "Depth to SWE conversion settings:" )

    ; Add a row to the above widget explaining what this conversion is for:

    row_base1 = WIDGET_BASE( TLB, /row )

    swe_explanation = 'If the subsurface is snow, the mean depth can be multiplied by the average density ' + $
       'to derive snow water equivalent (SWE):'

    not_used = WIDGET_LABEL( row_base1, value = swe_explanation )

    ; Add a row to the widget to allow the user to input the average snow density of
    ; the subsurface being measured in the GPR data:

    row_base2 = WIDGET_BASE( TLB, /row )

    density = WIDGET_PARAM( row_base2, /auto_manage, dt = 4, prompt = 'Average subsurface density [ g/(cm^3) ]:', $
        floor = 0.001, ceil = 0.999, field = 3, uvalue = 'density' )

    not_used = WIDGET_LABEL( row_base2, value = ' (e.g. 0.1 to 0.5 for snow; 0.917 for ice)' )

    ; Add a row explaining to the user that they can press 'Cancel' to ignore the SWE conversion
    ; (if their subsurface is now snow, for instance):

    row_base3 = WIDGET_BASE( TLB, /row )
    not_used = WIDGET_LABEL( row_base3, value = 'Press "Cancel" to ignore the depth-to-SWE conversion and continue.' )

    ; The "AUTO_WID_MNG" function automatically performs event handling of ENVI widgets, without
    ; the need to write an event-handler procedure. The function returns an anonymous structure ("result")
    ; whose tag names are defined by the user values ("uvalue") of the widgets being managed. AUTO_WID_MNG
    ; automatically creates an "OK" and "Cancel" button on the widget unless the optional keyword
    ; NO_BUTTONS is set. In all cases, if the "OK" button is selected, the field "result.accept" (where
    ; "result" is the name of the structure returned by AUTO_WID_MNG) is set to one. Otherwise, if the
    ; "Cancel" button is selected then "result.accept" is set to zero:

    result = AUTO_WID_MNG( TLB )

    ; If the user pressed "Cancel" then ignore the density measurement:

    IF ( result.accept NE 0 ) THEN BEGIN
        density = result.density
    ENDIF ELSE BEGIN
        density = !VALUES.F_NAN  ; IDL's variable for "not a number (NaN)"
    ENDELSE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 3:
    ;;
    ;;  Create a depth array from each ROI file.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Determine how many GPR files are in the "gpr_files" array:

    num_gpr_files = N_ELEMENTS( gpr_files )

    ; Determine how many ROI files were selected:

    num_roi_files = N_ELEMENTS( roi_files )

    ; Cause an error if the number of GPR files does not match the number of ROI files:

    IF ( num_gpr_files NE num_roi_files ) THEN BEGIN
       MESSAGE, "ERROR!: The number of specified GPR data files does not match the number of ROI files (*.roi)."
    ENDIF

    ; Determine the total number of ROI measurements so that an array can be
    ; declared of this size for holding all of the necessary depth measurements:

    num_depth_measurements = 0

    FOR i = 0, num_roi_files - 1 DO BEGIN

        ; Restore the desired ROI file into ENVI's memory; this is necessary in order to use
        ; ENVI_GET_ROI_IDS below:

        ENVI_RESTORE_ROIS, roi_files[ i ]

        ; Get the file ID associated with this GPR file:

        ENVI_OPEN_FILE, gpr_files[ i ], r_fid = gpr_file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

        ; Get the ROI ID associated with this GPR file ID:

        roi_id = ENVI_GET_ROI_IDS( fid = gpr_file_id )

        ; Get the pixel addresses associated with this ROI. ROI addresses are one-dimensional
        ; spatial addresses that need to be converted to (x,y) locations below:

        roi_pixel_addresses = ENVI_GET_ROI( roi_id )

        num_depth_measurements += N_ELEMENTS( roi_pixel_addresses )

        ; Delete the ROI from ENVI memory now that we are done with it:

        ENVI_DELETE_ROIS, roi_id

    ENDFOR

    ; Declare an array to hold all of the depth measurements:

    depths = FLTARR( num_depth_measurements )

    ; Set up a status window to show what percentage of the ROI files have been processed so far:

    IF ( num_gpr_files GT 1 ) THEN BEGIN
        ENVI_REPORT_INIT, [ 'Reading ' + STRTRIM( num_roi_files, 2 ) + ' ROI files...' ], base = status_base, $
        /interrupt, title = 'Reading ROI files...'
    ENDIF

    ; Read each ROI file individually:

    depth_index = 0

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

            ; Compute the depth for this pixel (note: assumes zero-based y-coordinate, so subtracts 1 from current
            ; sample):

            depth = GET_GPR_DEPTH( current_sample = y_image_coordinate - 1, num_samples = num_samples, $
                time_window = time_window, ground_velocity = ground_velocity, first_arrival = first_arrival, $
                direct_wave_adjustment = direct_wave_adjustment, adjustment_velocity = adjustment_velocity, $
                antenna_separation = antenna_separation )

            ; Store the depth into the depths array and update the depths index counter:

            depths[ depth_index ] = depth
            depth_index++

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
                RETURN, ''
            ENDIF
        ENDIF

    ENDFOR

    ; Close the status window:

    IF ( num_gpr_files GT 1 ) THEN BEGIN
        ENVI_REPORT_INIT, base = status_base, /finish
    ENDIF

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;
    ;;  Step 4:
    ;;
    ;;  Compute and report results.
    ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mean_depth_meters = MEAN( depths )
    stddev_depth_meters = STDDEV( depths )
    min_depth_meters = MIN( depths )
    max_depth_meters = MAX( depths )

    ; If the user supplied a density for computing SWE, compute SWE here:

    IF ( N_ELEMENTS( density ) NE 0 ) THEN BEGIN
        mean_swe_gcm2 = ( mean_depth_meters * 100 ) * density
        stddev_swe_gcm2 = ( stddev_depth_meters * 100 ) * density
        min_swe_gcm2 = ( min_depth_meters * 100 ) * density
        max_swe_gcm2 = ( max_depth_meters * 100 ) * density
    ENDIF ELSE BEGIN
        mean_swe_gcm2 = !VALUES.F_NAN
        stddev_swe_gcm2 = !VALUES.F_NAN
        min_swe_gcm2 = !VALUES.F_NAN
        max_swe_gcm2 = !VALUES.F_NAN
    ENDELSE

    ; Return the computed statistics in a structure variable:

    statistics = CREATE_STRUCT( 'total_measurements', depth_index, 'mean_depth_meters', mean_depth_meters, $
        'stddev_depth_meters', stddev_depth_meters, 'min_depth_meters', min_depth_meters, 'max_depth_meters', $
        max_depth_meters, 'mean_swe_gcm2', mean_swe_gcm2, 'stddev_swe_gcm2', stddev_swe_gcm2, 'min_swe_gcm2', $
        min_swe_gcm2, 'max_swe_gcm2', max_swe_gcm2 )

    RETURN, statistics

END