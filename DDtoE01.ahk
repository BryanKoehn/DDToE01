#CommentFlag // ; Set C++ comment style.
//**************************************************************
//  Authored by: Bryan Koehn
//  Date: 09/21/2011
//  The purpose of this code is to use FTK Imager Lite to 
//    convert DD images to E01 images.  It requires an input CSV
//    that is used to look up the name of the DD and fill out the
//    details in the E01.
//**************************************************************
JigglerName=JigglerNoNET.exe
OriginalWorkingDir = %A_WorkingDir%

StringLen,Dirlength, A_WorkingDir
StringTrimRight, DestinationDrive, A_WorkingDir, Dirlength - 1


//**********Define function************************
CSVParse(ENumber){
   global OriginalWorkingDir


   loop
   {
      FileReadLine, line, %OriginalWorkingDir%\SPOT.csv, %A_Index%
      StringSplit, CSV_Array, line,`,
//      msgBox, CSVArray=%CSV_Array2% Enumber=%ENumber%
      If ENumber in %CSV_Array2%
      {

         Return %line%
      }
   }
}
//****************End Function definition*************



//************Start GUI *************
Gui, Add, Text, ,Source Drive:
Gui, Add, Edit, vSource, F:\
Gui, Add, Text, ,Dest Drive:
Gui, Add, Edit, vDest, E:\
Gui, Add, Text, ,Continue previous run:
Gui, Add, Radio, vYes, Yes
Gui, Add, Radio, vNo, No
Gui, Add, Button, gConvert, &Convert
Gui, Show, ,DD->E01

Return





//************Start DD-> E01 conversion code *************
Convert:
GuiControlGet, Source
GuiControlGet, Dest
GuiControlGet, Yes
GuiControlGet, No

If No
{
   run, %comspec% /c Dir %Source%*.001 /b /s> DD.txt,,hide
}

BlockInput, on

SetWorkingDir, %OriginalWorkingDir%
//run, %JigglerName%,,, JigglerID

if StrLen(A_WorkingDir) = 3
{

   FTKGWorkingDir = %A_WorkingDir%FTKImagerLite
}else{
   FTKGWorkingDir = %A_WorkingDir%\FTKImagerLite
}


CheckDD:
ifExist, %A_WorkingDir%\DD.txt
{
}else{
  Goto, CheckDD
}


Sleep, 5000
FileAppend,
(
END
), DD.txt

Loop
{
   FileReadLine, line, %OriginalWorkingDir%\DD.txt, %A_Index%
   If line in END
   {
      BlockInput, off
      MsgBox, Done Coverting images.
      ExitApp
   }
   CurrentImageFullPath = %line%

   StringSplit, Line_Array, CurrentImageFullPath, \

   CurrentImageWExt = %Line_Array3%
   StringTrimRight, CurrentImageName, CurrentImageWExt, 4

   FileInfo := CSVParse(CurrentImageName)

   StringSplit, File_Info_Array, FileInfo,`,

   CaseNumber = %File_Info_Array1%
   EvidenceNumber = %File_Info_Array2%
   Unique = %File_Info_Array3%
   Examiner = %File_Info_Array4%
   Notes = %File_Info_Array5% %File_Info_Array6% %File_Info_Array7%
   Serial = %File_Info_Array7%
   FolderName = %File_Info_Array8%



   StringReplace, CaseNumber, CaseNumber, %A_SPACE%,, All
   StringReplace, EvidenceNumber, EvidenceNumber, %A_SPACE%,, All
   StringReplace, Unique, Unique, %A_SPACE%,, All
   StringReplace, Examiner, Examiner, %A_SPACE%,, All
   StringReplace, Notes, Notes, %A_SPACE%,, All
   StringReplace, Serial, Serial, %A_SPACE%,, All
   StringReplace, FolderName, FolderName, %A_SPACE%,, All


   run, %comspec% /c mkdir "%Dest%%FolderName%",,hide

   SetWorkingDir, %FTKGWorkingDir%

   RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\AccessData\FTK Imager\imaging, auto_verify, 1
   RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\AccessData\FTK Imager\imaging, prescan, 1

   run, FTK Imager.exe,,,ImagePID
   WinWait, (ahk_pid %ImagePID%)

   Sleep, 1000
   Send, !f
   Sleep, 1000
   send,c
   WinWait, Select
   send, !i
   sleep, 500
   Send, !n
   WinWait, Select File
   Send, %CurrentImageFullPath%
   Send, !f

   WinWait, Create Image
   send, !a
   WinWait, Select Image Type
   Send, !e
   Sleep, 500
   Send, !n
   WinWait, Evidence
   Send, %CaseNumber%
   Send, {tab}
   Send, %EvidenceNumber%
   Send, {tab}
   Send, %Unique%
   Send, {tab}
   Send, %Examiner%
   Send, {tab}
   Send, %Notes%
   send, !n
   send, !i
   send, %Dest%%FolderName%
   send, !m
   Send, %FolderName%_%Serial%_%EvidenceNumber%
   Send, !p
   Send, 9
   Send, !f
   Sleep, 1000
   Send, !s

   WinWait, Creating Image
   WinGet, ImagingWindowID, ID, Creating Image

   CheckImaging:
   IfWinExist, Creating Image
   {
      IfWinExist, Creating Image [100
      {
         WinWait, Verifying
         Goto, CheckVerifying
      }
      Sleep, 5600
      Goto, CheckImaging
   }

   CheckVerifying:
   IfWinExist, Verifying
   {
      IfWinExist, Drive/Image Verify Results
      {
         Goto, DoneVerifying
      }
      Sleep, 5600
      Goto, CheckVerifying
   }
   
   DoneVerifying:
   Send, !c
   Sleep, 500
   Send, !c
   Sleep, 500
   Send, !f
   Sleep, 1000
   Send, x   

   Sleep, 100
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   Sleep, 5000
}

//Kill Jiggler
Process,Close,%JigglerName%

BlockInput, off

Return

GuiClose:
ExitApp
