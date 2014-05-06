#NoTrayIcon
#SingleInstance force

#include inireadwrite.ahk

Version = Version 1.8a
SetWorkingDir %A_ScriptDir%
Working_Directory = %A_WorkingDir%


;~~~~~~~~~~~~~~~~~~~~~
;In Progress
;~~~~~~~~~~~~~~~~~~~~~
FileDelete, %A_WorkingDir%\html.txt
Day:= %A_Now%
Day+=1, d
FormatTime, Day,%Day%, dddd
INI_Init()
INI_Load()
INI_writeAll()

;ListVars
;Msgbox, alf

If (Ini_Loaded != 1)
{
Msgbox, Citizen! There was a problem reading the config.ini file. PPS2HTML will quit for your protection. (Copy a working replacement config.ini file to the same directory as PPS2HTML)
ExitApp
}




;### AUSTRALIA---------------------------------------------
Loop, %A_WorkingDir%\*.pdf
{
StringLen, FileNameLength, A_LoopFileName
	;Is this track Aus? They all have "ppAB" in the name
	If (FileNameLength >= 14 && FileNameLength < 16 && InStr(A_LoopFileName, "ppAB") )
	{
	StringTrimRight, DateBoth, A_LoopFileName, 4
	StringTrimLeft, DateBoth, DateBoth, 7
	StringTrimRight, DateMon, DateBoth, 2
	StringTrimLeft, DateDay, DateBoth, 2
	FileMove, %A_WorkingDir%\%A_LoopFileName%, %A_WorkingDir%\Australia%DateMon%%DateDay%%Options_Year%-li.pdf, 1
		If Errorlevel
		{
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions/FileInUse
		}
	}
}

;### IRELAND---------------------------------------------
Loop, %A_WorkingDir%\*.pdf
{
StringLen, FileNameLength, A_LoopFileName
	;Is this track IR? They all have "_INTER_IRE" in the name
	If (FileNameLength >= 27 && FileNameLength < 29 && InStr(A_LoopFileName, "_INTER_IRE.pdf") )
	{
		If FileNameLength = 27
		{
		TrimDateRight = 19
		}
		else
		{
		TrimDateRight = 20
		}
	StringTrimRight, TrackTLA, A_LoopFileName, 17
	StringTrimLeft, TrackTLA, TrackTLA, 8
	StringTrimRight, DateBoth, A_LoopFileName, %TrimDateRight%
	StringTrimLeft, DateBoth, DateBoth, 4
	StringTrimRight, DateMon, DateBoth, 2
	StringTrimLeft, DateDay, DateBoth, 2
	;TrackTLA now has tracks abbreviation, find a way to do that.
	;"The value in the variable named Var is " . Var
	
	Counter = 1
	BUFFER := IR_%TrackTLA%
		if BUFFER = 
		{
		Msgbox, There was no corresponding Ireland Track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this under the [IR] section: `n[IR]`n %TrackTLA%=Track Name
		ExitApp
		BUFFER = IR_NOTFOUND%Counter%
		Counter += 1
		}
	StringReplace, BUFFER, BUFFER, %A_SPACE%, _, All
	FileMove, %A_WorkingDir%\%A_LoopFileName%, %A_WorkingDir%\%BUFFER%%DateMon%%DateDay%%Options_Year%-li.pdf, 1
		If Errorlevel
		{
		Msgbox, There was a problem renaming the %A_LoopFileName% file. Permissions\FileInUse
		}
	}
}

