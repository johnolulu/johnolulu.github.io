;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  open_ramac_gpr_file
;;
;;  Version 1.00
;;  John Maurer (john.maurer@colorado.edu)
;;  ©2005-2006 University of Colorado
;;
;;  This IDL procedure can be run in ENVI to automatically and properly import a
;;  Mala Geoscience RAMAC round-penetrating radar (GPR) data file for viewing in ENVI
;;  (under ENVI's "File -> Open External File" file menu). The dimensions of the data
;;  file are read from an associated RAMAC "*.rad" header file and the data are transposed
;;  (rotated) so that they are displayed properly. The data file is opened in ENVI in memory
;;  and given an informative description in its ENVI header file so that if the rotated file
;;  is saved to disk this information can be referred to later. Having a procedure such
;;  as this one, though, prevents the need for saving an alternate format of the GPR data just
;;  for ENVI (and thereby doubling your space requirements) since you can view it directly
;;  from memory.
;;
;;  What follows are step-by-step instructions for opening a Mala Geoscience RAMAC GPR data
;;  file (*.rd3) in ENVI manually for the first time. These are essentially the steps that
;;  the current procedure enables automatically for the user:
;;
;;      1. Determine data dimensions:
;;
;;         Open the *.rad file associated with the particular GPR data file that you wish to view in
;;         order to determine its dimensions:
;;
;;       a.) Determine the number of pixels in the vertical/y-axis dimension of the data.
;;           This is labelled on the first line of the *.rad file as the number of "samples".
;;           For example:
;;
;;              SAMPLES:1024
;;
;;           This will be used to identify the number of "samples" in ENVI, which confusingly
;;           represents the horizontal/x-axis dimension of the data in ENVI. (The data will
;;           be flipped vertically in ENVI when we first open the file and will subsequently
;;           require a rotation within ENVI prior to usage.)
;;
;;       b.) Determine the number of pixels in the horizontal/x-axis dimension of the data.
;;           This is labelled on the 22nd line of the *.rad file as the number of the "last
;;           trace". For example:
;;
;;              LAST TRACE:37745
;;
;;           In RAMAC GPR terminology, each line of data in the horizontal dimension is
;;           considered a single "trace" of data since it represents the data traced by radar
;;           pulses for that particular distance along the x-axis. The last trace represents
;;           the total number of pixels in the horizontal dimension and will be used to
;;           identify the number of "lines" in ENVI, which confusingly represents the
;;           vertical/y-axis dimension of the data in ENVI. (Again, the data will be flipped
;;           vertically in ENVI when we first open the file and will therefore require a
;;           rotation within ENVI prior to usage.)
;;
;;   2. Open the file in ENVI:
;;
;;      Open ENVI and select "Open Image File" from the "File" pull-down menu. Select the
;;      particular RAMAC GPR data file (*.rd3) that you wish to open in ENVI. A "Header Info"
;;      window will appear for you to input various characteristics about the data so that ENVI
;;      knows how to properly display it. Using the dimensions of the data determined in step 1
;;      above, fill in each of the fields as so:
;;
;;       a.) Samples
;;
;;           Enter the number of Samples determined from the *.rad file in step 1 above (e.g.
;;           1024).
;;
;;       b.) Lines
;;
;;           Enter the number of the "last trace" determined from the *.rad file in step 1
;;           above (e.g. 37745).
;;
;;       c.) Bands
;;
;;           Enter "1". RAMAC GPR data only consist of a single band of data.
;;
;;       d.) Offset
;;
;;           Enter "0". There is no header information that precedes/offsets the RAMAC GPR
;;           data.
;;
;;       e.) xstart
;;
;;           Use the default of "1". This will define the left-most column of data as
;;           beginning at 1.
;;
;;       f.) ystart
;;
;;           Use the default of "1". This will define the upper-most row of data as beginning
;;           at 1.
;;
;;       g.) Data Type
;;
;;           Select "Integer". NOTE: It is incorrect to select "Unsigned Integer" since the
;;           RAMAC GPR data files can contain negative values and these will be incorrectly
;;           represented as very large positive values if you select "Unsigned Integer" as
;;           the data type.
;;
;;       h.) Byte Order
;;
;;           If the data were collected on a computer running the Windows operating system,
;;           select "Host (Intel)" byte order. If the data were collected on a computer
;;           running a Unix-based operating system (ex. SGI or Sun operating systems), select
;;           "Network (IEEE)" byte order. If you have selected the incorrect byte order, the
;;           data will obviously appear incorrect when displayed.
;;
;;       i.) File Type
;;
;;           Select the default of "ENVI Standard".
;;
;;       j.) Interleave
;;
;;           Select the default of "BSQ". Because the data contain only a single band, the
;;           band interleave that you select is irrelevant and any option will work equally
;;           well. NOTE: "BSQ" stands for band-sequential, "BIL" stands for band interleaved
;;           by line (y-dimension), and "BIP" stands for band interleaved by pixel
;;           (x-dimension).
;;
;;       k.) Description
;;
;;           In the text box at the bottom of the window you can enter any description of the
;;           data file that you like. The default description is "File imported into ENVI."
;;           If desired, enter informative details about the data file such as, "Mala
;;           Geoscience RAMAC 1,000 MHz GPR data file from the NASA-U Greenland Climate
;;           Network (GC-Net) automatic weather station (AWS) collected on June 1, 2003."
;;
;;      Select "OK" after entering the above selections and the file will automatically appear in
;;      a new "Available Bands List" window. Select the file from this window, use the defualt
;;      display mode of "Gray Scale" (the data are not in color), and then select "Load Band" to
;;      load the data for display. If any of the above fields were accidentally entered
;;      incorrectly and the data are displayed incorrectly, you can always right-click on the
;;      data file in the "Available Bands List" window and select "Edit Header..." to go back to
;;      the "Header Info" window and edit the appropriate field.
;;
;;      NOTE: An ENVI header file (*.hdr) will now be saved in the same directory as the original
;;      data file (*.rd3). This file contains all of the information entered above so that the
;;      next time you open the file in ENVI, it will automatically pop into the "Available Bands
;;      List" window without requiring to re-enter all of the above information in the "Header
;;      Info" window. If the ENVI header file is ever removed or moved to a different directory
;;      from the data file, ENVI will require you to re-enter all of the above information the
;;      next time you attempt to open the data file in ENVI.
;;
;;   3. Rotate the file in ENVI:
;;
;;      You will notice that the GPR data are flipped vertically when you first open them for
;;      display in ENVI after completing steps 1-2 above. The next step is to rotate the data so
;;      that they are oriented properly in ENVI. To do this, select "Rotate/Flip Data" from the
;;      main ENVI "Basic Tools" menu at the top of the screen. In the "Rotation Input File"
;;      window that pops-up, select the GPR data file that you wish to rotate and select "OK".
;;
;;      NOTE: If you are subsetting the original GPR data, you can also choose a "Spatial Subset"
;;      before selecting "OK" to only apply and output the rotation on a small section of the
;;      original data file. This may be desired, for example, if the original data file contains
;;      all of the transects that are part of a larger gridded survey and you wish to split the
;;      data file into its individual transect components for convenience and quickness during
;;      post-processing.
;;
;;      In the "Rotation Parameters" window that follows, press the toggle button next to
;;      "Transpose" to change the option to "Yes". Use the default of zero (0) for the rotation
;;      "Angle." Select to "Output File to" a file and then select an output filename (e.g.
;;      "*_ENVI.bin") if you wish to save the rotated data. use the default "Background Value" of
;;      0.00. The image rotation will take some time to complete before the new, rotated file
;;      will automatically appear in the "Available Bands List" for display. NOTE: It is
;;      incorrect to select a rotation angle of 90 degrees and no transpose: although this
;;      will rotate the data into the proper orientation, it will make the first sample of the
;;      image file be the last sample of the actual data.
;;
;;   4. The file is now displayed correctly in ENVI and ready for processing.
;;
;;  -------------------------------------------------------------------------------------
;;  TO USE IN ENVI: After saving this procedure in the ENVI "save_add" directory, look for
;;  the following line in ENVI's main menu configuration file (envi.men) located in ENVI's
;;  "menu" directory:
;;
;;      1 {Open External File} {separator}
;;
;;  Add the following lines beneath the above line prior to opening ENVI.
;;
;;        2 {GPR}
;;          3 {RAMAC} {not used} {open_ramac_gpr_file}
;;
;;  This procedure can then be run from the pull-down menu labelled "Open External File" under
;;  the main "File" menu option on ENVI's main menu bar. Along with the existing external file
;;  formats, at the top you will now see "GPR" as a category and "RAMAC" as a type of GPR file.
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

