### Overview
This is a program that automates Free Past Performance Sheet (FreePPs or "PPs") file renaming and html generation for use on TVG2 & 3. The purpose of this program is to eliminate the possibility of human error when renaming files and editing html.

The two required files should be located in the same dir
*config.ini* (Contains all settings)
*DB.json* (Database that contains track information from previous days; old data is automatically expunged after 33 days of age. This file can be deleted or moved in order to run a clean


### Example Use
Save new Past Performance Sheet files to the same directory as the PPS2HMTL program.
When run, the program will rename all unformatted PDF files in that same directory.

 
The program reads from DB.json to build a list of tracks that are active today and in the future. These are all written to html.txt and categorized into groups. Copy and paste each section to be used in the normal PPs update proccess.


### Settings
The program settings are saved in config.ini   This primarily serves to store all track codes and their corresponding track name. They need to be organized under the track type but alphabetical order does not matter. If a PDF file does not match any track in the config file; the program will exit and prompt to add the track and retry. 

As every track is added to the config file, this message will become less common.
rack names may include spaces or dashes. If a track name includes spaces, *do not* substitute them with underscores.


### Warnings & Troubleshooting
PPS2HTML must be run inside the same directory as config.ini. It only reads PDF files of adequate filename matching. If a file is being ignored; Check that it matches the correct file naming pattern (see table above) and ensure that the correct file was downloaded. Manual file renaming will note be included in HTML Output.
 
Open PDF files cannot be renamed. You will receive the following error:
> "There was a problem renaming the [X] file. Permissions/FileInUse


### Dev Brief
- Reads each file in the same directory as exe
- Tries to rename each file
- Generates html.txt based on new tracks and files run through the program previously


### Detailed Execution
- Startup
- Load the config file and check that it loaded completely
- Clear the old html.txt ;added some filesize checking for added safety
- Import existing track DB file
- Read each pdf file in the same directory and save it to the Track DB if it matches the expected filename pattern. See table
- Is this track Aus? They all have "ppAB" in the filename; EX: DOOppAB0527.pdf
- Is this track New Zealand? They all have "NZpp" in the filename
- NZ and Aus files get exported to txt, so we can read the trackname
- Read the trackname out of the Converted Text, after a short rest
- Is this track Japan? They all have "Japan" in the filename
- Is this track from Simo Central? They all have "_INTER_IRE." in the filename; EX: 20140526DR(D)_INTER.pdf
- If [Key]_TLA has no associated track; tell user and exit
- Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur instead on Thur,Fri,Sat
- Export Each Track type to HTML.txt; also handles renaming files
- Aus, NZ, and Japan must be handled explicitly because they don't follow SimoCentral rules
- Export all the tracks again in basic HTML format if user specified TVG2HTML = 1 in their config file
- Export all the tracks again in NON-DRUPAL format if user specified OldTVG3HTML = 1 in their config file
- Export all the tracks again in NON-DRUPAL Basic format if user specified OldTVG2HTML = 1 in their config file


### Technical Details
Latest version is 2.4.1 (04.14.15)
