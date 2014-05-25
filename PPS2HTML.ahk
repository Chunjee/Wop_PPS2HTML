#NoTrayIcon
#SingleInstance force

#include inireadwrite.ahk

Version = Version 2.0
SetWorkingDir %A_ScriptDir%
Working_Directory = %A_ScriptDir%


;~~~~~~~~~~~~~~~~~~~~~
;StartUp
;~~~~~~~~~~~~~~~~~~~~~
FileDelete, %A_ScriptDir%\html.txt
Day:= %A_Now%
Day+=1, d
FormatTime, Day,%Day%, dddd
INI_Init()
INI_Load()


If (Ini_Loaded != 1)
{
Msgbox, Citizen! There was a problem reading the config.ini file. PPS2HTML will quit for your protection. (Copy a working replacement config.ini file to the same directory as PPS2HTML)
ExitApp
}




;### AUSTRALIA--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track Aus? They all have "ppAB" in the name
	regexmatch(A_LoopFileName, "ppAB(\d\d)(\d\d)\.", RE_Aus)
	If (RE_Aus1 != "") {
	FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\Australia%RE_Aus1%%RE_Aus2%%Options_Year%-li.pdf, 1
		If Errorlevel {
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions/FileInUse
		}
	}
}

;### IRELAND---------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track Irish? They all have "_INTER_IRE." in the name; EX: 20140526DR(D)_INTER.pdf
	regexmatch(A_LoopFileName, "(\d\d\d\d)(\d\d)(\d\d)(\D+)\(D\)_INTER_IRE\.", RE_Ireland)
	If (RE_Ireland1 != "") {
	TrackTLA := RE_Ireland4
	TrackName := IR_%TrackTLA%
		If (TrackName = "") {
		Msgbox, There was no corresponding Ireland Track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this under the [IR] section: `n[IR]`n %TrackTLA%=Track Name
		ExitApp
		}
	StringReplace, TrackName, TrackName, %A_SPACE%, _, All
	FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\%TrackName%%RE_Ireland2%%RE_Ireland3%%RE_Ireland1%-li.pdf, 1
		If (Errorlevel) {
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions\FileInUse
		}
	}
}

;### GREAT BRITAIN---------------------------------------------
Loop, %A_ScriptDir%\*.pdf
{
;StringLen, FileNameLength, A_LoopFileName
	;Is this track Great Britain? They all have "_INTER." in the name; EX: 20140526CTM(D)_INTER.pdf
	regexmatch(A_LoopFileName, "(\d\d\d\d)(\d\d)(\d\d)(\D+)\(D\)_INTER\.", RE_GB)
	If (RE_GB1 != "") {
	TrackTLA := RE_GB4
	TrackName := GB_%TrackTLA%
		if (TrackName = "") {
		Msgbox, There was no corresponding Great Britain Track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this under the [GB] section: `n[GB]`n %TrackTLA%=Track Name
		ExitApp
		}
	StringReplace, TrackName, TrackName, %A_SPACE%, _, All
	FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\%TrackName%%RE_GB2%%RE_GB3%%RE_GB1%-li.pdf, 1
		If (Errorlevel) {
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions\FileInUse
		}
	}
}


FileList =  ; Initialize to be blank.
InputBox, Weekday , Weekday name, %A_Tab%%A_Space%%A_Space%%A_Space%%A_Space%%A_Space% %Version%, , 180, 120, X, Y, , , %Day%
;InputBox, Weekday, Weekday name, blank, , 200, 100

FileAppend,
(
-=TVG 3=---------------------
), %A_ScriptDir%\html.txt
InsertBlank(void)

FileAppend,
(

      Australia

), %A_ScriptDir%\html.txt


InsertBlank(void)

Loop, %A_ScriptDir%\*.pdf
{

StringTrimRight, Trackname, A_LoopFileName, 13
;StringReplace, Trackname, Trackname1, %A_SPACE%, , All
	IfInString, A_LoopFileName, Austr
	{
	FileAppend,
	(
	<a href="/forms/%A_LoopFileName%" target="_blank">%Weekday% PPs</a><br />
	
	), %A_ScriptDir%\html.txt
	}

}


InsertBlank(void)
InsertBlank(void)
FileAppend,
(

      Great Britain\Ireland

), %A_ScriptDir%\html.txt

InsertBlank(void)

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
FileAppend,
(
<a href="/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %Weekday% PPs</a><br />

), %A_ScriptDir%\html.txt

}
FileAppend,
(
<br \>
), %A_ScriptDir%\html.txt


InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)

FileAppend, -=TVG 2=---------------------`n, %A_ScriptDir%\html.txt
FileAppend,`n      Australia`n, %A_ScriptDir%\html.txt


InsertBlank(void)

Loop, %A_ScriptDir%\*.pdf {

StringTrimRight, Trackname, A_LoopFileName, 13
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
	IfInString, A_LoopFileName, Austr
	{
	FileAppend,<a href="https://www.tvg.com/forms/%A_LoopFileName%" target="_blank">%Weekday% PPs</a><br />`n, %A_ScriptDir%\html.txt
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
	IfInString, A_LoopFileName, Aus
	{
	Continue
	}
StringTrimRight, Trackname, A_LoopFileName, 15
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
;take space out of FileName and put into a new variable so that the html link will match the no space filename
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
FileAppend,
(
<a href="https://www.tvg.com/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %Weekday% PPs</a><br />`n
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





;\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\
;Functions
;\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\

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