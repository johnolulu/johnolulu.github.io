;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  collect_input_subtract_mean_trace
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL function is called by or for the "Subtract Mean Trace" ground-penetrating radar
;;  (GPR) image-processing filter (subtract_mean_trace.pro) to collect user input. It displays
;;  a window for the user to enter a subtraction method (either running average or total average)
;;  and for a window length (in traces) to apply to the filter if running average is the selected
;;  subtraction method. A "trace" is a single, vertical column of GPR data, representing the signal
;;  "traced" by a radar pulse as it travels from the instrument into the subsurface.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  result = collect_input_subtract_mean_trace( [num_traces = num_traces], [/SPECIFY_OUTPUT] )
;;
;;  Return Value:
;;
;;  result.accept = 1 if user selects "OK", 0 if "Cancel".
;;
;;  result.subtraction_method = either "running average" or "total average".
;;
;;  result.window_length = length of a sliding time window in number of traces (horizontal- or
;;      x- dimension) over which the filter is applied. If the optional keyword "num_traces"
;;      is not supplied, this field will instead return the length of the window in the percent
;;      of the total number of traces in the file (0% = 2 traces; 100% = all traces).
;;
;;  result.output_location = where to output filtered result, either to memory or to a file:
;;
;;      result.output_location.in_memory = 1 if output is to memory.
;;      result.output_location.name = full path and filename of file to output to.
;;
;;  Keywords:
;;
;;  num_traces (optional) = total number of traces (horizontal- or x- dimension) in the file
;;      being filtered. Used to provide a slider between two samples and the total number of
;;      samples in the file for the user to select a window length. If not provided, the slider
;;      will instead be between 0% (2 samples) and 100% (all samples), necessary when the number
;;      of samples in the file being filtered is not known in advance.
;;
;;  SPECIFY_OUTPUT (optional) = when this keyword is set, the widget will ask the user whether
;;      to save the output to memory or to a file; if the user chooses to output to a file, the
;;      widget will also ask the user where to save the file and what to name it.
;;
;;  Examples:
;;
;;  result = collect_input_subtract_mean_trace( num_traces = 1031 )
;;  result = collect_input_subtract_mean_trace( num_traces = 1031, /SPECIFY_OUTPUT )
;;  result = collect_input_subtract_mean_trace()
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

FUNCTION collect_input_subtract_mean_trace, num_traces = num_traces, specify_output = specify_output

    ; Define a default window length (in percent or number of traces) for the running average
    ; subtraction method:

    IF ( KEYWORD_SET( num_traces ) ) THEN BEGIN

        window_length_default = 60

        IF ( num_traces LE window_length_default ) THEN BEGIN
            window_percent_default = 0.1  ; a coefficient between 0 and 1
            window_length_default = FIX( num_traces * window_percent_default ) ; "FIX" function sets result to an integer
            IF ( window_length_default LT 2 ) THEN window_length_default = 2
        ENDIF

    ENDIF ELSE BEGIN
        window_length_default = 5  ; 5% of the total number of traces
    ENDELSE

    ; Create an IDL "widget" to allow user to input a subtraction method (running average
    ; or total average) and window length in traces (for the running average method only):

    ; Define the widget "Top Level Base" (TLB) and title:

    TLB = WIDGET_AUTO_BASE( title = 'Subtract Mean Trace' )

    ; Create a new base within TLB to frame and contain all of the input fields below
    ; except for the file output field:

    sub_base = WIDGET_BASE( TLB, /col, /frame )

    ; Provide a row to the above widget for setting the subtraction method (either
    ; running average or total average):

    row_base1 = WIDGET_BASE( sub_base, /row )
    subtraction_method = WIDGET_MENU( row_base1, /auto_manage, prompt = 'Subtraction method', $
        list = [ 'Running average', 'Total average' ], rows = 2, default_ptr = 0, /exclusive, $
        uvalue = 'subtraction_method' )

    ; Provide another row to the widget for setting the window length using a slider
    ; that goes between two traces (or 0%) and the total number of traces in the data file
    ; (num_traces, or 100%). Provide a reasonable default window length:

    row_base2 = WIDGET_BASE( sub_base, /row )

    IF ( KEYWORD_SET( num_traces ) ) THEN BEGIN
        window_length = WIDGET_SSLIDER( row_base2, /auto, title = 'Number of traces to use in running average', $
            min = 2, max = num_traces, value = window_length_default, uvalue = 'window_length' )
    ENDIF ELSE BEGIN
        title = 'Percent of traces to use in running average '
        window_length = WIDGET_SSLIDER( row_base2, /auto, title = 'Percent of traces to use in running average', $
            min = 0, max = 100, value = window_length_default, uvalue = 'window_length' )
        not_used = WIDGET_LABEL( row_base2, value = '%' )
        row_base3 = WIDGET_BASE( sub_base, /row )
        not_used = WIDGET_LABEL( row_base3, value = ' (0% = 2 samples; 100% = all samples)' )
    ENDELSE

    ; Ask the user whether to output the result to a file or to memory:

    IF ( KEYWORD_SET( specify_output ) ) THEN BEGIN
        output_location = WIDGET_OUTFM( TLB, /auto, uvalue = 'output_location', /frame )
    ENDIF

    ; The "AUTO_WID_MNG" function automatically performs event handling of ENVI widgets, without
    ; the need to write an event-handler procedure. The function returns an anonymous structure ("result")
    ; whose tag names are defined by the user values ("uvalue") of the widgets being managed. AUTO_WID_MNG
    ; automatically creates an "OK" and "Cancel" button on the widget unless the optional keyword
    ; NO_BUTTONS is set. In all cases, if the "OK" button is selected, the field "result.accept" (where
    ; "result" is the name of the structure returned by AUTO_WID_MNG) is set to one. Otherwise, if the
    ; "Cancel" button is selected then "result.accept" is set to zero:

    result = AUTO_WID_MNG( TLB )

    RETURN, result

END