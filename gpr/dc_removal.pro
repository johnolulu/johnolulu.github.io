;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  dc_removal
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to simulate the "DC removal" image-
;;  processing filter available within Mala Geoscience "GroundVision" software that
;;  is used to acquire and process RAMAC ground-penetrating radar (GPR) data. "DC"
;;  stands for an electrical "direct current." As described in Appendix 1 of the
;;  GroundVision Manual:
;;
;;  "There is often a constant offset in the amplitude of the registered trace.
;;   This is known as the DC level or the DC offset. This filter removes the DC
;;   component from the data. The DC component is individually calculated and
;;   removed for each trace [...]. The sample interval on which the DC component
;;   is calculated is specified [by the user]. The end sample is always the last
;;   sample in each trace and the start sample is set [by the user]."
;;
;;  A "trace" is a single, vertical column of GPR data, representing the signal "traced"
;;  by a radar pulse as it travels from the instrument into the subsurface. Each
;;  trace is composed of individual "samples," the smallest measurement unit in the
;;  vertical dimension.
;;
;;  In following with the description above, this IDL procedure filters a GPR image (that
;;  has already been formatted to view properly in ENVI) using the following methodology:
;;
;;  1. Ask the user for the start sample for calculation of each trace's DC level. This
;;     start sample should be set below any outstanding features within the trace to cover
;;     an area where DC noise is the prominent feature. This information can be provided
;;     to the program in one of two ways:
;;
;;      a.) through the use of a graphical user interface (GUI) that pops up when calling
;;          the program from within an ENVI image pull-down menu, or
;;
;;      b.) automatically through the use of command-line options at the IDL prompt or
;;          from within another IDL program (to facilitate the application of this filter
;;          programmatically across multiple files).
;;
;;  The IDL procedure then applies the following DC removal method to the data on a
;;  trace-by-trace basis:
;;
;;  2. Calculate the standard deviation of the data between the user-selected start
;;     sample and the last sample of the trace in order to compute the offset to
;;     be removed from the trace's data.
;;
;;  3. Calculate the mean data value of the entire trace.
;;
;;  4. For every sample in the trace, SUBTRACT the standard deviation from the
;;     sample's data value if it is GREATER THAN the mean plus the standard deviation.
;;     ADD the standard deviation to the sample's data value if it is LESS THAN the
;;     mean minus the standard deviation. Otherwise, set the sample's data value EQUAL
;;     TO the mean.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's function menu configuration file (display.men) located in
;;  ENVI's "menu" directory:
;;
;;      0 {GPR}
;;        1 {Filter}
;;          2 {DC Removal} {not used} {dc_removal}
;;
;;  This procedure can then be run from the pull-down menu labelled "GPR" on a GPR
;;  file that you have already opened in ENVI. The result can either be saved to memory or
;;  to a new file.
;;  -------------------------------------------------------------------------------------
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  dc_removal, input_location = input_location, start_sample = start_sample, $
;;      output_location = output_location
;;
;;  Keywords:
;;
;;  input_location = full pathname and filename of file to filter, surrounded by quotes ("").
;;
;;  start_sample = sample number (vertical dimension, or y-axis) to begin calculation of DC
;;      component from. Must be an integer between 1 (the first sample at the top of the file)
;;      and the total number of samples in the file.
;;
;;  output_location = full pathname and filename of file to output the filtered result to,
;;      surrounded by quotes ("").
;;
;;  Examples:
;;
;;  dc_removal, input_location = "C:\data\ramac_gpr.bin", start_sample = 150, $
;;      output_location = "C:\data\ramac_gpr_filtered.bin"
;;  dc_removal, input_location = "/home/maurer/data/ramac_gpr.bin", start_sample = 23, $
;;   output_location = "/home/maurer/data/ramac_gpr_filtered.bin"
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

