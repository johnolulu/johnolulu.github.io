;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  time_varying_gain
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to simulate the "time-varying gain" image
;;  processing filter available within Mala Geoscience "GroundVision" software that
;;  is used to acquire and process RAMAC ground-penetrating radar (GPR) data. As
;;  described in Appendix 1 of the GroundVision Manual:
;;
;;  "The Time-Gain filter applies a time-varying gain to compensate for amplitude
;;   loss due to spreading and attenuation. The trace is multiplied by a gain
;;   function combining linear and an exponential gain, with coefficients set by
;;   the user."
;;
;;  A "trace" is a single, vertical column of GPR data, representing the signal "traced"
;;  by a radar pulse as it travels from the instrument into the subsurface. Each
;;  trace is composed of individual "samples," the smallest measurement unit in the
;;  vertical dimension. Because of geometrical "spreading," the radar signal decreases
;;  in strength with depth as 1/(r^2), where r is depth.
;;
;;  In following with the description above, this IDL procedure filters a GPR image (that
;;  has already been formatted to view properly in ENVI) using the following methodology:
;;
;;  1. Collect the necessary user input:
;;
;;      a.) Ask the user for the "time window" of the GPR data being filtered. The time window
;;          is the amount of time that the GPR instrument was set to "listen" for radar pulses
;;          per trace at the time of data acquisition. This value is used to compute the gain
;;          function in step 2 below and can be found in the "*.rad" file associated with a
;;          particular RAMAC GPR data file ("*.rd3"), labelled "TIMEWINDOW" and reported in
;;          nanoseconds (10^-9 seconds).
;;
;;      b.) Ask the user for the start sample at which to begin applying the time-varying
;;          gain, providing a reasonable default as GroundVision does. The user may prefer to set
;;          the start sample below any outstanding features within the trace. The time-varying gain
;;          will be applied to all samples between the selected start sample and the last sample of
;;          each trace.
;;
;;      c.) Ask the user for linear (A) and exponential (B) gain factors to be applied in the
;;          equation outlined in step 2 below. Typical values range anywhere between 0 and ~1000
;;          for linear gain and 0 and ~150 for exponential gain. Increasing the exponential
;;          gain has the effect of dramatically amplifying the gain of the lower portion of
;;          the trace, which may be important if there are features you are looking for in the
;;          deeper portion of the GPR data.
;;
;;     This information can be provided to the program in one of two ways:
;;
;;      a.) through the use of a graphical user interface (GUI) that pops up when calling
;;          the program from within an ENVI image pull-down menu, or
;;
;;      b.) automatically through the use of command-line options at the IDL prompt or
;;          from within another IDL program (to facilitate the application of this filter
;;          programmatically across multiple files).
;;
;;  The IDL procedure then applies the following time-varying gain function to the data
;;  on a trace-by-trace basis:
;;
;;  2. Multiply each sample in the trace from the selected start sample to the last
;;     sample in the trace by a gain factor computed according to the following
;;     equation (note: this is the same equation used in the "GroundVision" software):
;;
;;          (A*time) + e^(B*time)
;;
;;     where "A" is the linear gain factor and "B" is the exponential gain factor selected
;;     by the user in step 3 above. Time, here, is expressed in microseconds (10^-6 seconds)
;;     and is computed from the time window input by the user in step 1 above (in nanoseconds,
;;     or 10^-9 seconds) according to the following equation:
;;
;;        time = ((time window)/(total samples per trace)) * (number of samples filtered so far)
;;
;;     where "time window" is first divided by 1000 to convert it from nanoseconds
;;     (10^-9 seconds) to microseconds (10^-6 seconds).
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's function menu configuration file (display.men) located in
;;  ENVI's "menu" directory:
;;
;;      0 {GPR}
;;        1 {Filter}
;;          2 {Time Varying Gain} {not used} {time_varying_gain}
;;
;;  This procedure can then be run from the pull-down menu labelled "GPR" on a GPR
;;  file that you have already opened in ENVI. The result can either be saved to memory or
;;  to a new file.
;;  -------------------------------------------------------------------------------------
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  time_varying_gain, input_location = input_location, time_window = time_window, $
;;      start_sample = start_sample, linear_gain = linear_gain, exponential_gain = exponential_gain, $
;;      output_location = output_location
;;
;;  Keywords:
;;
;;  input_location = full pathname and filename of file to filter, surrounded by quotes ("").
;;
;;  time_window = the amount of time in nanoseconds (10^-9 seconds) that the GPR instrument
;;      was set to "listen" for radar pulses per trace at the time of data acquisition.
;;
;;  start_sample = sample number (vertical dimension, or y-axis) to begin applying the filter
;;      at. Must be an integer between 1 (the first sample at the top of the file) and the total
;;      number of samples in the file.
;;
;;  linear_gain = scale factor to apply in linear gain component. Must be between 0 and 1000.
;;
;;  exponential_gain = scale factor to apply in exponential gain component. Must be between 0
;;      and 1000.
;;
;;  output_location = full pathname and filename of file to output the filtered result to,
;;      surrounded by quotes ("").
;;
;;  Examples:
;;
;;  time_varying_gain, input_location = "C:\data\ramac_gpr.bin", time_window = 42.522624, $
;;      start_sample = 1, linear_gain = 135, exponential_gain = 80, $
;;      output_location = "C:\data\ramac_gpr_filtered.bin"
;;  time_varying_gain, input_location = "/home/maurer/data/ramac_gpr.bin", time_window = 5247.0, $
;;   start_sample = 17, linear_gain = 0, exponential_gain = 4, $
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

