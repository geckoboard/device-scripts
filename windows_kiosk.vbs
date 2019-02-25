'*******************************************************************************
'* File:           windows_kiosk_mode
'*
'* Purpose:        Support making any windows device into kiosk mode optimized
'*				   for displaying Geckoboard
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
 
completedMsg = vbCrLf & vbCrLf & "************ Setup complete ***********" & vbCrLf &_
	"Check out the send to TV support article on how to pair your device with Geckoboard" & vbCrLf &_
	"Now you are ready to reboot" & vbCrLf & vbCrLf &_
	"When windows next starts up it should display the TV pin code" & vbCrLf & vbCrLf &_
	"http://bit.ly/gbontvdoc" & vbCrLf & vbCrLf &_
	"You'll be empowering your team to be the best in no time" & vbCrLf & vbCrLf &_
	"When you are ready restart your computer."

' Elevate the script and force cscript execution
If Not WScript.Arguments.Named.Exists("elevate") Then
  objShell.ShellExecute "cscript.exe" _
    , """" & WScript.ScriptFullName & """ /elevate", "", "runas", 1
  WScript.Quit
End If

' Startup with banner and steps
PrintLogoHeader
PrintProcessSteps

WScript.StdOut.Write("do you want this user to auto login [y/N]: ")
bolSetAutoLogin = WScript.StdIn.ReadLine

' Set current user to autologin
If bolSetAutoLogin = "y" Then
	LogMsg "setting up user to auto login", Null
	SetupAutoLoginUser
End If

' Install Chrome browser
If Not GoogleChromeInstalled Then
	LogMsg "installing google chrome as not found", Null
	DownloadChromeAndInitiateUserInstall
Else
	LogMsg "chrome already installed skipping", Null
End If

InstallKeepAwakeScript
InstallKioskScript
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
	Dim msg1,msg2
	
	msg1 = "We will guide you through setting up your device optimized to display Geckoboard." & vbCrLf &_
		"Along the way you will have the option to not do some things for which you can just press enter" & vbCrLf &_
		"The questions which will be asked will be just require either y for Yes or n for No " & vbCrLf &_
		"by default the answer will assume No (y/N) declared by the capital N in these cases you can just press enter" & vbCrLF

	msg2 = "We will do the following;" & vbCrLf &_
		" - Setup auto logging in your local user account (you can choose to opt out)" & vbCrLf &_
		" - Ensure chrome browser is installed for you" & vbCrLf &_
		" - Install a script to prevent the computer sleeping" & vbCrLf &_
 		" - Install a script which will start chrome at Geckoboard on each startup" & vbCrLf & vbCrLf &_
		"This process should only take a few minutes to setup"

	WScript.Echo(msg1)
	WScript.Echo(msg2)
	WScript.Echo("If you are ready press any key to start")
	WScript.StdIn.ReadLine
End Sub

Sub SetupAutoLoginUser
	On Error Resume Next

	Dim strUser, strPasswd
	
	strUser = CreateObject("WScript.Network").UserName
	CheckForErr

	WScript.StdOut.Write("Input the password for "+ strUser + ": ")
	strPasswd = WScript.StdIn.ReadLine

	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\AutoAdminLogon",1,"REG_SZ"
	CheckForErr
	
	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultUserName",strUser,"REG_SZ"
	CheckForErr
	
	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultPassword",strPasswd,"REG_SZ"
	CheckForErr
End Sub

