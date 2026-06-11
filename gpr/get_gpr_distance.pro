;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  get_gpr_distance
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL function returns the distance in meters of a given trace (x-axis) in a RAMAC
;;  ground-penetrating radar (GPR) data file based on the given start and end distance
;;  of the data file provided by the user.
;;
;;  NOTE: A "trace" is a single, vertical column of GPR data, representing the signal "traced"
;;  by a radar pulse as it travels from the instrument into the subsurface. Traces are
;;  herein described to be composed of a number of samples (vertical dimension, or y-axis),
;;  and the number of traces are used to describe the horizontal dimension, or x-axis. Note
;;  that in ENVI-terminology, "samples" are counted in the horizontal dimension, in contrast,
;;  and "lines" are counted in the vertical dimension, but we use GPR-terminology here instead
;;  to avoid confusion.
;;
;;  The distance of a given trace is computed according to the following equation:
;;
;;      1. total_distance = end_distance - start_distance
;;      2. depth_per_trace = total_distance / num_traces
;;      3. current_distance = depth_per_trace * current_trace
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  distance = get_gpr_distance( current_trace = current_trace, num_traces = num_traces, $
;;      start_distance = start_distance, end_distance = end_distance )
;;
;;  Return Value:
;;
;;  distance = the distance in meters of the specified trace number (x-axis).
;;
;;  Keywords:
;;
;;  current_trace = the number of the trace (horizontal- or x-dimension) to compute the distance
;;      of, where 0 is the first trace at the left of the file.
;;
;;  num_traces = total number of traces (horizontal- or x- dimension) in the GPR file.
;;
;;  start_distance = the distance of the first (left-most) trace in the GPR file. In most cases,
;;      this will probably be 0 meters.
;;
;;  end_distance = the distance of the last (right-most) trace in the GPR file.
;;
;;  Example:
;;
;;  distance = get_gpr_distance( current_trace = 500, num_traces = 1000, start_distance = 0, $
;;      end_distance = 100 )
;;
;;  [NOTE: distance should be 50.0000 meters in the above example.]
;;
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

FUNCTION get_gpr_distance, current_trace = current_trace, num_traces = num_traces, $
    start_distance = start_distance, end_distance = end_distance

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

    IF ( N_ELEMENTS( current_trace ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The current trace (e.g. current_trace=500) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( num_traces ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The total number of traces (e.g. num_traces=1000) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( start_distance ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The start distance (e.g. start_distance=0) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( end_distance ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The end distance (e.g. end_distance=100) was not supplied."
    ENDIF

    ; Convert start and end distances to floating point values in case they aren't already:

    start_distance = FLOAT( start_distance )
    end_distance = FLOAT( end_distance )

    ; Make sure the end distance is greater than the start distance:

    IF ( end_distance LT start_distance ) THEN BEGIN

        MESSAGE, "ERROR!: The end distance cannot be less than the start distance."

    ENDIF

    ; Compute the distance of the current trace:

    total_distance = end_distance - start_distance

    distance_per_trace = total_distance / num_traces

    current_distance = distance_per_trace * current_trace

    ; Return the current distance:

    RETURN, current_distance

END