PRO time_varying_gain, event, input_location = input_location, time_window = time_window, $
    start_sample = start_sample, linear_gain = linear_gain, exponential_gain = exponential_gain, $
    output_location = output_location

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                      ;;
    ;;  Step 1:                             ;;
    ;;                                      ;;
    ;;  Get required inputs from the user.  ;;
    ;;                                      ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Determine filter characteristics from the input parameters, if provided:

    IF ( KEYWORD_SET( input_location ) ) THEN BEGIN

        ; Make sure all of the necessary parameters have been provided:

        IF ( NOT KEYWORD_SET( time_window ) OR $
            NOT KEYWORD_SET( start_sample ) OR $
            NOT KEYWORD_SET( output_location ) ) THEN BEGIN

            ; The MESSAGE procedure issues error and informational messages using the same mechanism
            ; employed by built-in IDL routines. By default, the message is issued as an error, the
            ; message is output, and execution is haulted. See IDL's help page for information on
            ; controlling errors using CATCH or ON_ERROR:

            MESSAGE, "ERROR!: wrong number of parameters provided."

        ENDIF

        ; If linear_gain or exponential_gain not provided, set them to zero:

        IF ( NOT KEYWORD_SET( linear_gain ) ) THEN BEGIN
            linear_gain = 0
        ENDIF

        IF ( NOT KEYWORD_SET( exponential_gain ) ) THEN BEGIN
            exponential_gain = 0
        ENDIF

        ; Open the specified input file, suppressing the ENVI Header Information dialog when a valid
        ; ENVI header file does not exist (/NO_INTERACTIVE_QUERY) and suppressing the opening of the
        ; Available Bands List window (/NO_REALIZE):

        ENVI_OPEN_FILE, input_location, r_fid = file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

        ; If the file could not be opened, then exit:

        IF ( file_id EQ -1 ) THEN BEGIN
            error_message = "ERROR!: unable to open file """ + input_location + """
            MESSAGE, error_message
        ENDIF

        ; Determine the number of samples (vertical dimension, or y-axis) associated with this file ID:

        ENVI_FILE_QUERY, file_id, nl = num_samples

        ; Make sure all of the input parameters are within the proper range:

        IF ( time_window LE 0.0 ) THEN BEGIN
            MESSAGE, "ERROR!: time_window must be > 0."
        ENDIF

        IF ( start_sample LT 1 OR start_sample GT num_samples ) THEN BEGIN
            error_message = "ERROR!: start_sample must be >= 1 and <= total number of samples (" + $
                STRCOMPRESS( STRING( num_samples ), /REMOVE_ALL ) + ")."
            MESSAGE, error_message
        ENDIF

        IF ( linear_gain LT 0 OR linear_gain GT 1000 ) THEN BEGIN
            MESSAGE, "ERROR!: linear_gain must be >= 0 and <= 1000."
        ENDIF

        IF ( exponential_gain LT 0 OR exponential_gain GT 1000 ) THEN BEGIN
            MESSAGE, "ERROR!: exponential_gain must be >= 0 and <= 1000."
        ENDIF

        ; Set various input parameters to integer variables in case they aren't already:

        start_sample = FIX( start_sample )
        linear_gain = FIX( linear_gain )
        exponential_gain = FIX( exponential_gain )

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

        result = COLLECT_INPUT_TIME_VARYING_GAIN( num_samples = num_samples, /SPECIFY_OUTPUT )

        ; If the user pressed "Cancel" then exit:

        IF ( result.accept EQ 0 ) THEN RETURN

        in_memory = result.output_location.in_memory
        output_location = result.output_location.name

        ; Set the following result structure field to its own variable:

        time_window = result.time_window

        ; Set the following result structure fields to integer variables:

        start_sample = FIX( result.start_sample )
        linear_gain = FIX( result.linear_gain )
        exponential_gain = FIX( result.exponential_gain )

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

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                       ;;
    ;;  Step 2:                              ;;
    ;;                                       ;;
    ;;  Apply time-varying gain filter on a  ;;
    ;;  trace-by-trace basis.                ;;
    ;;                                       ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
                title = 'Time-Varying Gain'

    ; Initialize two integer arrays: one to hold the original data and one to
    ; hold the new filtered data. Both arrays will need to have as many traces
    ; (x dimension) and samples (y dimension) as the original data file:

    original_data = INTARR( num_traces, num_samples )
    filtered_data = INTARR( num_traces, num_samples )

    ; Because arrays are zero-based in IDL, the last trace or sample
    ; will be the total number of traces or samples in the data file
    ; minus one sample. Same goes for the user-selected start sample:

    last_trace = num_traces - 1
    last_sample = num_samples - 1
    start_sample -= 1

    ; Store all of the original data into an array:

    original_data = ENVI_GET_DATA( fid = file_id, dims = [ -1, 0, last_trace, 0, last_sample ], pos = 0 )

    ; Loop through each trace of the data file:

    FOR trace = 0, last_trace DO BEGIN

        ; Set all samples above the user-selected start sample equal to
        ; the original data value:

        filtered_data[ trace, 0:start_sample ] = original_data[ trace, 0:start_sample ]

        ; Now filter each remaining sample in the trace beginning with the
        ; user-selected start sample:

        num_filtered = 0
        FOR sample = start_sample, last_sample DO BEGIN
            num_filtered++

            ; Store the original data value for this sample:

            data_value = original_data[ trace, sample ]

            ; Convert the sample number to a time (in microseconds):

            time = ( ( ( time_window / 1000 ) / num_samples) * num_filtered )

            ; Compute the total gain for this sample:

            total_gain = ( linear_gain * time ) + EXP( exponential_gain * time )

            ; Store the newly scaled data value into a filtered-data array:

            filtered_data[ trace, sample ] = ROUND( data_value * total_gain )

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

    filtered_band_name = "Time-Varying Gain (" + band_name[0] + ")"

    ; Create a description that will get written to the output's ENVI header file
    ; based on the original file's description plus information about the filtering done:

    filtered_description = description + " Filtered with Time-Varying Gain (""time_varying_gain.pro""): " + $
                           "time window = " + STRING( time_window ) + "; start sample = " + $
                           STRING( start_sample + 1 ) + "; linear gain = " + STRING( linear_gain ) + $
                           "; exponential gain = " + STRING( exponential_gain ) + "."

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