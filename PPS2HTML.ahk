;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Renames FreePPs pdf files; then generates html for use with the normal FreePPs process.



;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
StartUp()
Version = Version 2.0

;Dependencies
#include inireadwrite.ahk

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Clear the old html.txt ;added some filesize checking for added safety
g_HMTLFile = %A_ScriptDir%\html.txt
	IfExist, %g_HMTLFile%
	{
	FileGetSize, HTMLSize , %g_HMTLFile%, M
		If (HTMLSize <= 1) {
		FileDelete, %g_HMTLFile%
		}
	
	}



;Get Tomorrows name to be used in HTML
g_WeekdayName:= %A_Now%
g_WeekdayName+=1, d
FormatTime, g_WeekdayName,%g_WeekdayName%, dddd


;Load the config file and check that it loaded the last line
settings = %A_ScriptDir%\config.ini
Fn_InitializeIni(settings)
Fn_LoadIni(settings)
If (Ini_Loaded != 1)
{
Msgbox, Citizen! There was a problem reading the config.ini file. PPS2HTML will quit for your protection. (Copy a working replacement config.ini file to the same directory as PPS2HTML)
ExitApp
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; File Renaming
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/



;### AUSTRALIA--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track Aus? They all have "ppAB" in the name
	regexmatch(A_LoopFileName, "ppAB(\d\d)(\d\d)\.", RE_Aus)
	If (RE_Aus1 != "") {
	FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\Australia20%Options_Year%%RE_Aus1%%RE_Aus2%-li.pdf, 1
		If Errorlevel {
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions/FileInUse
		}
	}
}




;### Experimental All Simo Central Renaming----------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track from Simo Central? They all have "_INTER_IRE." in the name; EX: 20140526DR(D)_INTER.pdf
	regexmatch(A_LoopFileName, "(\d\d\d\d)(\d\d)(\d\d)(\D+)\(D\)_INTER", RE_SimoCentralFile)
	If (RE_SimoCentralFile1 != "") {
	TrackTLA := RE_SimoCentralFile4
	Ini_Key := Fn_FindTrackIniKey(TrackTLA)
	TrackName := %Ini_Key%_%TrackTLA%
	StringReplace, TrackName, TrackName, %A_SPACE%, _, All
	
		If (TrackName = "") {
		Msgbox, There was no corresponding track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this: `n[Key]`n %TrackTLA%=Track Name
		ExitApp
		}
	
	FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\%TrackName%%RE_SimoCentralFile1%%RE_SimoCentralFile2%%RE_SimoCentralFile3%-li.pdf, 1
		If (Errorlevel) {
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions\FileInUse
		}
	}
}



;Ask user to confirm weekday name
InputBox, g_WeekdayName , Weekday name, %A_Tab%%A_Space%%A_Space%%A_Space%%A_Space%%A_Space% %Version%, , 180, 120, X, Y, , , %g_WeekdayName%




;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/





;Label TVG3 Section of HTML
FileAppend,
(
-=TVG 3=---------------------
), %A_ScriptDir%\html.txt
InsertBlank(void)

;Label Australia Section of HTML
FileAppend,
(

      Australia

), %A_ScriptDir%\html.txt


InsertBlank(void)


;Loop for all Australia pdf files
Loop, %A_ScriptDir%\*.pdf
{

StringTrimRight, Trackname, A_LoopFileName, 13
	IfInString, A_LoopFileName, Austr
	{
	g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
	FileAppend,
	(
	<a href="/forms/%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />
	
	), %A_ScriptDir%\html.txt
	}

}


InsertBlank(void)
InsertBlank(void)


;Label Australia Section of HTML
FileAppend,
(

      Great Britain\Ireland

), %A_ScriptDir%\html.txt

InsertBlank(void)


;Loop for all GB pdf files
Loop, %A_ScriptDir%\*.pdf
{
IfInString, A_LoopFileName, Aus
	{
	Continue
	}
StringTrimRight, Trackname, A_LoopFileName, 15
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
;take space out of FileName and put into a new variable so that the html link will match the no space filename
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
FileAppend,
(
<a href="/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />

), %A_ScriptDir%\html.txt

}

;Add trailing <br>
FileAppend,
(
<br \>
), %A_ScriptDir%\html.txt


;Insert Blank area for separation between TVG3 and TVG2
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)

;Label for TVG2
FileAppend, -=TVG 2=---------------------`n, %A_ScriptDir%\html.txt
FileAppend,`n      Australia`n, %A_ScriptDir%\html.txt


InsertBlank(void)





Loop, %A_ScriptDir%\*.pdf {

StringTrimRight, Trackname, A_LoopFileName, 13
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
	IfInString, A_LoopFileName, Australia
	{
	g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
	FileAppend,<a href="https://www.tvg.com/forms/%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />`n, %A_ScriptDir%\html.txt
	}
}


InsertBlank(void)
InsertBlank(void)
FileAppend,
(

      Great Britian\Ireland

), %A_ScriptDir%\html.txt

InsertBlank(void)

Loop, %A_ScriptDir%\*.pdf {
	IfInString, A_LoopFileName, Australia
	{
	Continue
	}
StringTrimRight, Trackname, A_LoopFileName, 15
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
;take space out of FileName and put into a new variable so that the html link will match the no space filename
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
FileAppend,
(
<a href="https://www.tvg.com/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />`n
), %A_ScriptDir%\html.txt
}
FileAppend,<br \>, %A_ScriptDir%\html.txt



;Ok we have everything done, just need to remove all spaces from all pdf filenames
Loop, %A_ScriptDir%\*.pdf {
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\%A_LoopFileNameNoSpace%, 1
	If (Errorlevel)	{
	Msgbox, There was a problem removing spaces from the %A_LoopFileName% file. Permissions\Duplicate\Unknown
	}
}

ExitApp





;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/


;Gets the timestamp out of a filename and converts it into a full day of the week name
Fn_GetWeekName(para_filename) 
{
global g_WeekdayName

regexmatch(para_filename, "\D+(\d+)-li.pdf", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
	;dddd corresponds to Monday for example
	FormatTime, l_WeekdayName , %RE_TimeStamp1%, dddd
	}
	If (l_WeekdayName != "") {
	Return l_WeekdayName
	} 
	Else {
	;Return the existing day name if no new one was found
	Return g_WeekdayName
	}
}

Fn_FindTrackIniKey(para_TrackCode)
{
	Loop, Read, %A_ScriptDir%\config.ini 
	{
		;Remember the INI key value for each section until a match has been found
		IfInString, A_LoopReadLine, ]
		{
		l_CurrentIniKey = %A_LoopReadLine%
		}
		
		;Cut each track line into a psudo array and see if it matches the parameter track code
		StringSplit, ConfigArray, A_LoopReadLine, =,
		If (ConfigArray1 = para_TrackCode) {
		;Match found, remove brackets from current ini key and send back out of function
		StringReplace, l_CurrentIniKey, l_CurrentIniKey, [,,
		StringReplace, l_CurrentIniKey, l_CurrentIniKey, ],,
		Return %l_CurrentIniKey%
		}
	}
}

InsertTitle(Text) {
FileAppend, %Text%`n, %A_ScriptDir%\html.txt
}
return

F6::
ListVars
return


InsertBlank(void) {
FileAppend,
(


), %A_ScriptDir%\html.txt
}
return



StartUp()
{
#NoTrayIcon
#SingleInstance force
}