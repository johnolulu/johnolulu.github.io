;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  get_gpr_depth
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL function returns the depth in meters of a given sample (y-axis) in a RAMAC
;;  ground-penetrating radar (GPR) data file based on the time window (in nanoseconds) of
;;  the data file and the ground velocity (in meters per nanosecond) of radar through
;;  the imaged subsurface medium/media.
;;
;;  NOTE: A "trace" is a single, vertical column of GPR data, representing the signal "traced"
;;  by a radar pulse as it travels from the instrument into the subsurface. Traces are
;;  herein described to be composed of a number of samples (vertical dimension, or y-axis),
;;  and the number of traces are used to describe the horizontal dimension, or x-axis. Note
;;  that in ENVI-terminology, "samples" are counted in the horizontal dimension, in contrast,
;;  and "lines" are counted in the vertical dimension, but we use GPR-terminology here instead
;;  to avoid confusion.
;;
;;  The "time window" and "ground velocity" terminology are common in the GPR literature and
;;  are herein modelled after RAMAC GroundVision software, which similarly requires the user to
;;  enter these parameters in order to convert time to depth for the scale bars that are displayed
;;  to the right and left of the data imagery in GroundVision. The time window is the amount of time
;;  (in nanoseconds) that the radar receiver was set to "listen" for the return pulse after each
;;  radar pulse was released from the transmitting antenna during data acquisition. If the time window
;;  is set to 40 ns, for example, that means an individual radar pulse has a maximum time duration of
;;  20 ns to reach a reflector and 20 more ns to reflect back to the receiver in order to be recorded
;;  in the data file. The bottom of the data file therefore represents a maximum duration of 20 ns for
;;  a time window of 40 ns. The ground velocity represents (in meters per nanosecond) how fast the
;;  radar pulses travelled through the subsurface medium being imaged in the data file. Ground
;;  velocities range from slow (e.g. 0.03 m/ns for fresh water) to fast (e.g. 0.3 m/ns for air)
;;  and the user should refer to a GPR textbook or manual for the proper value related to the media
;;  being imaged. For dry snow on the Greenland ice sheet, for example, an average value of 0.236 m/ns
;;  may suffice if the value has not been measured in a snow pit, based on an average dry snow density
;;  of 0.3 grams per cubic centimeter that has been empirically related to a dry snow permittivity of
;;  1.62 by the following publication:
;;
;;      Mätzler, C. (1996), Microwave permittivity of dry snow. IEEE Transactions on Geoscience
;;      and Remote Sensing. 34(2): 573-581.
;;
;;  Given an average dry snow permittivity of 1.62, an average radar velocity of 0.236 m/ns
;;  can be derived by dividing the speed of light in a vaccuum (0.3 m/ns) by the square root
;;  of this permittivity.
;;
;;  The user may also select the sample of the "first arrival" of the radar pulse reaching
;;  the subsurface: depth computations will start at this sample number (y-axis). Often
;;  in GPR data, there is an obvious lack of backscatter at the top of the file that results
;;  from the empty space that occurred between the antenna and the surface. The first arrival
;;  begins at the point where obvious backscatter begins. The user may also select whether or
;;  not to adjust the first arrival travel time by the "direct wave." The direct wave is the
;;  part of the transmitted energy that travels the shortest distance between the transmitter
;;  and receiver. Due to antenna separation, the wave traveling from the transmitter directly
;;  to the receiver (i.e. the direct wave) is received some time after the actual transmission.
;;  This means that the transmitted pulse has already penetrated the medium a certain distance
;;  before the direct wave is received. The result of this is that the depth scale zero must
;;  be corrected to be accurate. The zero for the depth scale is calculated using the first
;;  arrival value, the antenna separation, and the first arrival adjustment velocity. The
;;  adjustment velocity can be set to any value. Practically however, it can be the ground
;;  velocity, the air velocity (most common), or anything in between depending on the antenna
;;  configuration.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN IDL:
;;
;;  depth = get_gpr_depth( current_sample = current_sample, num_samples = num_samples, $
;;      time_window = time_window, ground_velocity = ground_velocity, first_arrival = first_arrival,
;;      [ direct_wave_adjustment = direct_wave_adjustment, adjustment_velocity = adjustment_velocity,
;;      antenna_separation = antenna_separation ] )
;;
;;  Return Value:
;;
;;  depth (integer) = the depth in meters of the specified sample number (y-axis).
;;
;;  Keywords:
;;
;;  current_sample (integer) = the number of the sample (vertical- or y-dimension) to compute the depth
;;      of, where 0 is the first sample at the top of the file.
;;
;;  num_samples (integer) = total number of samples (vertical- or y- dimension) in the GPR file.
;;
;;  time_window (double) = the amount of time in nanoseconds (10^-9 seconds) that the GPR instrument
;;      was set to "listen" for radar pulses per trace at the time of data acquisition. This
;;      value can be found in the "*.rad" file associated with a particular RAMAC GPR data
;;      file ("*.rd3") in the row labelled "TIMEWINDOW".
;;
;;  ground_velocity (float) = the velocity (in meters per nanosecond) at which radar would travel
;;      through the imaged subsurface medium/media.  Ground velocities range from slow
;;      (e.g. 0.03 m/ns for fresh water) to fast (e.g. 0.3 m/ns for air) and the user should
;;      refer to a GPR textbook or manual for the proper value related to the media being imaged.
;;
;;  first_arrival (integer) = the number of the sample (vertical- or y-dimension) at which the first
;;      radar pulse has reached the subsurface in the data file. This will be the zero-depth point,
;;      without direct wave adjustment.
;;
;;  direct_wave_adjustment (0 = no; 1 = yes) (optional) = a flag to specify whether or not to adjust the
;;      reported depth measurement by the direct wave. If not supplied, the default is 0 (no adjustment).
;;
;;  adjustment_velocity (double) (optional) = the velocity (in meters per nanosecond) at which radar would
;;      travel the direct wave. Most frequently this will be the velocity of air (0.3 m/ns). This only
;;      needs to be supplied if the direct_wave_adjustment is set to 1.
;;
;;  antenna_separation (double) (optional) = the separation in meters between the transmitter and
;;      receiver antennae. This value can be found in the "*.rad" file associated with a particular
;;      RAMAC GPR data file ("*.rd3") in the row labelled "ANTENNA SEPARATION". This keyword only
;;      needs to be supplied if the direct_wave_adjustment is set to 1.
;;
;;  Example:
;;
;;  depth = get_gpr_depth( current_sample = 212, num_samples = 1024, time_window = 42.5, $
;;      ground_velocity = 0.236, first_arrival = 0 )
;;
;;  [NOTE: depth should be 1.0382617 meters in the above example.]
;;
;;  depth = get_gpr_depth( current_sample = 212, num_samples = 1024, time_window = 42.5, $
;;   ground_velocity = 0.236, first_arrival = 100, direct_wave_adjustment = 1, $
;;   adjustment_velocity = 0.3, antenna_separation = 0.1 )
;;
;;  [NOTE: depth should be 0.58784896 meters in the above example.]
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

