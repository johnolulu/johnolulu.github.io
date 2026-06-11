;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  collect_input_time_varying_gain
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL function is called by or for the "Time-Varying Gain" ground-penetrating
;;  radar (GPR) image-processing filter (time_varying_gain.pro) to collect user
;;  input. It displays a window for the user to enter the following information:
;;
;;  1. Ask the user for the "time window" of the GPR data being filtered. The time window
;;     is the amount of time that the GPR instrument was set to "listen" for radar pulses
;;     per trace at the time of data acquisition. This value is used to compute the gain
;;     function and can be found in the "*.rad" file associated with a particular RAMAC GPR
;;     data file ("*.rd3"), labelled "TIMEWINDOW" and reported in nanoseconds (10^-9 seconds).
;;
;;  2. Ask the user for the start sample at which to begin applying the time-varying
;;     gain, providing a reasonable default as GroundVision does. The user may prefer to set
;;     the start sample below any outstanding features within the trace. The time-varying gain
;;     will be applied to all samples between the selected start sample and the last sample of
;;     each trace.
;;
;;  3. Ask the user for linear (A) and exponential (B) gain factors to be applied in the
;;     filter. Typical values range anywhere between 0 and ~1000 for linear gain and 0 and ~150
;;     for exponential gain. Increasing the exponential gain has the effect of dramatically
;;     amplifying the gain of the lower portion of the trace, which may be important if there
;;     are features you are looking for in the deeper portion of the GPR data.
;;
;;  NOTE: A "trace" is a single, vertical column of GPR data, representing the signal "traced"
;;  by a radar pulse as it travels from the instrument into the subsurface.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  result = collect_input_time_varying_gain( [num_samples = num_samples], [/SPECIFY_OUTPUT] )
;;
;;  Return Value:
;;
;;  result.accept = 1 if user selects "OK", 0 if "Cancel".
;;
;;  result.time_window = amount of time (ns) that the GPR instrument was set to "listen" for
;;      radar pulses per trace at the time of data acquisition.
;;
;;  result.start_sample = start sample (vertical- or y- dimension) at which to begin applying
;;      the time-varying gain on a trace-by-trace basis. If the optional keyword "num_samples"
;;      is not supplied, this field will instead return the percent (0-100) of the sample to
;;      start at between the first sample (0%) and the last sample (100%) in the file.
;;
;;  result.linear_gain = linear gain factor, between 0 and 1000.
;;
;;  result.exponential_gain = exponential gain factor, between 0 and 1000.
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
;;      widget will also ask the user where to save the file and what to name it. This would not
;;   be set, for example, if using the function programmatically to collect input parameters
;;   for several filters before asking where to save the output file(s) separately.
;;
;;  Examples:
;;
;;  result = collect_input_time_varying_gain( num_samples = 1024 )
;;  result = collect_input_time_varying_gain( num_samples = 1024, /SPECIFY_OUTPUT )
;;  result = collect_input_time_varying_gain()
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