PRO OPEN_RAMAC_GPR_FILE, event

    ; Instruct the IDL compiler to strictly enforce square brackets for dereferencing variables
    ; rather than parentheses so that functions can be identified by parentheses. Also instruct
    ; IDL to assume that lexical integer constants default to the 32-bit type rather than the
    ; usual default of 16-bit integers:

    COMPILE_OPT idl2

    ; Ask the user to select a RAMAC GPR data file:

    gpr_file = ENVI_PICKFILE( title = "Select a RAMAC GPR file to open:", filter = "*.rd3" )

    ; If the user pressed "Cancel" then exit:

    IF ( gpr_file[0] EQ '' ) THEN RETURN

    ; Get the directory of the input file so that we can look for the associated header file (*.rad)
    ; in the same directory:

    gpr_directory = FILE_DIRNAME( gpr_file, /MARK_DIRECTORY )

    ; Get the basename of the input file so that we can look for the associated header file (*.rad)
    ; with the same basename but a different suffix (*.rad instead of *.rd3):

    gpr_filename = FILE_BASENAME( gpr_file, '.rd3' )

    ; Put together the default directory and filename to look for the associated header file (*.rad):

    header_file = gpr_directory + gpr_filename + '.rad'

    ; Try to open the default location of the header file and trap any error in case the
    ; file does not exist in this location:

    OPENR, lun, header_file, /GET_LUN, ERROR = error

    ; If the file cannot be opened in the default location, ask the user where it is:

    IF ( ERROR NE 0 ) THEN BEGIN

        header_file = ENVI_PICKFILE( title = "Select associated RAMAC header file (*.rad):", filter = "*.rad" )

        ; If the user pressed "Cancel" then exit:

        IF ( header_file[0] EQ '' ) THEN RETURN

        ; Open the header file into IDL:

        OPENR, lun, header_file, /GET_LUN

    ENDIF

    ; Create a string array to read the header file into. A RAMAC "*.rad" header file has
    ; one column of information with 38 rows each containing a single "PARAMETER:VALUE"
    ; string (e.g. "SAMPLES:1024"):

    header_file_contents = STRARR( 38 )

    ; Read the "*.rad" header file contents into the string array as free-format ASCII:

    READF, lun, header_file_contents
    FREE_LUN, lun

    ; Get information from the header array about the associated data file. Note that the number
    ; of samples will represent the x-dimension and the number of traces will represent the y-dimension
    ; for the raw, unrotated GPR data file. The data need to be rotated (transposed, see below) in ENVI,
    ; though, in order for the file to be displayed correctly: so these dimensions will be reversed
    ; for the rotated/transposed data file (i.e. num_samples will be the y-dimension and num_traces
    ; will be the x-dimension). The antenna frequency and time window are simply captured so that
    ; they can be recorded in the ENVI header file description for future reference:

    num_samples = header_file_contents[ 0 ]
    num_samples = FIX( STRMID( num_samples, 8 ) )

    num_traces = header_file_contents[ 22 ]
    num_traces = FIX( STRMID( num_traces, 11 ) )

    antenna_frequency = header_file_contents[ 14 ]
    antenna_frequency = STRMID( antenna_frequency, 9 )

    time_window = header_file_contents [ 18 ] ; two-way travel time (TWT) in nanoseconds (ns)
    time_window = DOUBLE( STRMID( time_window, 11 ) )

    ; Create a suitable description for the ENVI header file that will result:

    file_description = 'Mala Geoscience RAMAC(tm) ground penetrating radar (GPR) data file. ' + $
        'For further instrument details, see "http://www.malags.com/hardware/gpr.php". ' + $
        'Original filename: "' + gpr_filename + '.rd3".' + ' Antenna frequency: ' + $
        antenna_frequency + '. Two-way radar travel time window: ' + $
        STRCOMPRESS( STRING( time_window ), /REMOVE_ALL ) + ' ns.' + ' Rotated in ENVI to ' + $
        'be properly displayed: Basic Tools -> Rotate/Flip Data -> Angle: 0.0, Transpose: Yes.' + $
        ' For other characteristics of this data file see the associated "' + gpr_filename + $
        '.rad" RAMAC header file and "' + gpr_filename + '.cor" GPS coordinate file.'

    ; Open the GPR data into ENVI:

    ENVI_SETUP_HEAD, fname = gpr_file, ns = num_samples, nl = num_traces, nb = 1, data_type = 2, interleave = 0, $
       offset = 0, descrip = file_description, r_fid = unrotated_fid, /OPEN

    ; Define the dimensions of the GPR data file and then transpose the image:

    unrotated_dims = [ -1, 0, num_samples - 1, 0, num_traces - 1 ]

    ENVI_DOIT, 'ROTATE_DOIT', fid = unrotated_fid, pos = 0, dims = unrotated_dims, r_fid = rotated_fid, $
        rot_type = 0, out_bname = "Rotated (" + gpr_filename + ".rd3)", /TRANSPOSE, /IN_MEMORY

    ; Remove the unrotated data file from ENVI now that the rotated image is there:

    ENVI_FILE_MNG, id = unrotated_fid, /REMOVE

    ; Get the dimensions and data for the trasposed image:

    rotated_dims = [ -1, 0, num_traces - 1, 0, num_samples - 1 ]
    rotated_data = ENVI_GET_DATA( fid = rotated_fid, dims = rotated_dims, pos = 0 )

    ; Enter the rotated data into ENVI memory, providing an informative header (ENVI_DOIT does not
    ; allow us to specify a header description in the originally rotated data so we add one this way):

    ENVI_ENTER_DATA, rotated_data, bnames = [ "Rotated (" + gpr_filename + ".rd3)" ], descrip = file_description

    ; Remove the original rotated data file form ENVI memory now that a new one has been
    ; entered that has an informative header file:

    ENVI_FILE_MNG, id = rotated_fid, /REMOVE

END