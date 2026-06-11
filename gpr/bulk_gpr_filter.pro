;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  bulk_gpr_filter
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure applies selected image-processing filters on one or more RAMAC
;;  ground-penetrating radar (GPR) data files that have been previously formatted for
;;  viewing in ENVI. The following filters have been implemented as IDL procedures by
;;  the author to simulate filters available within Mala Geoscience "GroundVision" software
;;  that is used to acquire and process RAMAC ground-penetrating radar (GPR) data
;;  (GroundVision does not allow the user to permanently apply filtering to the data or to
;;  save the results to another file):
;;
;;  1. Subtract Mean Trace (subtract_mean_trace.pro)
;;
;;     Removes horizontal and nearly horizontal features within the radargram (i.e. "ringing")
;;     by subtracting a calculated mean trace from all traces. NOTE: A "trace" is a single,
;;     vertical column of GPR data, representing the signal "traced" by a radar pulse as it
;;     travels from the instrument into the subsurface. Each trace is composed of individual
;;     "samples," the smallest measurement unit in the vertical dimension.
;;
;;  2. Time-Varying Gain (time_varying_gain.pro)
;;
;;     Applies a time-varying (i.e. depth-varying) gain to compensate for amplitude loss due
;;     to spreading and attenuation. Each radar trace is multiplied by a gain function combining
;;     linear and exponential components, with coefficients set by the user.
;;
;;  3. DC Removal (dc_removal.pro)
;;
;;     There is often a constant offset in the amplitude of each radar trace caused by interference
;;     from direct current (DC) used to power the GPR instrument. This filter removes the DC
;;     component from the data, which has the effect of making the data less noisy, or smoothing
;;     the data.
;;
;;  Refer to the documentation within each of the aforementioned IDL procedures above for
;;  further details on their operation. Each is located in the ENVI "save_add" directory.
;;
;;  This IDL procedure operates in the following manner:
;;
;;  1. Collect the necessary user input:
;;
;;      a.) Ask the user to select the input files to be filtered. These must all be in the same
;;          directory. The user can use Shift-click to select multiple contiguous files or
;;          Ctrl-click to individually select multiple files.
;;
;;      b.) The user must then check off the filters to be applied to the input files from a list
;;          of the available filters and select the order in which these filters should be applied
;;          to the files.
;;
;;      c.) An input window will then appear for each of the selected filters for the user to
;;          provide the necessary parameters to be applied for these filters.
;;
;;      d.) Lastly, the user must select an output directory to save the resulting files to. Also,
;;          a filename pattern must be determined for naming the output files, including a basename,
;;          suffix, and the format of an incrementing number to be inserted in the middle.
;;
;;      e.) Display the user's selections and ask the user for confirmation before continuing. Also
;;          ask the user for an existing or new log file to write messages to during processing.
;;
;;  2. The IDL procedure then applies the above selected filters in the order specified on a
;;     on a file-by-file basis. A status window will display the percentage of completion for
;;     all of the files to be filtered. This status window includes a "Cancel" button to terminate
;;     the program prematurely. Individual status windows are also displayed for the progress of each
;;     individual filter that is run. Status messages will also be written to the specified log
;;     file so that a history of events can be viewed after processing is complete.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, add the
;;  following lines to ENVI's main menu configuration file (envi.men) located in ENVI's
;;  "menu" directory:
;;
;;      0 {GPR}
;;         1 {Bulk Filter} {not used} {bulk_gpr_filter}
;;
;;  This procedure can then be run from the pull-down menu labelled "GPR" on ENVI's main
;;  menu bar.
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