FUNCTION collect_input_time_varying_gain, num_samples = num_samples, specify_output = specify_output

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                  ;;
    ;;  Step 1:                                         ;;
    ;;                                                  ;;
    ;;  Ask user for the time window of the data file.  ;;
    ;;                                                  ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Define the widget "Top Level Base" (TLB) and title:

    TLB = WIDGET_AUTO_BASE( title = 'Time-Varying Gain' )

    ; Create a new base within TLB to frame and contain all of the input fields below
    ; except for the file output field:

    sub_base = WIDGET_BASE( TLB, /col, /frame )

    ; Provide a row to the above widget for explaining where the user can find the
    ; the data file's "time window":

    row_base1 = WIDGET_BASE( sub_base, /row )

    IF ( KEYWORD_SET( num_samples ) ) THEN BEGIN
        time_window_explanation = 'This value can be found in the "*.rad" file associated with ' + $
            'this RAMAC GPR data file:'
    ENDIF ELSE BEGIN
        time_window_explanation = 'This value can be found in the "*.rad" files associated with ' + $
            'these RAMAC GPR data:'
    ENDELSE

    not_used = WIDGET_LABEL( row_base1, value = time_window_explanation )

    ; Provide another row to the widget for setting the time window in nanoseconds (ns).
    ; The data type is floating-point ("dt=4"):

    row_base2 = WIDGET_BASE( sub_base, /row )
    time_window = WIDGET_PARAM( row_base2, /auto_manage, dt = 4, prompt = 'Time window (ns): ', $
        uvalue = 'time_window' )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                   ;;
    ;;  Step 2:                                          ;;
    ;;                                                   ;;
    ;;  Ask user for the start sample to begin applying  ;;
    ;;  the filter at.                                   ;;
    ;;                                                   ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Provide another row to the widget defining the start sample:

    row_base3 = WIDGET_BASE( sub_base, /row )
    filter_explanation1 = 'Specifies the point on the trace from which the following gain ' + $
                          'function is applied:'
    not_used = WIDGET_LABEL( row_base3, value = filter_explanation1 )

    ; Provide another row to the widget defining the time-varying gain equation:

    row_base4 = WIDGET_BASE( sub_base, /row )
    filter_explanation2 = '(A * time) + e^(B * time):'
    not_used = WIDGET_LABEL( row_base4, value = filter_explanation2 )

    ; Provide another row to the widget for setting the start sample using a slider
    ; that goes between the first sample (or 0%) and the total number of samples in the data file
    ; (num_samples, or 100%). Provide a reasonable default start sample:

    row_base5 = WIDGET_BASE( sub_base, /row )

    ; Define a default start sample. The deeper you go, the more the data need compensation
    ; for amplitude loss due to spreading and attenuation:

    IF ( KEYWORD_SET( num_samples ) ) THEN BEGIN
        start_depth = 0.5  ; a coefficient between 0 and 1
        start_sample_default = FIX( num_samples * start_depth ) ; "FIX" function sets result to an integer
    ENDIF ELSE BEGIN
        start_sample_default = 50 ; 50% down from start sample to end sample
    ENDELSE

    IF ( KEYWORD_SET( num_samples ) ) THEN BEGIN
        start_sample = WIDGET_SSLIDER( row_base5, /auto, title = 'Start sample', min = 1, max = num_samples, $
            value = start_sample_default, uvalue = 'start_sample' )
    ENDIF ELSE BEGIN
        title = '0% = first sample; 100% = last sample'
        start_sample = WIDGET_SSLIDER( row_base5, /auto, title = title, min = 0, max = 100, $
            value = start_sample_default, uvalue = 'start_sample' )
        not_used = WIDGET_LABEL( row_base5, value = '%' )
    ENDELSE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                                     ;;
    ;;  Step 3:                                            ;;
    ;;                                                     ;;
    ;;  Ask user for linear and exponential gain factors.  ;;
    ;;                                                     ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Provide another row to the widget for setting the linear gain factor. This is also a
    ; slider, between 0 and 1000 and defaulting at 40 as GroundVision software does:

    row_base6 = WIDGET_BASE( sub_base, /row )

    linear_gain = WIDGET_SSLIDER( row_base6, /auto, title = 'Linear gain', min = 0, max = 1000, value = 40, $
        uvalue = 'linear_gain')

    ; Provide another row to the widget for setting the exponential gain factor. This is also a
    ; slider, between 0 and 1000 and defaulting at 10 as GroundVision software does:

    row_base7 = WIDGET_BASE( sub_base, /row )
    exponential_gain = WIDGET_SSLIDER( row_base7, /auto, title = 'Exponential gain', min = 0, max = 1000, $
        value = 10, uvalue = 'exponential_gain' )

    ; Ask the user whether to output the result to a file or to memory:

    IF ( KEYWORD_SET( specify_output ) ) THEN BEGIN
        output_location = WIDGET_OUTFM( TLB, /auto, uvalue = 'output_location', xsize = 60, /frame )
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