;### GREAT BRITAIN---------------------------------------------
Loop, %A_WorkingDir%\*.pdf
{
StringLen, FileNameLength, A_LoopFileName
	;Is this track GB? They all have "_INTER" in the name and are longer then 23 characters.
	If (FileNameLength >= 23 && FileNameLength < 26 && InStr(A_LoopFileName, "_INTER.pdf") )
	{
		If FileNameLength = 23
		{
		TrimDateRight = 15
		}
		else
		{
		TrimDateRight = 16
		}
	StringTrimRight, TrackTLA, A_LoopFileName, 13
	StringTrimLeft, TrackTLA, TrackTLA, 8
	StringTrimRight, DateBoth, A_LoopFileName, %TrimDateRight%
	StringTrimLeft, DateBoth, DateBoth, 4
	StringTrimRight, DateMon, DateBoth, 2
	StringTrimLeft, DateDay, DateBoth, 2
	;TrackTLA now has tracks abbreviation, find a way to do that.
	;"The value in the variable named Var is " . Var
	
	Counter = 1
	BUFFER := GB_%TrackTLA%
		if BUFFER = 
		{
		Msgbox, There was no corresponding Great Britain Track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this under the [GB] section: `n[GB]`n %TrackTLA%=Track Name
		ExitApp
		BUFFER = GB_NOTFOUND%Counter%
		Counter += 1
		}
	StringReplace, BUFFER, BUFFER, %A_SPACE%, _, All
	FileMove, %A_WorkingDir%\%A_LoopFileName%, %A_WorkingDir%\%BUFFER%%DateMon%%DateDay%%Options_Year%-li.pdf, 1
		If Errorlevel
		{
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
), %A_WorkingDir%\html.txt
InsertBlank(void)

FileAppend,
(

      Australia

), %A_WorkingDir%\html.txt


InsertBlank(void)

Loop, %A_WorkingDir%\*.pdf
{

StringTrimRight, Trackname, A_LoopFileName, 13
;StringReplace, Trackname, Trackname1, %A_SPACE%, , All
	IfInString, A_LoopFileName, Austr
	{
	FileAppend,
	(
	<a href="/forms/%A_LoopFileName%" target="_blank">%Weekday% PPs</a><br />
	
	), %A_WorkingDir%\html.txt
	}

}


InsertBlank(void)
InsertBlank(void)
FileAppend,
(

      Great Britian\Ireland

), %A_WorkingDir%\html.txt

InsertBlank(void)

Loop, %A_WorkingDir%\*.pdf
{
IfInString, A_LoopFileName, Aus
	{
	Continue
	}
StringTrimRight, Trackname, A_LoopFileName, 13
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
;take space out of FileName and put into a new variable so that the html link will match the no space filename
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
FileAppend,
(
<a href="/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %Weekday% PPs</a><br />

), %A_WorkingDir%\html.txt

}
FileAppend,
(
<br \>
), %A_WorkingDir%\html.txt


InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)
InsertBlank(void)

FileAppend,
(
-=TVG 2=---------------------

), %A_WorkingDir%\html.txt


FileAppend,
(

      Australia

), %A_WorkingDir%\html.txt


InsertBlank(void)

Loop, %A_WorkingDir%\*.pdf
{

StringTrimRight, Trackname, A_LoopFileName, 13
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
	IfInString, A_LoopFileName, Austr
	{
	FileAppend,
	(
	<a href="https://www.tvg.com/forms/%A_LoopFileName%" target="_blank">%Weekday% PPs</a><br />
	
	), %A_WorkingDir%\html.txt
	}

}


InsertBlank(void)
InsertBlank(void)
FileAppend,
(

      Great Britian\Ireland

), %A_WorkingDir%\html.txt

InsertBlank(void)

Loop, %A_WorkingDir%\*.pdf
{
IfInString, A_LoopFileName, Aus
	{
	Continue
	}
StringTrimRight, Trackname, A_LoopFileName, 13
StringReplace, TrackName, TrackName, _, %A_SPACE%, All
;take space out of FileName and put into a new variable so that the html link will match the no space filename
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
FileAppend,
(
<a href="https://www.tvg.com/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %Weekday% PPs</a><br />

), %A_WorkingDir%\html.txt

}
FileAppend,
(
<br \>
), %A_WorkingDir%\html.txt



;Ok we have everything done, just need to remove all spaces from all pdf filenames
Loop, %A_WorkingDir%\*.pdf
{
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
FileMove, %A_WorkingDir%\%A_LoopFileName%, %A_WorkingDir%\%A_LoopFileNameNoSpace%, 1
	If Errorlevel
	{
	Msgbox, There was a problem removing spaces from the %A_LoopFileName% file. Permissions\Duplicate\Unknown
	}
}



ExitApp





;\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\
;Functions
;\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\--\

InsertTitle(Text)
{
FileAppend,
(
%Text%
), %A_WorkingDir%\html.txt
}
return

F6::
ListVars
return


InsertBlank(void)
{
FileAppend,
(


), %A_WorkingDir%\html.txt
}
return