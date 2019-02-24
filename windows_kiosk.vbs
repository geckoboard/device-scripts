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

Dim errMsgEnd, bolSetAutoLogin

errMsgEnd = "The program has stopped due to the below error " &_
 "If you believe this is a bug, please report it." & vbCrLf & vbCrLf &_
 "If you are having issues please ask for help from Geckoboard support " & vbCrLf & vbCrLf

' Elevate the script and force cscript execution
If Not WScript.Arguments.Named.Exists("elevate") Then
  CreateObject("Shell.Application").ShellExecute "cscript.exe" _
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
	LogMsg "please check for password prompt popup", Null
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

WScript.Echo "Setup complete and successfull"
WScript.Echo "Restart your computer to start in kiosk mode"
WScript.StdIn.ReadLine

' ***************************************************
' 				ONLY FUNCTIONS BELOW
' ***************************************************

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

	Dim strUser, strPasswd, wshShell
	
	strUser = CreateObject("WScript.Network").UserName
	CheckForErr

	strPasswd = PromptForPassword("Input password for user: " + strUser)

	Set wshShell = CreateObject("WScript.Shell")	

	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\AutoAdminLogon",1,"REG_SZ"
	CheckForErr
	
	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultUserName",strUser,"REG_SZ"
	CheckForErr
	
	wshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultPassword",strPasswd,"REG_SZ"
	CheckForErr
	
	Set wshShell = Nothing
End Sub

