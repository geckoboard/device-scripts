'*******************************************************************************
'* File:           windows_kiosk_mode_uninstall
'*
'* Purpose:        Remove kiosk mode from device
'*
'* Version:        0.0.1
'*
'*******************************************************************************

Option Explicit

On Error Resume Next

Dim errMsgEnd, completedMsg, bolSetAutoLogin, objShell, objFSO, wshShell

Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set wshShell = WScript.CreateObject("WScript.Shell")

errMsgEnd = "The program has stopped due to the below error " &_
 "If you believe this is a bug, please report it." & vbCrLf & vbCrLf &_
 "If you are having issues please ask for help from Geckoboard support " & vbCrLf & vbCrLf

completedMsg = vbCrLf & vbCrLf & "Removal of resources completed" & vbCrLf & "When you are ready restart your computer"

' Elevate the script and force cscript execution
If Not WScript.Arguments.Named.Exists("elevate") Then
  objShell.ShellExecute "cscript.exe" _
    , """" & WScript.ScriptFullName & """ /elevate", "", "runas", 1
  WScript.Quit
End If

' Startup with banner and steps
PrintLogoHeader
PrintProcessSteps

WScript.StdOut.Write("do you want to stop the user from auto logging in [y/N]: ")
bolSetAutoLogin = WScript.StdIn.ReadLine

If bolSetAutoLogin = "y" Then
	LogMsg "removing user auto login", Null
	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\AutoAdminLogon",0,"REG_SZ"
End If

LogMsg "removing keep awake script", Null
RemoveKeepAwakeScript

LogMsg "removing kiosk script", Null
RemoveKioskScript
Cleanup

WScript.Echo(completedMsg)
WScript.StdIn.ReadLine

' ***************************************************
' 				ONLY FUNCTIONS BELOW
' ***************************************************
Sub Cleanup
	wshShell = Nothing
	objFSO = Nothing
	objShell = Nothing
End Sub

Sub LogMsg(msg, i)
	If IsNull(i) Then
		WScript.Echo("[INFO] " + msg)
	Else
		WScript.Echo("[ERRO] " + msg)
		WScript.Echo(vbCrLf & errMsgEnd)
		MsgBox errMsgEnd & "Error:" & vbCrLf & msg, 16, "Unexpected Error"
		WScript.Quit(1)
	End If
End Sub

Sub CheckForErr
	If Err <> 0 Then
		LogMsg Err.Description, 1
	End If
End Sub

Sub PrintLogoHeader
	Dim banner
	banner = "  _____ ______ _____ _  ______  ____   ____          _____  _____ " & vbCrLf &_
	" / ____|  ____/ ____| |/ / __ \|  _ \ / __ \   /\   |  __ \|  __ \ " & vbCrLf &_
	"| |  __| |__   |    | ' / |  | | |_| | |  | | /  \  | |__| | |  | | " & vbCrLf &_
	"| | |_ |  __|  |    |  <  |  | |  _ <| |  | |/ /\ \ |  _  /| |  | | " & vbCrLf &_
	"| |__| | |___  |____| ' \ |__| | |_| | |__| / ____ \| | \ \| |__| | " & vbCrLf &_
	" \_____|______\_____|_|\_\____/|____/ \____/_/    \_\_|  \_\_____/ "
	
	WScript.Echo(banner & vbCrLf)
End Sub

Sub PrintProcessSteps
	Dim msg1
	
	msg1 = "This will remove scripts installed to support Geckoboard kiosk mode" & vbCrLf & vbCrLf &_
	"We will do the following;" & vbCrLf &_
		" - Prevent auto autologin (optional)" & vbCrLf &_
		" - Remove the script which prevented the computer sleeping" & vbCrLf &_
 		" - Remove script which will start chrome at Geckoboard on each startup" & vbCrLf & vbCrLf &_
		"This process should only take a few seconds to complete"

	WScript.Echo(msg1)
	WScript.Echo("If you are ready press any key to start")
	WScript.StdIn.ReadLine
End Sub

' List of special folder consts https://docs.microsoft.com/en-us/previous-versions/tn-archive/ee176604(v=technet.10)
Function ExtractFolderPath(ssfConst)
	On Error Resume Next
	Dim folder

	Set folder = objShell.NameSpace(ssfConst)
	CheckForErr

	If folder Is Nothing Then
  		LogMsg "failed to fetch folder path", 1
	End If
	
	ExtractFolderPath = folder.Self.Path
End Function

Sub RemoveKeepAwakeScript
	On Error Resume Next
	Dim strFolder, strFile

	strFolder = ExtractFolderPath(&H7)
	strFile = strFolder + "\keepalive.vbs"

	If objFSO.FileExists(strFile) Then
		objFSO.DeleteFile(strFile)
	End If

	CheckForErr
End Sub

Sub RemoveKioskScript
	On Error Resume Next
	Dim strFolder, strFile

	strFolder = ExtractFolderPath(&H7)
	strFile = strFolder + "\geckoboard_kiosk.vbs"

	If objFSO.FileExists(strFile) Then
		objFSO.DeleteFile(strFile)
	End If

	CheckForErr	
End Sub