PRO dc_removal, event, input_location = input_location, start_sample = start_sample, $
    output_location = output_location

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                ;;
    ;;  Step 1:                                       ;;
    ;;                                                ;;
    ;;  Ask user for start sample for calculation of  ;;
    ;;  each trace's DC level.                        ;;
    ;;                                                ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Determine filter characteristics from the input parameters, if provided:

    IF ( KEYWORD_SET( input_location ) ) THEN BEGIN

        ; Make sure all of the necessary parameters have been provided:

        IF ( NOT KEYWORD_SET( start_sample ) OR $
            NOT KEYWORD_SET( output_location ) ) THEN BEGIN

            ; The MESSAGE procedure issues error and informational messages using the same mechanism
            ; employed by built-in IDL routines. By default, the message is issued as an error, the
            ; message is output, and execution is haulted. See IDL's help page for information on
            ; controlling errors using CATCH or ON_ERROR:

            MESSAGE, "ERROR!: wrong number of parameters provided."

        ENDIF

        ; Open the specified input file, suppressing the ENVI Header Information dialog when a valid
        ; ENVI header file does not exist (/NO_INTERACTIVE_QUERY) and suppressing the opening of the
        ; Available Bands List window (/NO_REALIZE):

        ENVI_OPEN_FILE, input_location, r_fid=file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

        ; If the file could not be opened, then exit:

        IF ( file_id EQ -1 ) THEN BEGIN
            error_message = "ERROR!: unable to open file """ + input_location + """
            MESSAGE, error_message
        ENDIF

       ; Determine the number of samples (vertical dimension, or y-axis) associated with this file ID:

        ENVI_FILE_QUERY, file_id, nl = num_samples

        ; Make sure the input parameter is within the proper range:

        IF ( start_sample LT 1 OR start_sample GT num_samples ) THEN BEGIN
            error_message = "ERROR!: start_sample must be >= 1 and <= total number of samples (" + $
                STRCOMPRESS( STRING( num_samples ), /REMOVE_ALL ) + ")."
            MESSAGE, error_message
        ENDIF

        ; Set the input parameter to an integer variable in case it isn't already:

        start_sample = FIX( start_sample )

        ; Result will be stored to a file (output_location), not to memory:

        in_memory = 0

    ; Otherwise, the procedure is being called as a widget function within ENVI. Display a widget
    ; to collect collect filter characteristics from the user:

    ENDIF ELSE BEGIN

        ; Get the display number of the image window that was used to call this IDL procedure:

        WIDGET_CONTROL, event.top, get_uvalue = display_num

       ; Determine the file ID associated with this file and the number of samples (vertical
        ; dimension, or y-axis):

       ENVI_DISP_QUERY, display_num, fid = file_id, nl = num_samples

        ; Create an IDL "widget" to allow user to input the necessary filter parameters:

        result = COLLECT_INPUT_DC_REMOVAL( num_samples = num_samples, /SPECIFY_OUTPUT )

        ; If the user pressed "Cancel" then exit:

        IF ( result.accept EQ 0 ) THEN return

        in_memory = result.output_location.in_memory
        output_location = result.output_location.name

        ; Set the result structure field to an integer variable:

        start_sample = FIX( result.start_sample )

    ENDELSE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                     ;;
    ;;  Determine data characteristics...  ;;
    ;;                                     ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Collect information about this GPR data, including its number of samples (vertical
    ; dimension, or y-axis), and the number of traces (horizontal dimension, or x-axis).
    ; [NOTE: In ENVI-terminology, "samples" are counted in the horizontal dimension ("ns")
    ; and "lines" are counted in the vertical dimension ("nl"), but we use GPR-terminology
    ; here instead to avoid confusion.] Also, determine the coordinates of the upper left-hand
    ; pixel (xstart and ystart) so that the new filtered data file gets created using the same
    ; starting pixel:

    ENVI_FILE_QUERY, file_id, bnames = band_name, xstart = xstart, ystart = ystart, data_type = data_type, $
               descrip = description, interleave = interleave, nl = num_samples, ns = num_traces, nb = num_bands, $
               offset = offset, fname = file_name

    ; Store the dimensions of the data file into an array. This will be used later by MAGIC_MEM_CHECK.
    ; Although recent versions of ENVI (>= 4.1) allow this to be set using ENVI_FILE_QUERY above,
    ; testing on ENVI 4.0 revealed that the dims keyword was not yet available in this function. To
    ; make this code accessible to earlier versions of ENVI, therefore, the dimensions array is
    ; defined explicitly here. The array is stored as so:
    ;   DIMS[0] = a pointer to an open Region of Interest, used only in cases where ROIs define the spatial subset,
    ;             otherwise set to -1;
    ;   DIMS[1] = the starting sample number (an IDL zero-based array subscript);
    ;   DIMS[2] = the ending sample number;
    ;   DIMS[3] = the starting line number;
    ;   DIMS[4] = the ending line number:

    dimensions = [ -1, xstart, xstart + num_traces, ystart, ystart + num_samples ]

    ; If the user chose to output to memory instead of a file, make sure the cache
    ; limit will not be exceeded. After the call to "MAGIC_MEM_CHECK", the code
    ; should use "memory_check.in_memory" and "memory_check.out_name" instead of
    ; "result.output_location.in_memory" and "result.output_location.name":

    memory_check = MAGIC_MEM_CHECK( dims = dimensions, fid = file_id, in_memory = in_memory, $
                                   out_dt = data_type, nb = num_bands, out_name = output_location)

    ; If the cache limit was exceeded and the user pressed "Cancel" then exit:

    IF ( memory_check.cancel EQ 1 ) THEN RETURN

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                               ;;
    ;;  Steps 2-4:                                   ;;
    ;;                                               ;;
    ;;  Apply DC removal on a trace-by-trace basis.  ;;
    ;;                                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Display a status window to show what percentage of processing is currently
    ; complete...

    ; ...First define the text strings that will be displayed in the status reporting
    ; dialog:

    status_string1 = "Input File: " + file_name

    IF ( memory_check.in_memory EQ 1 ) THEN BEGIN
       status_string2 = "Output to Memory"
    ENDIF ELSE BEGIN
       status_string2 = "Output File: " + memory_check.out_name
    ENDELSE

    status_strings = [ status_string1, status_string2 ]

    ; ...Now initiate the status window. The "/interrupt" option gives the user
    ; the option to cancel processing at any time:

    ENVI_REPORT_INIT, status_strings, base = status_base, /interrupt, $
                title = 'DC Removal'

    ; Initialize two integer arrays: one to hold the original data and one to
    ; hold the new filtered data. Both arrays will need to have as many traces
    ; (x dimension) and samples (y dimension) as the original data file:

    original_data = INTARR( num_traces, num_samples )
    filtered_data = INTARR( num_traces, num_samples )

    ; Because arrays are zero-based in IDL, the last trace or sample
    ; will be the total number of traces or samples in the data file
    ; minus one sample:

    last_trace = num_traces - 1
    last_sample = num_samples - 1

    ; Store all of the original data into an array:

    original_data = ENVI_GET_DATA( fid = file_id, dims = [ -1, 0, last_trace, 0, last_sample ], pos = 0 )

    ; Loop through each trace of the data file:

    FOR trace = 0, last_trace DO BEGIN

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;                                                 ;;
        ;;  Step 2:                                        ;;
        ;;                                                 ;;
        ;;  Calculate standard deviation of data between   ;;
        ;;  user-selected start sample and last sample of  ;;
        ;;  trace; this is the offset to be removed from   ;;
        ;;  the trace in Step 4.                           ;;
        ;;                                                 ;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        trace_stddev = ROUND( STDDEV( original_data[ trace, start_sample:last_sample ] ) )

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;                                       ;;
        ;;  Step 3:                              ;;
        ;;                                       ;;
        ;;  Calculate mean data value of trace.  ;;
        ;;                                       ;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        trace_mean = ROUND( MEAN( original_data[ trace, 0:last_sample ] ) )

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;                                                                        ;;
        ;;  Step 4:                                                               ;;
        ;;                                                                        ;;
        ;;  Remove the offset calculated in Step 2 as so:                         ;;
        ;;                                                                        ;;
        ;;  For every sample in the trace, SUBTRACT the standard deviation        ;;
        ;;  from the data value if it is GREATER THAN the mean plus the           ;;
        ;;  standard deviation; ADD the standard deviation to the sample's        ;;
        ;;  data value if it is LESS THAN the mean minus the standard deviation.  ;;
        ;;  Otherwise, set the sample's data value EQUAL TO the mean.             ;;
        ;;                                                                        ;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        FOR sample = 0, last_sample DO BEGIN
            data_value = original_data[ trace, sample ]
            IF ( data_value GT ( trace_mean + trace_stddev ) ) THEN BEGIN
                data_value -= trace_stddev
            ENDIF ELSE $
            IF ( data_value LT ( trace_mean - trace_stddev ) ) THEN BEGIN
                data_value += trace_stddev
            ENDIF ELSE BEGIN
                data_value = trace_mean
            ENDELSE
            filtered_data[ trace, sample ] = data_value
        ENDFOR

       ; Update the status window with the current percentage of completion:

       ENVI_REPORT_STAT, status_base, trace, last_trace, cancel = cancel

       ; If the user chooses to cancel processing from the status window, delete
       ; the status window and exit the program:

       IF ( cancel EQ 1 ) THEN BEGIN
         ENVI_REPORT_INIT, base = status_base, /finish
         RETURN
       ENDIF

    ENDFOR

    ;;;;;;;;;;;;;;;;;;;;;;
    ;;                  ;;
    ;;  End filtering.  ;;
    ;;                  ;;
    ;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;
    ;;                ;;
    ;;  Save results  ;;
    ;;                ;;
    ;;;;;;;;;;;;;;;;;;;;

    ; Determine a band name for the output:

    filtered_band_name = "DC Removal (" + band_name[0] + ")"

    ; Create a description that will get written to the output's ENVI header file
    ; based on the original file's description plus information about the filtering done:

    filtered_description = description + " Filtered with DC Removal (""dc_removal.pro""): " + $
                           "start sample = " + STRING( start_sample ) + "."

    ; Write the filtered data to a file or memory, depending on what
    ; the user selected. The new data will appear in the ENVI "Available
    ; Bands List" window and is thereby available for display or use by
    ; other ENVI functions:

    IF ( memory_check.in_memory EQ 1 ) THEN BEGIN

        ENVI_ENTER_DATA, filtered_data, bnames = filtered_band_name, descrip = filtered_description, $
                   xstart = xstart, ystart = ystart

    ENDIF ELSE BEGIN

        OPENW, lun, memory_check.out_name, /GET_LUN
        WRITEU, lun, filtered_data
        FREE_LUN, lun

        ; If this procedure is being run from another program (such as bulk_gpr_filter.pro) or at the
        ; command line, do not specify the "/open" keyword to "ENVI_SETUP_HEAD", which opens the file
        ; in ENVI and makes it available from the "Available Bands List" window:

        IF ( KEYWORD_SET( input_location ) ) THEN BEGIN
            ENVI_SETUP_HEAD, bnames = filtered_band_name, data_type = data_type, fname = memory_check.out_name, $
                interleave = interleave, ns = num_traces, nl = num_samples, nb = num_bands, offset = offset, $
                xstart = xstart, ystart = ystart, descrip = filtered_description, /write
        ENDIF ELSE BEGIN
            ENVI_SETUP_HEAD, bnames = filtered_band_name, data_type = data_type, fname = memory_check.out_name, $
                interleave = interleave, ns = num_traces, nl = num_samples, nb = num_bands, offset = offset, $
                xstart = xstart, ystart = ystart, descrip = filtered_description, /open, /write
        ENDELSE

    ENDELSE

    ; If this procedure is being run from another program (such as bulk_gpr_filter.pro) or at the
    ; command line, close the input file in ENVI now that we are done (otherwise, it remains in the
    ; ENVI "Available Bands List" window):

    IF ( KEYWORD_SET( input_location ) ) THEN BEGIN
        ENVI_FILE_MNG, id = file_id, /remove
    ENDIF

    ; Close the status window:

    ENVI_REPORT_INIT, base = status_base, /finish

END