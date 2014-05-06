;~~~~~~~~~~~~~~~~~~~~~
;Ini Read/Write
;~~~~~~~~~~~~~~~~~~~~~
;Imports settings.ini
;Credit for Function: Superfraggle

/*
INI_Init(inifile)     ;prepares the global variables to be populated
INI_Load(inifile)     ;Reads all the settings into the global variables from the file
INI_Save(inifile)     ;Saves all the settings from the global variables into the file

INI_ReadAll(inifile)  ;Synonym for INI_Load
INI_WriteAll(inifile) ;Synonym for INI_Save

*/
INI_Init(inifile = "config.ini"){
  global
  local key
  inisections:=0
 
  loop,read,%inifile%
  {
    if regexmatch(A_Loopreadline,"\[(\w+)]")
      {
        inisections+= 1
        section%inisections%:=regexreplace(A_loopreadline,"(\[)(\w+)(])","$2")
        section%inisections%_keys:=0
      }
    else if regexmatch(A_LoopReadLine,"(\w+)=(\w+)")
      {
        section%inisections%_keys+= 1
        key:=section%inisections%_keys
        section%inisections%_key%key%:=regexreplace(A_LoopReadLine,"(\w+)=(.*)","$1")
      }
  }
}

INI_readAll(inifile="config.ini"){
  INI_load(inifile)
}

INI_load(inifile="config.ini"){
  global
  local sec,var
  loop,%inisections%
    {
      sec:=A_index
      loop,% section%a_index%_keys
        {
          var:=section%sec% "_" section%sec%_key%A_index%
          iniread,%var%,%inifile%,% section%sec%,% section%sec%_key%A_index%
        }
    }
}

INI_writeAll(inifile="config.ini"){
  INI_Save(inifile)
}

INI_Save(inifile="config.ini"){
  global
  local sec,var
  loop,%inisections%
    {
      sec:=A_index
      loop,% section%a_index%_keys
        {
          var:=section%sec% "_" section%sec%_key%A_index%,var:=%var%
          iniwrite,%var%,%inifile%,% section%sec%,% section%sec%_key%A_index%
        }
    }
}