' Apparently looking through docs and google search
' You can't disable sleep/screen going blank :(
' This is a workaround by continuously taping F15
' which runs at user startup
' Alternatively the user can go through the GUI and change the option I didn't find it looking through the registry :(

' List of special folder consts https://docs.microsoft.com/en-us/previous-versions/tn-archive/ee176604(v=technet.10)
Function ExtractFolderPath(ssfConst)
	On Error Resume Next
	Dim wshShell, folder

	Set wshShell = CreateObject("Shell.Application")
	Set folder = wshShell.NameSpace(ssfConst)
	CheckForErr

	If folder Is Nothing Then
  		LogMsg "failed to fetch folder path", 1
	End If
	
	ExtractFolderPath = folder.Self.Path
End Function

Sub InstallKeepAwakeScript
	'On Error Resume Next
	Dim objFS, objFile, strContent, strFolder
	
	strFolder = ExtractFolderPath(&H7)

	Set objFS = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFS.CreateTextFile(strFolder + "\keepalive.vbs")
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
	Dim WSHShell, objAdr 

	Set WSHShell = WScript.CreateObject("WScript.Shell") 
	WSHShell.RegRead("HKEY_CURRENT_USER\SOFTWARE\Google\Chrome\BLBeacon\version")

	If Err.number <> 0 Then 
		GoogleChromeInstalled = False
		Exit Function
	End If
	
	GoogleChromeInstalled = True
End Function

Sub DownloadChromeAndInitiateUserInstall
	On Error Resume Next
	Dim oXMLHTTP, strFolder, strFPath, wshShell, objFS, objStream, objExec
	
	strFolder = ExtractFolderPath(&H10)
	strFPath = strFolder + "\chrome_install.exe"
	
	Set objFS = CreateObject("Scripting.FileSystemObject")
	Set wshShell = WScript.CreateObject("WScript.Shell")
	Set oXMLHTTP = CreateObject("MSXML2.XMLHTTP.3.0")

	If objFS.FileExists(strFPath) Then
		objFS.DeleteFile(strFPath)
	End If

	LogMsg "downloading chrome installer", Null
	oXMLHTTP.Open "GET", "https://dl.google.com/chrome/install/latest/chrome_installer.exe", False
	oXMLHTTP.Send

	If oXMLHTTP.Status = 200 Then
    	Set objStream = CreateObject("ADODB.Stream")
    	objStream.Open
    	objStream.Type = 1
    	objStream.Write oXMLHTTP.responseBody
    	objStream.SaveToFile strFPath
    	objStream.Close
	End If
	CheckForErr

	
	' Start installation which user will take over
	' and wait for install to finish
	Set objExec = wshShell.Exec(strFPath)
	LogMsg "waiting for user to complete chrome install", Null
	Do
       objExec.StdOut.ReadLine()
    Loop While Not objExec.Stdout.atEndOfStream

	LogMsg "install of chrome browser finished", Null
End Sub

Sub InstallKioskScript
	On Error Resume Next
	
	LogMsg "preparing kiosk script", Null
	Dim objFS, objFile, strFolder, strChrome86, strChrome64, strChromePath,strContent
	strFolder = ExtractFolderPath(&H7)

	Set objFS = CreateObject("Scripting.FileSystemObject")
	strChrome86 = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
	strChrome64 = "C:\Program Files\Google\Chrome\Application\chrome.exe"

	If objFS.FileExists(strChrome86) Then
		strChromePath = strChrome86
	ElseIf objFS.FileExists(strChrome64) Then
		strChromePath = strChrome64
	Else
		LogMsg "chrome browser not found at any expected paths", 1
	End If
	
	Set objFile = objFS.CreateTextFile(strFolder + "\geckoboard_kiosk.vbs")
	CheckForErr
	
	strContent = "Set wshShell = CreateObject(""WScript.Shell"")" & vbCrLf &_
	"Dim cmd" & vbCrLf &_
	"cmd =" + Chr(34) + "cmd /C " + Chr(34) + Chr(34) + strChromePath + Chr(34) + Chr(34) &_
		" --start-fullscreen --disable-extensions --no-default-browser-check --app=https://app.geckoboard.com/tv" + Chr(34) & vbCrLf &_
	"wshShell.Run cmd, 0, false" & vbCrLf &_
	"WScript.Sleep 15000" & vbCrLf &_
	"wshShell.SendKeys(""%{TAB}"")" & vbCrLf &_
	"wshShell.SendKeys(""%{TAB}"")"

	'strContent = Chr(34) + strChromePath + Chr(34) + " --start-fullscreen --disable-extensions --no-default-browser-check --app=https://app.geckoboard.com/tv"
	objFile.WriteLine(strContent)
	CheckForErr

	LogMsg "kiosk script successfully created at " + strFolder, Null
End Sub

Function PromptForPassword(myprompt)
' Written by Rob van der Woude
' http://www.robvanderwoude.com
' Error handling code written by Denis St-Pierre
	Dim objIE, strHTML, strRegValFB, strRegValLE, wshShell

	Set wshShell = CreateObject( "WScript.Shell" )
	On Error Resume Next
	On Error Goto 0
	
	' Create an IE object
	Set objIE = CreateObject( "InternetExplorer.Application" )
	' specify some of the IE window's settings
	objIE.Navigate "about:blank"
	' Add string of "invisible" characters (500 tabs) to clear the title bar
	objIE.Document.title = "Auto login computer credentials" & String( 500, 7 )
	objIE.AddressBar     = False
	objIE.Resizable      = False
	objIE.StatusBar      = False
	objIE.ToolBar        = False
	objIE.Width          = 320
	objIE.Height         = 200

	' Center the dialog window on the screen
	With objIE.Document.parentWindow.screen
		objIE.Left = (.availWidth  - objIE.Width ) \ 2
		objIE.Top  = (.availheight - objIE.Height) \ 2
	End With

	' Wait till IE is ready
	Do While objIE.Busy
		WScript.Sleep 200
	Loop

	' Insert the HTML code to prompt for a password
	strHTML = "<div style=""text-align: center;"">" _
       & "<p>" & myPrompt & "</p>" _
       & "<p><input type=""password"" size=""20"" id=""Password"" onkeyup=" _
       & """if(event.keyCode==13){document.all.OKButton.click();}"" /></p>" _
       & "<p><input type=""hidden"" id=""OK"" name=""OK"" value=""0"" />" _
       & "<input type=""submit"" value="" OK "" id=""OKButton"" " _
       & "onclick=""document.all.OK.value=1"" /></p></div>"

	objIE.Document.body.innerHTML = strHTML
	' Hide the scrollbars
	objIE.Document.body.style.overflow = "auto"
	objIE.Visible = True
	' Set focus on password input field
	objIE.Document.all.Password.focus

	' Wait till the OK button has been clicked
	On Error Resume Next
	Do While objIE.Document.all.OK.value = 0 
		WScript.Sleep 200
		' Error handling code by Denis St-Pierre
		If Err Then	' User clicked red X (or Alt+F4) to close IE window
			objIE.Quit
			Set objIE = Nothing
			PromptForPassword = ""
			Exit Function
		End if
	Loop
	On Error Goto 0

	' Read the password from the dialog window
	PromptForPassword = objIE.Document.all.Password.value

	' Terminate the IE object
	objIE.Quit
	Set objIE = Nothing

	On Error Resume Next
	On Error Goto 0
	Set wshShell = Nothing
End Function

