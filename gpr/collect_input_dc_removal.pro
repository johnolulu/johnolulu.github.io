;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  collect_input_dc_removal
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL function is called by or for the "DC Removal" ground-penetrating radar (GPR)
;;  image-processing filter (dc_removal.pro) to collect user input. It displays a window
;;  for the user to enter a start sample for calculation of each trace's DC level. "DC"
;;  stands for an electrical "direct current."  A "trace" is a single, vertical column of
;;  GPR data, representing the signal "traced" by a radar pulse as it travels from the
;;  instrument into the subsurface.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  result = collect_input_dc_removal( [num_samples = num_samples], [/SPECIFY_OUTPUT] )
;;
;;  Return Value:
;;
;;  result.accept = 1 if user selects "OK", 0 if "Cancel".
;;
;;  result.start_sample = start sample (vertical- or y- dimension) at which to begin computing
;;      the DC level on a trace-by-trace basis. If the optional keyword "num_samples" is not
;;      supplied, this field will instead return the percent (0-100) of the sample to start at
;;      between the first sample (0%) and the last sample (100%) in the file.
;;
;;  result.output_location = where to output filtered result, either to memory or to a file:
;;
;;      result.output_location.in_memory = 1 if output is to memory.
;;      result.output_location.name = full path and filename of file to output to.
;;
;;  Keywords:
;;
;;  num_samples (optional) = total number of samples (vertical- or y- dimension) in the file
;;      being filtered. Used to provide a slider between the first sample and the last sample
;;      for the user to select a start sample. If not provided, the slider will instead be
;;      between 0% (first sample) and 100% (last sample), necessary when the number of samples
;;      in the file being filtered is not known in advance.
;;
;;  SPECIFY_OUTPUT (optional) = when this keyword is set, the widget will ask the user whether
;;      to save the output to memory or to a file; if the user chooses to output to a file, the
;;      widget will also ask the user where to save the file and what to name it.
;;
;;  Examples:
;;
;;  result = collect_input_dc_removal( num_samples = 1024 )
;;  result = collect_input_dc_removal( num_samples = 1024, /SPECIFY_OUTPUT )
;;  result = collect_input_dc_removal()
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

FUNCTION collect_input_dc_removal, num_samples = num_samples, specify_output = specify_output

    ; Define a default start sample. The deeper you go, the more likely the data is
    ; dominated by DC noise and not meaningful signal:

    IF ( KEYWORD_SET( num_samples ) ) THEN BEGIN
        start_depth = 0.65  ; a coefficient between 0 and 1
        start_sample_default = FIX( num_samples * start_depth ) ; "FIX" function sets result to an integer
    ENDIF ELSE BEGIN
        start_sample_default = 65  ; 65% down from start sample to end sample
    ENDELSE

    ; Create an IDL "widget" to allow user to input a start sample...

    ; Define the widget "Top Level Base" (TLB) and title:

    TLB = WIDGET_AUTO_BASE( title = 'DC removal' )

    ; Create a new base within TLB to frame and contain all of the input fields below
    ; except for the file output field:

    sub_base = WIDGET_BASE( TLB, /col, /frame )

    ; Provide a row to the above widget for setting the start sample using a slider
    ; that goes between the first sample (or O%) and the total number of samples in the data file
    ; (num_samples, or 100%). Provide a reasonable default start sample:

    row_base1 = WIDGET_BASE( sub_base, /row )

    IF ( KEYWORD_SET( num_samples ) ) THEN BEGIN
        start_sample = WIDGET_SSLIDER( row_base1, /auto, title = 'Start sample for calculation of DC-level', $
        min = 1, max = num_samples, value = start_sample_default, uvalue = 'start_sample' )
    ENDIF ELSE BEGIN
        title = 'Start sample for calculation of DC-level'
        start_sample = WIDGET_SSLIDER( row_base1, /auto, title = title, min = 0, max = 100, $
            value = start_sample_default, uvalue = 'start_sample' )
        not_used = WIDGET_LABEL( row_base1, value = '%' )
        row_base1 = WIDGET_BASE( sub_base, /row )
        not_used = WIDGET_LABEL( row_base1, value = ' (0% = first sample; 100% = last sample)' )
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