PRO bulk_gpr_filter, event

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                      ;;
    ;;  Steps 1a - 1e:                      ;;
    ;;                                      ;;
    ;;  Get required inputs from the user.  ;;
    ;;                                      ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                            ;;
    ;;  Step 1a: Determine what files to filter.  ;;
    ;;                                            ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    input_files = ENVI_PICKFILE( title = "Select the GPR file(s) to be filtered:", /MULTIPLE_FILES )

    ; If the user pressed "Cancel" then exit:

    IF ( input_files[0] EQ '' ) THEN RETURN

    ; Determine how many input files were selected:

    num_input_files = N_ELEMENTS( input_files )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                               ;;
    ;;  Step 1b: Determine what filters to apply and in what order.  ;;
    ;;                                                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Define the list and number of available filters:

    filter_list = [ 'Subtract Mean Trace', 'Time-Varying Gain', 'DC Removal' ]
    num_filters_total = N_ELEMENTS( filter_list )

    ; Create an IDL "widget" to allow user input...

    ; Define the widget "Top Level Base" (TLB) and title:

    TLB = WIDGET_AUTO_BASE( title = 'Bulk GPR Filter' )

    ; Provide a row to the above widget for providing a checklist of the available filters:

    row_base1 = WIDGET_BASE( TLB, /row )
    filter_selections = WIDGET_MENU( row_base1, /auto, list = filter_list, rows = num_filters_total, $
        prompt = "Select the filters to be applied:", uvalue = 'filter_selections' )

    ; The "AUTO_WID_MNG" function automatically performs event handling of ENVI widgets, without
    ; the need to write an event-handler procedure. The function returns an anonymous structure ("result")
    ; whose tag names are defined by the user values ("uvalue") of the widgets being managed. AUTO_WID_MNG
    ; automatically creates an "OK" and "Cancel" button on the widget unless the optional keyword
    ; NO_BUTTONS is set. In all cases, if the "OK" button is selected, the field "result.accept" (where
    ; "result" is the name of the structure returned by AUTO_WID_MNG) is set to one. Otherwise, if the
    ; "Cancel" button is selected then "result.accept" is set to zero:

    result = AUTO_WID_MNG( TLB )

    ; If the user pressed "Cancel" then exit:

    IF ( result.accept EQ 0 ) THEN RETURN

    ; The WIDGET_MENU above returns an array of 0's and 1's depending on whether the
    ; filters in filter_list were selected or not. From this, store a new array of the
    ; filter names of only those filters that were selected by the user:

    ; ...First determine how many filters were selected:

    num_filters_to_apply = 0
    FOR i = 0, num_filters_total - 1 DO BEGIN
        IF ( result.filter_selections[ i ] EQ 1 ) THEN num_filters_to_apply++
    ENDFOR

    ; ...Initialize new array:

    filters_to_apply = STRARR( num_filters_to_apply )

    ; ...Store the selected filters in the new array:

    j = 0
    FOR i = 0, num_filters_total - 1 DO BEGIN
        IF ( result.filter_selections[ i ] EQ 1 ) THEN BEGIN
            filters_to_apply[ j ] = filter_list[ i ]
            j++
        ENDIF
    ENDFOR

    ; If more than one filter was selected, determine what order to apply the filters in:

    IF ( num_filters_to_apply GT 1 ) THEN BEGIN

        ; Initialize two variables:

        order_values = STRCOMPRESS( STRING( INDGEN( num_filters_to_apply ) + 1 ), /REMOVE_ALL )
        error = 0

        ; Repeat the widget until the user properly selects the order in which to apply each filter:

        REPEAT BEGIN

            ; Define the widget "Top Level Base" (TLB) and title:

            TLB = WIDGET_AUTO_BASE( title = 'Bulk GPR Filter' )

            ; If the user did not properly select the ordering of filters in the previous try, display
            ; a message to this effect:

            IF ( error GT 0 ) THEN BEGIN

                ; Create a new base within TLB to frame the error message:

                sub_base = WIDGET_BASE( TLB, /col, /frame )

                row_base0 = WIDGET_BASE( sub_base, /row )
                widget_error_explanation = 'ERROR!: More than one filter was given the same order. Please try again.'
                not_used = WIDGET_LABEL( row_base0, value = widget_error_explanation )

            ENDIF

            row_base1 = WIDGET_BASE( TLB, /row )
            widget_explanation = 'Select the order in which each filter will be applied to the selected files:'
            not_used = WIDGET_LABEL( row_base1, value = widget_explanation )

            ; Provide a row to the above widget for determining the order of each of the selected filters:

            FOR i = 0, num_filters_to_apply - 1 DO BEGIN

                prompt = '     '
                uvalue = STRCOMPRESS( 'filter_order' + STRING( i ), /REMOVE_ALL )
                row_base2 = WIDGET_BASE( TLB, /row )

                ; If a filter ordering was previously selected and an error caused the input window
                ; to be repeated, re-use the selected values as new defaults:

                IF ( N_ELEMENTS( orders ) EQ 0 ) THEN BEGIN
                    default_order = i
                ENDIF ELSE BEGIN
                    default_order = orders[ i ]
                ENDELSE

                filter_order = WIDGET_PMENU( row_base2, /auto, list = order_values, default = default_order, $
                    xsize = 1, prompt = prompt, uvalue = uvalue )

                label_filter = filters_to_apply[ i ]
                not_used = WIDGET_LABEL( row_base2, value = label_filter )

            ENDFOR

            result = AUTO_WID_MNG( TLB )

            ; If the user pressed "Cancel" then exit:

            IF ( result.accept EQ 0 ) THEN RETURN

            ; Sort the array of filters to be applied according to the criteria set by
            ; the user in the widget above:

            filters_to_apply_sorted = STRARR( num_filters_to_apply )
            orders = INTARR( num_filters_to_apply )

            FOR i = 0, num_filters_to_apply - 1 DO BEGIN
                orders[ i ] = result.( i )
                filters_to_apply_sorted[ orders[ i ] ] = filters_to_apply[ i ]
            ENDFOR

            ; Make sure none of the filter orders are the same in the user's results.
            ; If the number of unique elements in the array of orders is not the same
            ; as the number of selected filters, then repeat the widget to force the
            ; user to try again:

            num_unique_orders = N_ELEMENTS( orders[ UNIQ( orders, SORT( orders ) ) ] )

            error++

        ENDREP UNTIL ( num_unique_orders EQ num_filters_to_apply )

    ENDIF ELSE BEGIN
            filters_to_apply_sorted = filters_to_apply
    ENDELSE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                         ;;
    ;;  Step 1c: Determine filter parameters.  ;;
    ;;                                         ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    FOR i = 0, num_filters_to_apply - 1 DO BEGIN

        ; Create an IDL widget to allow user to input the necessary filter parameters:

        CASE filters_to_apply_sorted[ i ] OF
            'Subtract Mean Trace': BEGIN
                    result = COLLECT_INPUT_SUBTRACT_MEAN_TRACE()

                    ; If the user pressed "Cancel" then exit:

                    IF ( result.accept EQ 0 ) THEN RETURN

                    ; Set the resulting subtraction method to a variable:

                    subtraction_method = result.subtraction_method

                    CASE subtraction_method OF
                        0: subtraction_method = 'running average'
                        1: subtraction_method = 'total average'
                    ENDCASE

                    ; Set the resulting window length to an integer variable:

                    subtraction_window_length = FIX( result.window_length )

                    IF ( subtraction_method EQ 'total average' ) THEN BEGIN
                        subtraction_window_length = 100
                    ENDIF
                END
            'Time-Varying Gain': BEGIN
                    result = COLLECT_INPUT_TIME_VARYING_GAIN()

                    ; If the user pressed "Cancel" then exit:

                    IF ( result.accept EQ 0 ) THEN RETURN

                    ; Set the following result structure field to its own variable:

                    timevary_window = result.time_window

                    ; Set the following result structure fields to integer variables:

                    timevary_start_sample = FIX( result.start_sample )
                    timevary_linear_gain = FIX( result.linear_gain )
                    timevary_exponential_gain = FIX( result.exponential_gain )
                END
            'DC Removal': BEGIN
                    result = COLLECT_INPUT_DC_REMOVAL()

                    ; If the user pressed "Cancel" then exit:

                    IF ( result.accept EQ 0 ) THEN RETURN

                    ; Set the result structure field to an integer variable:

                    dcremoval_start_sample = FIX( result.start_sample )
                END
        ENDCASE

    ENDFOR

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                              ;;
    ;;  Step 1d: Determine output location and filenaming pattern.  ;;
    ;;                                                              ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Create an IDL "widget" to allow user input...

    ; Repeat the widget until the user properly selects a counter starter that is of the selected
    ; number of digits or less:

    error = 0

    REPEAT BEGIN

        ; Define the widget "Top Level Base" (TLB) and title:

        TLB = WIDGET_AUTO_BASE( title = 'Bulk GPR Filter' )

        ; If the user did not properly select a counter start number, display
        ; a message to this effect:

        IF ( error GT 0 ) THEN BEGIN

            ; Create a new base within TLB to frame the error message:

            sub_base0 = WIDGET_BASE( TLB, /col, /frame )

            row_base0 = WIDGET_BASE( sub_base0, /row )
            widget_error_explanation = 'ERROR!: Counter start number (' + $
                STRCOMPRESS( STRING( output_counter_start ), /REMOVE_ALL ) + ') ' + $
                'is greater than the selected number of digits (' + $
                STRCOMPRESS( STRING( output_counter_digits ), /REMOVE_ALL ) + ') ' + $
                '. Please try again.'
            not_used = WIDGET_LABEL( row_base0, value = widget_error_explanation )

        ENDIF

        ; Create a new base within TLB to frame the output directory input field:

        sub_base = WIDGET_BASE( TLB, /col, /frame )

        ; Provide a row to the above widget for determining the output directory:

        ; ...First determine the input directory so that we can set this as the
        ; default output directory. If an output directory was previously selected
        ; and an error caused the input window to be repeated, re-use the
        ; selected value instead:

        IF ( N_ELEMENTS( output_directory ) EQ 0 ) THEN BEGIN
            default_directory = FILE_DIRNAME( input_files[0] )
        ENDIF ELSE BEGIN
            default_directory = output_directory
        ENDELSE

        row_base1 = WIDGET_BASE( sub_base, /row )
        output_directory = WIDGET_OUTF( row_base1, /auto, /directory, prompt = 'Select an output directory:', $
            default = default_directory, uvalue = 'output_directory')

        ; Create a new base within TLB to frame and contain the rest of the input fields:

        sub_base2 = WIDGET_BASE( TLB, /col, /frame )

        ; Tell the user how many input files have been selected:

        row_base2 = WIDGET_BASE( sub_base2, /row )

        IF ( num_input_files GT 1 ) THEN BEGIN
            inform_user_numfiles = 'You have selected ' + STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL ) + $
                ' files to be filtered. Select an output filenaming convention below, as so:'
        ENDIF ELSE BEGIN
            inform_user_numfiles = 'You have selected ' + STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL ) + $
                ' file to be filtered. Select an output filenaming convention below, as so:'
        ENDELSE

        not_used = WIDGET_LABEL( row_base2, value = inform_user_numfiles )

        ; Explain how the output filenaming convention is constructed:

        row_base3 = WIDGET_BASE( sub_base2, /row )
        filenaming_explanation = '     basename + ### + suffix'
        not_used = WIDGET_LABEL( row_base3, value = filenaming_explanation )

        row_base4 = WIDGET_BASE( sub_base2, /row )
        filenaming_example = '     Example: "output_t" + ### + "f.bin" = "output_t001f.bin"'
        not_used = WIDGET_LABEL( row_base4, value = filenaming_example )

        ; Provide another row to the widget for determining the base filename to
        ; apply to all output files:

        ; ...First determine a default basename depending on whether one was previously
        ; selected and an error caused the input window to be repeated:

        IF ( N_ELEMENTS( output_basename ) EQ 0 ) THEN BEGIN
            default_basename = ""
        ENDIF ELSE BEGIN
            default_basename = output_basename
        ENDELSE

        row_base5 = WIDGET_BASE( sub_base2, /row )
        output_basename = WIDGET_STRING( row_base5, /auto, prompt = 'Enter a basename for the output files:', $
            xsize = 30, default = default_basename, uvalue = 'output_basename')

        ; Provide another row to the widget for determining the number of digits to
        ; use in the file counter:

        ; ...First determine a default based on the number of input files. e.g. 5 files would mean
        ; 1 digit, 15 files would mean 2 digits, 150 files would mean 3 digits, etc. Based on the
        ; length of a string (STRLEN) composed of the number of input files:

        default_digits = STRLEN( STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL ) )

        ; ...Next create an string array of possible numbers of digits for a pull-down menu that goes
        ; between the lowest number of digits possible (default_digits) and the the maximum number
        ; of digits allowed (max_digits):

        max_digits = 5
        counter_values = STRCOMPRESS( STRING( INDGEN( max_digits ) + default_digits ), /REMOVE_ALL )

        ; If the number of digits was previously selected and an error caused the input
        ; window to be repeated, re-use the selected value as the new default:

        IF ( N_ELEMENTS( output_counter_index ) EQ 0 ) THEN BEGIN
            default_counter_index = 0
        ENDIF ELSE BEGIN
            default_counter_index = output_counter_index
        ENDELSE

        ; ...Now define the pull-down menu from the values defined above:

        row_base6 = WIDGET_BASE( sub_base2, /row )
        prompt = 'Select the number of digits to use in the file counter (###):'
        output_counter_index = WIDGET_PMENU( row_base6, /auto, list = counter_values, prompt = prompt, $
            xsize = 1, default = default_counter_index, uvalue = 'output_counter_index' )

        ; Provide another row to the widget for determining the number to start at in
        ; the file counter:

        ; ...First determine a default start number depending on whether one was previously
        ; selected and an error caused the input window to be repeated:

        IF ( N_ELEMENTS( output_counter_start ) EQ 0 ) THEN BEGIN
            default_counter_start = 1
        ENDIF ELSE BEGIN
            default_counter_start = output_counter_start
        ENDELSE

        row_base7 = WIDGET_BASE( sub_base2, /row )
        prompt = 'Enter the first number to begin the file counter at:'
        output_counter_start = WIDGET_PARAM( row_base7, /auto, default = default_counter_start, $
            floor = 0, dt = 2, prompt = prompt, xsize = 5, uvalue = 'output_counter_start' )

        ; Provide another row to the widget for determining the filename suffix to
        ; apply to all output files:

        ; ...First determine a default suffix depending on whether one was previously
        ; selected and an error caused the input window to be repeated:

        IF ( N_ELEMENTS( output_suffix ) EQ 0 ) THEN BEGIN
            default_suffix = ""
        ENDIF ELSE BEGIN
            default_suffix = output_suffix
        ENDELSE

        row_base8 = WIDGET_BASE( sub_base2, /row )
        output_suffix = WIDGET_STRING( row_base8, /auto, prompt = 'Enter a suffix for the output files:', $
            xsize = 15, default = default_suffix, uvalue = 'output_suffix' )

        result = AUTO_WID_MNG( TLB )

        ; If the user pressed "Cancel" then exit:

        IF ( result.accept EQ 0 ) THEN RETURN

        ; Set result structure fields to their own variables:

        output_directory = result.output_directory
        output_basename = result.output_basename
        output_counter_index = result.output_counter_index
        output_counter_digits = counter_values[ output_counter_index ]
        output_counter_start = FIX( result.output_counter_start )
        output_suffix = result.output_suffix

        ; Determine the number of digits in the user's selected counter starter:

        num_digits_starter = STRLEN( STRCOMPRESS( STRING( output_counter_start ), /REMOVE_ALL ) )
        error++

    ENDREP UNTIL ( num_digits_starter LE output_counter_digits )

    ; Create an array of the output filenames using the basename, counter, and suffix pattern
    ; specified by the user above:

    output_filenames = STRARR( num_input_files )

    ; ...Determine the proper file path segment separator character for the current operating system
    ; (e.g. Windows = "\", Unix = "/"):

    path_separator = PATH_SEP()

    FOR i = 0, num_input_files - 1 DO BEGIN

        ; Determine the counter to add to the current filename, using the user-selected number
        ; of digits:

        current_counter = output_counter_start + i
        current_counter_digits = STRLEN( STRCOMPRESS( STRING( current_counter ), /REMOVE_ALL ) )

        WHILE (current_counter_digits LT output_counter_digits) DO BEGIN
            current_counter = '0' + STRCOMPRESS( STRING( current_counter ), /REMOVE_ALL )
            current_counter_digits = STRLEN( current_counter )
        ENDWHILE

        ; Determine current filename from current counter and add to array:

        current_filename = output_basename + STRCOMPRESS( STRING( current_counter ), /REMOVE_ALL) + output_suffix
        output_filenames[ i ] = output_directory + path_separator + current_filename

    ENDFOR

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                               ;;
    ;;  Step 1e: Display and confirm user input and  ;;
    ;;  determine log file location                  ;;
    ;;                                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Initialize an array to hold strings of information to be displayed at the top
    ; of the selected log file:

    log_header = STRARR( 16 )
    j = 0

    ; Define the widget "Top Level Base" (TLB) and title:

    TLB = WIDGET_AUTO_BASE( title = 'Bulk GPR Filter' )

    ; Create a new base within TLB to frame the output:

    sub_base1 = WIDGET_BASE( TLB, /col, /frame )

    row_base1 = WIDGET_BASE( sub_base1, /row )
    not_used = WIDGET_LABEL( row_base1, value = 'Please confirm your settings and select a log file:' )

    ; Create a separate frame to display the user's input parameters:

    sub_base2 = WIDGET_BASE( TLB, /col, /frame )

    ; Display selected input directory:

    row_base2 = WIDGET_BASE( sub_base2, /row )
    display_input_directory = 'Input directory: ' + FILE_DIRNAME( input_files[0] )
    log_header[ j++ ] = display_input_directory
    not_used = WIDGET_LABEL( row_base2, value = display_input_directory )

    ; Display number of selected files:

    row_base3 = WIDGET_BASE( sub_base2, /row )
    display_num_files = 'Number of files selected: ' + STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL )
    log_header[ j++ ] = display_num_files
    not_used = WIDGET_LABEL( row_base3, value = display_num_files )

    ; Display each of the selected filters and their selected parameters:

    row_base4 = WIDGET_BASE( sub_base2, /row )
    prompt = 'Filter(s) to apply (listed in order selected):'
    log_header[ j++ ] = prompt
    not_used = WIDGET_LABEL( row_base4, value = prompt )

    FOR i = 0, num_filters_to_apply - 1 DO BEGIN

        display_filter = '     ' + STRCOMPRESS( STRING( i + 1 ), /REMOVE_ALL ) + '. ' + $
            filters_to_apply_sorted[ i ]
        log_header[ j++ ] = display_filter
        row_base5 = WIDGET_BASE( sub_base2, /row )
        not_used = WIDGET_LABEL( row_base5, value = display_filter )

       indent = '               '

        CASE filters_to_apply_sorted[ i ] OF
            'Subtract Mean Trace': BEGIN

                    row_base6 = WIDGET_BASE( sub_base2, /row )
                    display_subtraction_method = indent + 'Subtraction method: ' + subtraction_method
                    log_header[ j++ ] = display_subtraction_method
                    not_used = WIDGET_LABEL( row_base6, value = display_subtraction_method )

                    row_base7 = WIDGET_BASE( sub_base2, /row )
                    display_window_length = indent + 'Window length: ' + STRCOMPRESS( $
                        STRING( subtraction_window_length ), /REMOVE_ALL ) + '%  (0% = 2 samples; 100% = all samples)'
                    log_header[ j++ ] = display_window_length
                    not_used = WIDGET_LABEL( row_base7, value = display_window_length )

                END
            'Time-Varying Gain': BEGIN

                    row_base6 = WIDGET_BASE( sub_base2, /row )
                    display_time_window = indent + 'Time window (ns): ' + STRCOMPRESS( STRING( timevary_window ), $
                        /REMOVE_ALL )
                    log_header[ j++ ] = display_time_window
                    not_used = WIDGET_LABEL( row_base6, value = display_time_window )

                    row_base7 = WIDGET_BASE( sub_base2, /row )
                    display_start_sample = indent + 'Start sample: ' + $
                        STRCOMPRESS( STRING( timevary_start_sample ), /REMOVE_ALL ) + '%' + $
                        '  (0% = first sample; 100% = last sample)'
                    log_header[ j++ ] = display_start_sample
                    not_used = WIDGET_LABEL( row_base7, value = display_start_sample )

                    row_base8 = WIDGET_BASE( sub_base2, /row )
                    display_linear_gain = indent + 'Linear gain: ' + STRCOMPRESS( STRING( timevary_linear_gain ), $
                        /REMOVE_ALL )
                    log_header[ j++ ] = display_linear_gain
                    not_used = WIDGET_LABEL( row_base8, value = display_linear_gain )

                    row_base9 = WIDGET_BASE( sub_base2, /row )
                    display_exponential_gain = indent + 'Exponential gain: ' + STRCOMPRESS( $
                        STRING( timevary_exponential_gain ), /REMOVE_ALL )
                    log_header[ j++ ] = display_exponential_gain
                    not_used = WIDGET_LABEL( row_base9, value = display_exponential_gain )

                END
            'DC Removal': BEGIN

                    row_base6 = WIDGET_BASE( sub_base2, /row )
                    display_start_sample = indent + 'Start sample: ' + $
                        STRCOMPRESS( STRING( dcremoval_start_sample ), /REMOVE_ALL ) + '%' + $
                        '  (0% = first sample; 100% = last sample)'
                    log_header[ j++ ] = display_start_sample
                    not_used = WIDGET_LABEL( row_base6, value = display_start_sample )

                END
        ENDCASE

    ENDFOR

    ; Display selected output directory:

    row_base5 = WIDGET_BASE( sub_base2, /row )
    display_output_directory = 'Output directory: ' + output_directory
    log_header[j++] = display_output_directory
    not_used = WIDGET_LABEL( row_base5, value = display_output_directory )

    ; Display first output filename:

    row_base6 = WIDGET_BASE( sub_base2, /row )
    display_output_filename = 'First output filename: ' + FILE_BASENAME( output_filenames[0] )
    log_header[ j++ ] = display_output_filename
    not_used = WIDGET_LABEL( row_base6, value = display_output_filename )

    ; Display last output filename:

    row_base7 = WIDGET_BASE( sub_base2, /row )
    display_output_filename = 'Last output filename: ' + FILE_BASENAME( output_filenames[ num_input_files - 1 ] )
    log_header[ j ] = display_output_filename
    not_used = WIDGET_LABEL( row_base7, value = display_output_filename )

    ; Create a separate frame to determine an output log file to write to during processing:

    sub_base3 = WIDGET_BASE( TLB, /col, /frame )

    ; Determine log file (new or existing):

    row_base8 = WIDGET_BASE( sub_base3, /row )
    default_log_file = output_directory + path_separator + 'bulk_gpr_filter.log'
    log_file = WIDGET_OUTF( row_base8, /auto, prompt = 'Select a log file to write to:', $
        default = default_log_file, xsize = 75, uvalue = 'log_file' )

    row_base9 = WIDGET_BASE( sub_base3, /row )
    display_logfile_warning = ' NOTE: When selecting an existing log file, contents will be overwritten.'
    not_used = WIDGET_LABEL( row_base9, value = display_logfile_warning )

    ; Collect the results from the above widget:

    result = AUTO_WID_MNG( TLB )

    ; If the user pressed "Cancel" then exit:

    IF ( result.accept EQ 0 ) THEN RETURN

    ; Save the selected log file to a variable:

    log_file = result.log_file

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                       ;;
    ;;  Step 2:                              ;;
    ;;                                       ;;
    ;;  Apply the specified filter(s) on a   ;;
    ;;  file-by-file basis.                  ;;
    ;;                                       ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Open the log file for writing and print header information:

    OPENW, lun, log_file, /GET_LUN

    PRINTF, lun, 'bulk_gpr_filter.pro log file'
    PRINTF, lun, '========================================='

    FOR i = 0, N_ELEMENTS( log_header ) - 1 DO BEGIN
        IF ( log_header[ i ] NE "" ) THEN BEGIN
            PRINTF, lun, log_header[ i ]
        ENDIF
    ENDFOR

    PRINTF, lun, '========================================='

    ; Display a status window to show what percentage of processing is currently
    ; complete...

    ; ...First define the text strings that will be displayed in the status reporting
    ; dialog:

    status_string1 = 'Number of files: ' + STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL )
    status_string2 = 'Filter(s) to apply (listed in order selected): '
    status_string3 = '     '

    FOR i = 0, num_filters_to_apply - 1 DO BEGIN
        status_string3 += filters_to_apply_sorted[ i ]
        IF ( i LT ( num_filters_to_apply - 1 ) ) THEN BEGIN
            status_string3 += ', '
        ENDIF ELSE BEGIN
            status_string3 += '.'
        ENDELSE
    ENDFOR

    status_string4 = 'Started: ' + SYSTIME()
    status_string5 = 'Log file: ' + log_file
    status_string6 = ''
    status_string7 = 'Press "Cancel" to quit processing after the current file.'

    status_strings = [ status_string1, status_string2, status_string3, status_string4, status_string5, $
        status_string6, status_string7 ]

    ; ...Now initiate the status window. The "/interrupt" option gives the user
    ; the option to cancel processing at any time:

    ENVI_REPORT_INIT, status_strings, base = status_base, /interrupt, title = 'Bulk GPR Filter'

    ; Initialize variable to store the total number of traces (x-axis) and total size
    ; in bytes of all input (or output) files:

    total_traces = 0
    total_size_bytes = 0

    ; Loop through the input files, applying filters and recording info to the log file:

    FOR i = 0, num_input_files - 1 DO BEGIN

        display_file_count = 'File ' + STRCOMPRESS( STRING( i + 1 ), /REMOVE_ALL ) + ' of ' + $
            STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL ) + ': ' + input_files[ i ]
        PRINTF, lun, display_file_count
        PRINTF, lun, 'Input filename: ' + FILE_BASENAME( input_files[ i ] )
        start_time = SYSTIME()
        PRINTF, lun, 'Started: ' + start_time

        ; Record the first start time in a variable to record in log file later:

        IF ( i EQ 0 ) THEN BEGIN
            total_start_time = start_time
        ENDIF

        ; Open the specified input file, suppressing the ENVI Header Information dialog when a valid
        ; ENVI header file does not exist (/NO_INTERACTIVE_QUERY) and suppressing the opening of the
        ; Available Bands List window (/NO_REALIZE):

        ENVI_OPEN_FILE, input_files[ i ], r_fid = file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

        ; If the file could not be opened, then write message to log file and exit:

        IF ( file_id EQ -1 ) THEN BEGIN
            error_message = "ERROR!: unable to open file """ + input_files[ i ] + """
            PRINTF, lun, error_message
            PRINTF, lun, SYSTIME()
            MESSAGE, error_message
        ENDIF

        ; Determine the number of samples (vertical dimension, or y-axis) and traces (horizontal
        ; dimension, or x-axis) associated with this file: [NOTE: In ENVI-terminology, "samples"
        ; are counted in the horizontal dimension ("ns") and "lines" are counted in the vertical
        ; dimension ("nl"), but we use GPR-terminology here instead to avoid confusion.]

        ENVI_FILE_QUERY, file_id, nl = num_samples, ns = num_traces

        total_traces += num_traces
        PRINTF, lun, 'Samples (y-axis): ' + STRCOMPRESS( STRING( num_samples ), /REMOVE_ALL )
        PRINTF, lun, 'Traces (x-axis): ' + STRCOMPRESS( STRING( num_traces ), /REMOVE_ALL )

        ; Determine the size (bytes) of the file:

        file_info = FILE_INFO( input_files[ i ] )
        file_size_bytes = file_info.size
        total_size_bytes += file_size_bytes
        file_size_megabytes = ( FLOAT( file_size_bytes ) / 1024.0 ) / 1024.0
        PRINTF, lun, 'Size: ' + STRCOMPRESS( STRING( file_size_megabytes ), /REMOVE_ALL ) + ' MB'

        ; Apply each of the selected filters to the file, in the order that the user specified.
        ; If more than one filter is being applied, store results to temporary files in the
        ; specified output directory until the last filter is applied. Then remove all temporary
        ; files:

        ; ...First initialize an array of temporary filenames. This will be used to remove all
        ; temporary files later:

        temp_filenames = STRARR( num_filters_to_apply )

        FOR j = 0, num_filters_to_apply - 1 DO BEGIN

            ; If a temporary file was previously created by this "for" loop, use that as the new
            ; input file. Otherwise, use the current input file:

            IF ( j GT 0 ) THEN BEGIN
                IF ( temp_filenames[ j - 1 ] NE "" ) THEN BEGIN
                    input_filename = temp_filenames[ j - 1 ]
                ENDIF ELSE BEGIN
                    input_filename = input_files[ i ]
                ENDELSE
            ENDIF ELSE BEGIN
                input_filename = input_files[ i ]
            ENDELSE

            ; Determine the output filename. If this is not the last filter being applied, determine
            ; a temporary filename based on the selected output filename:

            IF ( j LT ( num_filters_to_apply - 1 ) ) THEN BEGIN
                output_filename = output_filenames[ i ] + STRCOMPRESS( STRING( j ), /REMOVE_ALL )
                temp_filenames[ j ] = output_filename
            ENDIF ELSE BEGIN
                output_filename = output_filenames[ i ]
            ENDELSE

            CASE filters_to_apply_sorted[ j ] OF
                'Subtract Mean Trace': BEGIN

                        ; Determine the window length in number of traces based on the percent of
                        ; traces specified previously by "subtraction_window_length". If the
                        ; subtraction_method is "total average" or the percentage is 100%, ignore
                        ; the window length since not supplying it to the "subtract_mean_trace"
                        ; procedure will indicate that it should run a total average:

                        IF ( subtraction_method NE 'total average' AND subtraction_window_length NE 100 ) THEN BEGIN

                            IF ( subtraction_window_length NE 0 ) THEN BEGIN
                                window_length_percent = subtraction_window_length / 100.0
                                window_length_traces = ROUND( window_length_percent * num_traces )
                            ENDIF ELSE BEGIN
                                ; 0% = 2 traces:
                                window_length_traces = 2
                            ENDELSE

                            SUBTRACT_MEAN_TRACE, input_location = input_filename, window_length = window_length_traces, $
                                output_location = output_filename

                        ENDIF ELSE BEGIN
                            SUBTRACT_MEAN_TRACE, input_location = input_filename, output_location = output_filename
                        ENDELSE
                    END
                'Time-Varying Gain': BEGIN

                        ; Determine the start sample to begin applying the filter at based on the
                        ; percent of samples specified previously by "timevary_start_sample" and
                        ; the number of samples in this file:

                        IF ( timevary_start_sample NE 0 ) THEN BEGIN
                            start_sample_percent = timevary_start_sample / 100.0
                            start_sample_num = ROUND( start_sample_percent * num_samples )
                        ENDIF ELSE BEGIN
                            ; 0% = 1st sample:
                            start_sample_num = 1
                        ENDELSE

                        TIME_VARYING_GAIN, input_location = input_filename, time_window = timevary_window, $
                            start_sample = start_sample_num, linear_gain = timevary_linear_gain, $
                            exponential_gain = timevary_exponential_gain, output_location = output_filename
                    END
                'DC Removal': BEGIN

                        ; Determine the start sample to begin applying the filter at based on the
                        ; percent of samples specified previously by "dcremoval_start_sample" and
                        ; the number of samples in this file:

                        IF ( dcremoval_start_sample NE 0 ) THEN BEGIN
                            start_sample_percent = dcremoval_start_sample / 100.0
                            start_sample_num = ROUND( start_sample_percent * num_samples )
                        ENDIF ELSE BEGIN
                            ; 0% = 1st sample:
                            start_sample_num = 1
                        ENDELSE

                        DC_REMOVAL, input_location = input_filename, start_sample = start_sample_num, $
                            output_location = output_filename
                    END
            ENDCASE

            ; Record in the log file when the filter completed:

            PRINTF, lun, filters_to_apply_sorted[ j ] + ' completed: ' + SYSTIME()

            ; If a temporary file was previously created by this "for" loop and used as the current
            ; input file, remove it now that the filtering on that temporary file is completed and
            ; a new output file has been created:

            IF ( j GT 0 ) THEN BEGIN
                IF ( temp_filenames[ j - 1 ] NE "" ) THEN BEGIN

                    ; Get an ENVI file ID associated with this temp file:

                    ENVI_OPEN_FILE, temp_filenames[ j - 1 ], r_fid = temp_file_id, /NO_INTERACTIVE_QUERY, /NO_REALIZE

                    ; Remove this file ID from ENVI so that it doesn't appear in the "Available
                    ; Bands List" window:

                    ENVI_FILE_MNG, id = temp_file_id, /REMOVE

                    ; Delete the file from the user's competer:

                    FILE_DELETE, temp_filenames[ j - 1 ]

                ENDIF
            ENDIF

        ENDFOR

        ; Record the output filename in the log file:

        PRINTF, lun, 'Output file: ' + output_filenames[ i ]
        PRINTF, lun, 'Output filename: ' + FILE_BASENAME( output_filenames[ i ] )

        ; Record in the log file when processing completed for this file:

        completed_time = SYSTIME()
        PRINTF, lun, 'Completed: ' + completed_time
        PRINTF, lun, ''

        ; Update the status window with the current percentage of completion:

        ENVI_REPORT_STAT, status_base, i + 1, num_input_files, cancel = cancel

        ; If the user chooses to cancel processing from the status window, delete
        ; the status window and exit the program:

        IF ( cancel EQ 1 ) THEN BEGIN
            ENVI_REPORT_INIT, base = status_base, /finish

            ; Print message to log file and close it:
            PRINTF, lun, 'Processing cancelled: ' + SYSTIME()
            FREE_LUN, lun

            RETURN
        ENDIF

    ENDFOR

    ; Record the total traces (x-axis) and size of all input (or output) files in the log file:

    PRINTF, lun, '========================================='
    PRINTF, lun, 'Start time:      ' + total_start_time
    PRINTF, lun, 'Completion time: ' + completed_time
    PRINTF, lun, 'Number of files: ' + STRCOMPRESS( STRING( num_input_files ), /REMOVE_ALL )
    PRINTF, lun, 'Total traces (x-axis): ' + STRCOMPRESS( STRING( total_traces ), /REMOVE_ALL )
    total_size_megabytes = ( FLOAT( total_size_bytes ) / 1024.0 ) / 1024.0
    PRINTF, lun, 'Total size: ' + STRCOMPRESS( STRING( total_size_megabytes ), /REMOVE_ALL ) + ' MB'

    ; Close the log file:

    FREE_LUN, lun

    ; Close the status window:

    ENVI_REPORT_INIT, base = status_base, /finish
END