FUNCTION get_gpr_depth, current_sample = current_sample, num_samples = num_samples, time_window = time_window, $
    ground_velocity = ground_velocity, first_arrival = first_arrival, direct_wave_adjustment = direct_wave_adjustment, $
    adjustment_velocity = adjustment_velocity, antenna_separation = antenna_separation

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

    IF ( N_ELEMENTS( current_sample ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The current sample (e.g. current_sample=500) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( num_samples ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The total number of samples (e.g. num_samples=1024) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( time_window ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The time window (e.g. time_window=42.5) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( ground_velocity ) EQ 0 ) THEN BEGIN
       MESSAGE, "ERROR!: The ground velocity (e.g. ground_velocity=0.236) was not supplied."
    ENDIF

    IF ( N_ELEMENTS( first_arrival ) EQ 0 ) THEN BEGIN
        first_arrival = 0
    ENDIF

    ; To make a direct wave adjustment, it is necessary for the user to supply an adjustment
    ; velocity (ns) and antenna separation (m):

    IF ( N_ELEMENTS( direct_wave_adjustment ) NE 0 ) THEN BEGIN
        IF ( direct_wave_adjustment EQ 1 ) THEN BEGIN

            IF ( N_ELEMENTS( adjustment_velocity ) EQ 0 ) THEN BEGIN
                MESSAGE, "ERROR!: The adjustment velocity (e.g. adjustment_velocity=0.300) was not supplied."
            ENDIF

            IF ( N_ELEMENTS( antenna_separation ) EQ 0 ) THEN BEGIN
                MESSAGE, "ERROR!: The antenna separation (e.g. antenna_separation=4.0) was not supplied."
            ENDIF

       ENDIF
    ENDIF ELSE BEGIN
       direct_wave_adjustment = 0
    ENDELSE

    ; Convert the time window, ground velocity, adjustment velocity, and antenna separation to the proper
    ; data types (float or double) in case they aren't already:

    time_window = DOUBLE( time_window )
    ground_velocity = FLOAT( ground_velocity )

    IF ( N_ELEMENTS( adjustment_velocity ) NE 0 ) THEN BEGIN
        adjustment_velocity = FLOAT( adjustment_velocity )
    ENDIF

    IF ( N_ELEMENTS( antenna_adjustment ) NE 0 ) THEN BEGIN
        antenna_adjustment = DOUBLE( antenna_adjustment )
    ENDIF

    ; The "time_window" is the two-way travel time (in nanoseconds) of the radar pulse; in
    ; other words, the amount of time it took to leave the antenna, reach the reflector, and
    ; reach the receiver. In order to derive the one-way travel time, therefore, we must
    ; first divide by 2 below in order to calculate the time per sample:

    time_per_sample = ( time_window / 2 ) / num_samples

    ; Use the time per sample (ns) to compute the depth per sample (m) by multiplying by the
    ; ground velocity (m/ns):

    depth_per_sample = time_per_sample * ground_velocity

    ; Adjust the current sample according to the first arrival sample:

    IF ( current_sample LT first_arrival ) THEN BEGIN

        adjusted_current_sample = 0

    ENDIF ELSE BEGIN

        adjusted_current_sample = current_sample - first_arrival

    ENDELSE

    ; Compute the depth of the current sample either with or without a direct wave adjustment:

    IF ( direct_wave_adjustment EQ 1 ) THEN BEGIN

        ; The antenna separation (m) divided by the adjustment velocity (m/ns) gives the
        ; direct wave duration (ns) that needs to be added to the current sample to adjust
        ; the reported depth:

        direct_wave_duration = antenna_separation / adjustment_velocity

        ; During the direct wave duration, the first arrival will have travelled two ways:
        ; from the transmitter to a reflector and from the reflector to the receiver.
        ; Therefore the duration that should be used to adjust the depth of the radar
        ; data in one direction should be half of the direct wave duration:

        adjustment_duration = direct_wave_duration / 2

        ; Convert the adjustment duration (ns) to a number of samples that will be
        ; added to or subtracted from the current sample to adjust the current depth calculation:

        direct_wave_samples = adjustment_duration / time_per_sample

        ; Adjust the current sample number by the number of direct wave samples:

        IF ( adjustment_velocity GT ground_velocity ) THEN BEGIN

            IF ( adjusted_current_sample NE 0 ) THEN BEGIN

                adjusted_current_sample += direct_wave_samples

            ENDIF

        ENDIF ELSE BEGIN

            adjusted_current_sample += direct_wave_samples

        ENDELSE

        ; Compute the depth of the adjusted current sample:

        current_depth = depth_per_sample * adjusted_current_sample

        ; If the current depth is negative, set it to zero:

        IF ( current_depth LT 0 ) THEN BEGIN

            current_depth = DOUBLE( 0.00 )

        ENDIF

    ENDIF ELSE BEGIN

        current_depth = depth_per_sample * adjusted_current_sample

    ENDELSE

    ; Return the current depth:

    RETURN, current_depth

END