' Apparently looking through docs and google search
' You can't disable sleep/screen going blank :(
' This is a workaround by continuously taping F15
' which runs at user startup
' Alternatively the user can go through the GUI and change the option I didn't find it looking through the registry :(

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

Sub InstallKeepAwakeScript
	On Error Resume Next
	Dim objFile, strContent, strFolder
	
	strFolder = ExtractFolderPath(&H7)

	Set objFile = objFSO.CreateTextFile(strFolder + "\keepalive.vbs")
	CheckForErr
	
	strContent = "Dim wshShell" & vbCrLf &_
	"Set wshShell = WScript.CreateObject(""WScript.Shell"")" & vbCrLf &_
	"Do While True" & vbCrLf &_
	"	wshShell.SendKeys(""{F15}"")" & vbCrLf &_
	"	WScript.Sleep(55000)" & vbCrLf &_
	"Loop"
	
	objFile.WriteLine(strContent)
End Sub

Function GoogleChromeInstalled
	On Error Resume Next 

	WSHShell.RegRead("HKEY_CURRENT_USER\SOFTWARE\Google\Chrome\BLBeacon\version")

	If Err.number <> 0 Then 
		GoogleChromeInstalled = False
		Exit Function
	End If
	
	GoogleChromeInstalled = True
End Function

Sub HttpGetRequest(url, strFilePath)
	On Error Resume Next
	Dim oXMLHTTP, objStream

	Set oXMLHTTP = CreateObject("MSXML2.XMLHTTP.3.0")

	If objFSO.FileExists(strFilePath) Then
		objFSO.DeleteFile(strFilePath)
	End If

	oXMLHTTP.Open "GET", url, False
	oXMLHTTP.Send

	If oXMLHTTP.Status = 200 Then
    	Set objStream = CreateObject("ADODB.Stream")
    	objStream.Open
    	objStream.Type = 1
    	objStream.Write oXMLHTTP.responseBody
    	objStream.SaveToFile strFilePath
    	objStream.Close
	End If

	CheckForErr
End Sub

Sub DownloadChromeAndInitiateUserInstall
	On Error Resume Next
	Dim strDesktop, strFilePath, objExec

	strDesktop = ExtractFolderPath(&H10)
	strFilePath = strDesktop + "\chrome_install.exe"

	LogMsg "downloading chrome installer", Null
	HttpGetRequest "https://dl.google.com/chrome/install/latest/chrome_installer.exe", strFilePath

	' Start installation which user will take over
	' and wait for install to finish
	Set objExec = wshShell.Exec(strFilePath)
	LogMsg "waiting for user to complete chrome install", Null
	Do
       objExec.StdOut.ReadLine()
    Loop While Not objExec.Stdout.atEndOfStream

	LogMsg "install of chrome browser finished", Null
End Sub

Sub InstallKioskScript
	On Error Resume Next
	Dim objFS, objFile, strFolder, strChrome86, strChrome64, strChromePath, strContent

	LogMsg "preparing kiosk script", Null
	strFolder = ExtractFolderPath(&H7)

	strChrome86 = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
	strChrome64 = "C:\Program Files\Google\Chrome\Application\chrome.exe"

	If objFSO.FileExists(strChrome86) Then
		strChromePath = strChrome86
	ElseIf objFSO.FileExists(strChrome64) Then
		strChromePath = strChrome64
	Else
		LogMsg "chrome browser not found at any expected paths", 1
	End If

	Set objFile = objFSO.CreateTextFile(strFolder + "\geckoboard_kiosk.vbs")
	CheckForErr

	strContent = "Set wshShell = CreateObject(""WScript.Shell"")" & vbCrLf &_
	"Dim cmd" & vbCrLf &_
	"cmd =" + Chr(34) + "cmd /C " + Chr(34) + Chr(34) + strChromePath + Chr(34) + Chr(34) &_
		" --start-fullscreen --disable-extensions --no-default-browser-check --app=https://app.geckoboard.com/tv" + Chr(34) & vbCrLf &_
	"wshShell.Run cmd, 0, false" & vbCrLf &_
	"WScript.Sleep 15000" & vbCrLf &_
	"wshShell.SendKeys(""%{TAB}"")" & vbCrLf &_
	"wshShell.SendKeys(""%{TAB}"")"

	objFile.WriteLine(strContent)
	CheckForErr

	LogMsg "kiosk script successfully created at " + strFolder, Null
End Sub