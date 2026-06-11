;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  subtract_mean_trace
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to simulate the "subtract mean trace" image-
;;  processing filter available within Mala Geoscience "GroundVision" software that
;;  is used to acquire and process RAMAC ground-penetrating radar (GPR) data. As
;;  described in Appendix 1 of the GroundVision Manual:
;;
;;  "This filter is used to remove horizontal and nearly horizontal features in the
;;   radargram by subtracting a calculated mean trace from all traces. The running
;;   average version subtracts a mean trace calculated in a window centered at the
;;   trace to be filtered. The size of the window is selected by the 'Number of traces
;;   to use in filter process' edit box. The Total average method calculates the mean
;;   trace as the mean of the whole data file."
;;
;;  A "trace" is a single, vertical column of GPR data, representing the signal "traced"
;;  by a radar pulse as it travels from the instrument into the subsurface. Each
;;  trace is composed of individual "samples," the smallest measurement unit in the
;;  vertical dimension.
;;
;;  In following with the description above, this IDL procedure filters a GPR image (that
;;  has already been formatted to view properly in ENVI) using the following methodology:
;;
;;  1. Ask the user for a subtraction method (either running average or total average)
;;     and for a window length (in traces) to apply to the filter if running average
;;     is the selected subtraction method. This information can be provided to the program
;;     in one of two ways:
;;
;;      a.) through the use of a graphical user interface (GUI) that pops up when calling
;;          the program from within an ENVI image pull-down menu, or
;;
;;      b.) automatically through the use of command-line options at the IDL prompt or
;;          from within another IDL program (to facilitate the application of this filter
;;          programmatically across multiple files).
;;
;;  The IDL procedure then applies the following mean-subtraction filter to the data
;;  on a row-by-row basis (note: rows are oriented horizontally in the data, as opposed
;;  to traces, which are oriented vertically):
;;
;;  2. Calculate the mean data value (in DN) for the row, either for the entire
;;     row (total average method) or for a window centered around the current
;;     trace (running average method).
;;
;;  3. Subtract this mean data value from each pixel in the row. Note that pixels
;;     that used to have the mean data value will now have a data value of 0. This
;;     also means that pixels that used to have data values less than the mean will now
;;     be negative. Negative data values are acceptable in these data, however.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's function menu configuration file (display.men) located in
;;  ENVI's "menu" directory:
;;
;;      0 {GPR}
;;        1 {Filter}
;;          2 {Subtract Mean Trace} {not used} {subtract_mean_trace}
;;
;;  This procedure can then be run from the pull-down menu labelled "GPR" on a GPR
;;  file that you have already opened in ENVI. The result can either be saved to memory or
;;  to a new file.
;;  -------------------------------------------------------------------------------------
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  subtract_mean_trace, input_location = input_location, [window_length = window_length,] $
;;      output_location = output_location
;;
;;  Keywords:
;;
;;  input_location = full pathname and filename of the file to filter, surrounded by quotes ("").
;;
;;  window_length (optional) = length in traces (horizonatal dimension, or x-axis) to use in
;;      the running average subtraction method. Must be an integer between 2 and the total
;;      number of traces in the file. If this keyword is not supplied, the program will assume
;;      a total average subtraction method.
;;
;;  output_location = full pathname and filename of a file to output the filtered result to,
;;      surrounded by quotes ("").
;;
;;  Examples:
;;
;;  subtract_mean_trace, input_location = "C:\data\ramac_gpr.bin", window_length = 60, $
;;      output_location = "C:\data\ramac_gpr_filtered.bin"
;;  subtract_mean_trace, input_location = "/home/maurer/data/ramac_gpr.bin", $
;;      output_location = "/home/maurer/data/ramac_gpr_filtered.bin"
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

