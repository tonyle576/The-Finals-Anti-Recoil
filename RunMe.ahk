#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#SingleInstance force
#MaxThreadsBuffer on
#Persistent
Process, Priority, , A
SetBatchLines, -1
ListLines Off
SetWorkingDir %A_ScriptDir%
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input

global UUID := "33f6cce189114748870d4fe1c2388b0e"

GoSub, iniLoad
SetPattern()
;RunAsAdmin()
;HideProcess()

global currentPattern := akmPattern
global interval := 100

SetPattern() 
{
    global akmPattern := LoadPattern("AKM.txt")
    global fcarPattern
    global xp54Pattern := LoadPattern("XP54.txt")
    global m11Pattern
    global lewisgunPattern := LoadPattern("LGUN.txt")
    global m60Pattern
    Return
}

LoadPattern(filename) 
{
    FileRead, patternStr, %A_ScriptDir%\Patterns\%filename%
    pattern := []

    Loop, Parse, patternStr, `n, `, , `" ,`r 
    {
        If StrLen(A_LoopField) == 0 {
            Continue
        }
        pattern.Insert(A_LoopField)
    }

    Return pattern
}

Speak(text) 
{
    sp := ComObjCreate("SAPI.SpVoice")
    sp.Rate := 6
    sp.Speak(text)
    Return
}

Move(x, y) 
{
    DllCall("mouse_event", uint, 1, int, x, int, y)
    Return
}

ToDegrees(num)
{
    Return num / 0.01745329252
}

ToRadians(num)
{
    Return num * 0.01745329252
}

~$*LButton::
{
    If (!GetKeyState("RButton"))
        Return

    lMax := currentPattern.MaxIndex()

    Loop {
        If (!GetKeyState("LButton", "P") || A_Index > (lmax)) {
            DllCall("mouse_event", int, 4, int, 0, int, 0, int, 0, int, 0)
            Return
        }

        patternStr := currentPattern[A_Index]
        pattern := StrSplit(patternStr,", ")

        xPix := pattern[1]
        xDeg := ToDegrees(ATan(xPix/adjacent))
        xDot := Round(xDeg/yaw)

        yPix := pattern[2]
        yDeg := ToDegrees(ATan(yPix/adjacent))
        yDot := Round(yDeg/yaw)

        Move(xDot, yDot)

        Sleep, interval
    }
    Return
}

~$*F1::
{
    currentPattern := null
    Speak("None")
    Return
}

~$*F2::
{
    currentPattern := akmPattern
    interval := 99
    Speak("AKM Selected")
    Return
}

~$*F3::
{
    currentPattern := xp54Pattern
    interval := 69
    Speak("XP54 Selected")
    Return
}

~$*F4::
{
    currentPattern := lewisgunPattern
    interval := 118
    Speak("Lewis gun selected")
    Return
}

~$*End::
{
    ExitApp
}

iniLoad:
    IniRead, sensitivity, settings.ini, settings, sensitivity
    IniRead, height, settings.ini, settings, height
    IniRead, fov, settings.ini, settings, fov

    global adjacent := 0.5 * height / TAN(0.5 * ToRadians(fov * 0.78))
    global yaw := sensitivity * 0.00101
Return

RunAsAdmin()
{
    Global 0
    IfEqual, A_IsAdmin, 1, Return 0
    Loop, %0%
        params .= A_Space . %A_Index%
        DllCall("shell32\ShellExecute" (A_IsUnicode ? "":"A"),uint,0,str,"RunAs",str,(A_IsCompiled ? A_ScriptFullPath : A_AhkPath),str,(A_IsCompiled ? "": """" . A_ScriptFullPath . """" . A_Space) params,str,A_WorkingDir,int,1)
    ExitApp
}

HideProcess() 
{
    If ((A_Is64bitOS=1) && (A_PtrSize!=4))
        hMod := DllCall("LoadLibrary", Str, "hyde64.dll", Ptr)
    Else If ((A_Is32bitOS=1) && (A_PtrSize=4))
        hMod := DllCall("LoadLibrary", Str, "hyde.dll", Ptr)
    Else
    {
        MsgBox, Mixed Versions detected!`nOS Version and AHK Version need to be the same (x86 & AHK32 or x64 & AHK64).`n`nScript will now terminate!
        ExitApp
    }

    If (hMod)
    {
        hHook := DllCall("SetWindowsHookEx", Int, 5, Ptr, DllCall("GetProcAddress", Ptr, hMod, AStr, "CBProc", ptr), Ptr, hMod, Ptr, 0, Ptr)
        If (!hHook)
        {
            MsgBox, SetWindowsHookEx failed!`nScript will now terminate!
            ExitApp
        }
    }
    Else
    {
        MsgBox, LoadLibrary failed!`nScript will now terminate!
        ExitApp
    }
    Return
}