PRO subtract_mean_trace, event, input_location = input_location, window_length = window_length, $
    output_location = output_location

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                      ;;
    ;;  Step 1:                                             ;;
    ;;                                                      ;;
    ;;  Ask user for subtraction method and window length.  ;;
    ;;                                                      ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Determine filter characteristics from the input parameters, if provided:

    IF ( KEYWORD_SET( input_location ) ) THEN BEGIN

        ; Make sure an output location has been provided:

        IF ( NOT KEYWORD_SET( output_location ) ) THEN BEGIN

            ; The MESSAGE procedure issues error and informational messages using the same mechanism
            ; employed by built-in IDL routines. By default, the message is issued as an error, the
            ; message is output, and execution is haulted. See IDL's help page for information on
            ; controlling errors using CATCH or ON_ERROR:

            MESSAGE, "ERROR!: wrong number of parameters provided."

        ENDIF

       ; Determine the subtraction method based on whether or not a window
       ; length was provided as an input parameter or not:

       IF ( KEYWORD_SET( window_length ) ) THEN BEGIN
            subtraction_method = 'running average'
       ENDIF ELSE BEGIN
            subtraction_method = 'total average'
       ENDELSE

        ; Open the specified input file, suppressing the ENVI Header Information dialog when a valid
        ; ENVI header file does not exist (/NO_INTERACTIVE_QUERY) and suppressing the opening of the
        ; Available Bands List window (/NO_REALIZE):

        ENVI_OPEN_FILE, input_location, r_fid = file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

        ; If the file could not be opened, then exit:

        IF ( file_id EQ -1 ) THEN BEGIN
            error_message = "ERROR!: unable to open file """ + input_location + """
            MESSAGE, error_message
        ENDIF

        ; Determine the number of traces (horizontal dimension, or x-axis) associated with this file ID:

        ENVI_FILE_QUERY, file_id, ns = num_traces

        ; If provided, make sure the window_length is within the proper range:

        IF ( KEYWORD_SET( window_length ) ) THEN BEGIN

            IF ( window_length LT 2 OR window_length GT num_traces ) THEN BEGIN
                error_message = "ERROR!: window_length must be >= 2 and <= total number of traces (" + $
                    STRCOMPRESS( STRING( num_traces ), /REMOVE_ALL ) + ")."
                MESSAGE, error_message
            ENDIF

            ; Set the input parameter to an integer variable in case it isn't already:

            window_length = FIX( window_length )

        ENDIF

        ; Result will be stored to a file (output_location), not to memory:

        in_memory = 0

    ; Otherwise, the procedure is being called as a widget function within ENVI. Display a widget
    ; to collect collect filter characteristics from the user:

    ENDIF ELSE BEGIN

        ; Get the display number of the image window that was used to call this IDL procedure:

        WIDGET_CONTROL, event.top, get_uvalue = display_num

        ; Determine the file ID associated with this file and the number of traces (horizontal
        ; dimension, or x-axis):

        ENVI_DISP_QUERY, display_num, fid = file_id, ns = num_traces

        ; Create an IDL "widget" to allow user to input the necessary filter parameters:

        result = COLLECT_INPUT_SUBTRACT_MEAN_TRACE( num_traces = num_traces, /SPECIFY_OUTPUT )

        ; If the user pressed "Cancel" then exit:

        IF( result.accept EQ 0 ) THEN RETURN

        in_memory = result.output_location.in_memory
        output_location = result.output_location.name

        ; Set the resulting subtraction method to a variable:

        subtraction_method = result.subtraction_method

        CASE subtraction_method OF
            0: subtraction_method = 'running average'
            1: subtraction_method = 'total average'
        ENDCASE

        ; Set the resulting window length to an integer variable:

        window_length = FIX( result.window_length )

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
                                   out_dt = data_type, nb = num_bands, out_name = output_location )

    ; If the cache limit was exceeded and the user pressed "Cancel" then exit:

    IF ( memory_check.cancel EQ 1 ) THEN RETURN

    ; If the subtraction method is "total average", set the window length to
    ; the total number of traces:

    IF ( subtraction_method EQ 'total average' ) THEN BEGIN
       window_length = num_traces
    ENDIF

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                      ;;
    ;;  Steps 2-3:                          ;;
    ;;                                      ;;
    ;;  Apply mean-subtraction filter on a  ;;
    ;;  row-by-row basis.                   ;;
    ;;                                      ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
                title = 'Subtract Mean Trace'

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

    ; Loop through each row of the data file:

    FOR sample = 0, last_sample DO BEGIN

        FOR trace = 0, last_trace DO BEGIN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;;                                                         ;;
            ;;  Step 2:                                                ;;
            ;;                                                         ;;
            ;;  Calculate mean data value for the row, either for      ;;
            ;;  the entire row (total average method) or for a window  ;;
            ;;  centered around the current sample (running average    ;;
            ;;  method).                                               ;;
            ;;                                                         ;;
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            IF ( subtraction_method EQ 'total average' ) THEN BEGIN
                row_mean = ROUND( MEAN( original_data[ 0:last_trace, sample ] ) )
            ENDIF ELSE BEGIN

                ; For the 'running average' method, compute the first and last trace
                ; of the window that will be used to compute the mean:

                mean_first_trace = trace - window_length
                mean_last_trace = trace + window_length

                ; If the first and last traces of the window are outside the bounds
                ; of the data, constrain them:

                IF ( mean_first_trace LT 0 ) THEN mean_first_trace = 0
                IF ( mean_last_trace GT last_trace ) THEN mean_last_trace = last_trace

                ; Compute the mean for this window length:

                row_mean = ROUND( MEAN( original_data[ mean_first_trace:mean_last_trace, sample ] ) )

            ENDELSE

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;;                                                 ;;
            ;;  Step 3:                                        ;;
            ;;                                                 ;;
            ;;  Subtract mean data value calculated in Step 2  ;;
            ;;  from each pixel in the row.                    ;;
            ;;                                                 ;;
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            filtered_data[ trace, sample ] = original_data[ trace, sample ] - row_mean

        ENDFOR

       ; Update the status window with the current percentage of completion:

       ENVI_REPORT_STAT, status_base, sample, last_sample, cancel = cancel

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

    filtered_band_name = "Mean Trace Subtracted (" + band_name[0] + ")"

    ; Create a description that will get written to the output's ENVI header file
    ; based on the original file's description plus information about the filtering done:

    filtered_description = description + " Filtered with Subtract Mean Trace (""subtract_mean_trace.pro""): " + $
                           "method = " + subtraction_method
    IF ( subtraction_method EQ 'running average' ) THEN BEGIN
        filtered_description += "; window length = " + STRING( window_length ) + "."
    ENDIF ELSE BEGIN
        filtered_description += "."
    ENDELSE

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