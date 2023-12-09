<#-----------------------------------------------------------------------------------------------------------------------------
    Galaxy Logs Collector Version 1.1.0
    Script, Knowledge & Bugs, Eran Binyamin Zeitoun (ezeitoun@dalet.com)
-------------------------------------------------------------------------------------------------------------------------------#>

Add-Type -AssemblyName System.Windows.Forms

$strComputerName = $env:COMPUTERNAME                                                        #Get Computer Name from Environment Variables
$strCurrentTime = (get-date).ToString("yyyyMMdd_HHmmss")                                    #Current Time/Date as String
$strProcessName = "DaletGalaxy"                                                             #Process Name
$strToolsPath = "C:\GLC\"                                                                   #3rd party tools path
$strStoragePath = "C:\GLC\Files\"                                                           #Compressed archive target path
$strWorkPath = $env:TEMP + "\GLC\"                                                          #Temp files path
$StrServersLogsXML = "\\yourShare\LogsToCollect.xml"                                        #Galaxy site XML file
$BolClose = $true                                                                           #Display Save and Close button
$strDestination = ($strStoragePath + $strCurrentTime + "_" + $strComputerName + ".zip")     #Compressed archive file name
$ScriptPath = $MyInvocation.MyCommand.Path                                                  #Script source path
$IntHours = 4                                                                               #Logs Collection Range (Hours)



<# Create Shortcut (use Create Parameter) #>
if ($Args -contains 'Create') {
    $SourceFilePath = Split-Path $ScriptPath -Parent
    $ShortcutPath = "C:\Users\Public\Desktop\Galaxy Logs Collector.lnk"
    $WScriptObj = New-Object -ComObject ("WScript.Shell")
    $shortcut = $WscriptObj.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $SourceFilePath + "\glc.bat"
    $shortcut.WorkingDirectory = $SourceFilePath
    $shortcut.IconLocation = $SourceFilePath + "\bug.ico"
    $shortcut.WindowStyle = 7
    $ShortCut.Hotkey = "CTRL+SHIFT+F12";
    $shortcut.Save()
    exit
}

<# Creating required directories for script / erasing old GLC content if exist #>
If (!(test-path $strWorkPath)) { New-Item -ItemType Directory -Force -Path $strWorkPath -ErrorAction SilentlyContinue | Out-Null}
If (!(test-path $strStoragePath)) { New-Item -ItemType Directory -Force -Path $strStoragePath -ErrorAction SilentlyContinue  | Out-Null} 
Get-ChildItem -Path $strWorkPath -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

Function MaximizeGalaxy {
$Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru
    Add-Type -AssemblyName UIAutomationClient
    $processList = Get-Process -Name $strProcessName
    foreach ($process in $processList) {
        $automationElement = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
        $processPattern = $automationElement.GetCurrentPattern([System.Windows.Automation.WindowPatternIdentifiers]::Pattern)
        $State = [PSCustomObject]@{
            ProcessState = $processPattern.Current.WindowVisualState
        }
    }
    If ($State.ProcessState -eq "Minimized") {
        $processes = Get-Process -Name "*$strProcessName*"
        $process = $processes | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
        $hwnd = $process.MainWindowHandle
        $Win32ShowWindowAsync::ShowWindowAsync($hwnd, 3)  | Out-Null
        $Win32ShowWindowAsync::SetForegroundWindow($hwnd)  | Out-Null
    }
sleep 1
}

Function IncidentForm {
    $form = [System.Windows.Forms.Form] @{ TopMost = $true; Text = "Galaxy Log Collector"; FormBorderStyle = "Fixed3D"; Icon = $strToolsPath + "\bug.ico"; MinimizeBox = $false; MaximizeBox = $false; Width = 600; Height = 130; StartPosition = 'CenterScreen' }
    $form.Controls.AddRange(@(
        [System.Windows.Forms.Label] @{ Name = 'lbl'; Left = 10; Top = 2; Width = 560; Text = "Please describe incident:"; TextAlign = "MiddleCenter"; }
        [System.Windows.Forms.TextBox] @{ Name = 'txtbox'; Left = 10; Top = 24; Width = 560 }
        If ($BolClose) { [System.Windows.Forms.Button] @{ Name = "SaveClose"; Text = "Save And Close"; Width = 105; Height = 23; Top = 50; Left = 350; DialogResult = [System.Windows.Forms.DialogResult]::Yes } }
        [System.Windows.Forms.Button] @{ Name = "SaveWait"; Text = "Save"; Width = 105; Height = 23; Top = 50; Left = 465; DialogResult = [System.Windows.Forms.DialogResult]::No }))
    $global:result = $form.ShowDialog()
    $TempPath = $strWorkPath + $strCurrentTime + "_UserInput.txt"
    $TempString = "`nUser Input:`t" + $form.controls['txtbox'].text
    Add-Content $TempPath $TempString
    if ($global:result -eq [System.Windows.Forms.DialogResult]::Cancel) { Remove-Item -LiteralPath $strWorkPath -Force -Recurse; $form.Dispose(); exit }    
    $form.Dispose()
}

Function ProgBar ($strMessage, $intBar) {    
    $form.Controls['lbl'].Text = $strMessage
    $form.Controls['pb'].Value = $intBar
    start-sleep -Milliseconds 500
}

Function ScreenShot($path) {
    $width = 0;
    $height = 0;
    $workingAreaX = 0;
    $workingAreaY = 0;
    $screen = [System.Windows.Forms.Screen]::AllScreens;
    foreach ($item in $screen) {
        if ($workingAreaX -gt $item.WorkingArea.X) { $workingAreaX = $item.WorkingArea.X; }
        if ($workingAreaY -gt $item.WorkingArea.Y) { $workingAreaY = $item.WorkingArea.Y; }
        $width = $width + $item.Bounds.Width;
        if ($item.Bounds.Height -gt $height) { $height = $item.Bounds.Height; }
    }
    $bounds = [Drawing.Rectangle]::FromLTRB($workingAreaX, $workingAreaY, $width, $height); 
    $bmp = New-Object Drawing.Bitmap $width, $height;
    $graphics = [Drawing.Graphics]::FromImage($bmp);
    $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size);
    $bmp.Save($path);
    $graphics.Dispose();
    $bmp.Dispose();
}

IncidentForm
$form = [System.Windows.Forms.Form] @{ TopMost = $true; Text = "Galaxy Log Collector"; FormBorderStyle = "Fixed3D"; Icon = $strToolsPath + "\bug.ico"; MinimizeBox = $false; MaximizeBox = $false; Width = 600; Height = 130; StartPosition = 'CenterScreen' }
$form.Controls.AddRange(@(
    [System.Windows.Forms.Label] @{ Name = 'lbl'; Left = 10; Top = 2; Width = 560; Text = "Generating/Collecting Client DMP Files..."; TextAlign = "MiddleCenter"; }
    [System.Windows.Forms.ProgressBar] @{ Name = 'pb'; Minimum = 0; Maximum = 100; Top = 30; Left = 10; Width = 560 }))
$form.Show()

<# Creating/Copying DMP File #>
ProgBar "Generating/Collecting Client DMP File" 15
if ((get-process $strProcessName -ea SilentlyContinue) -eq $Null) {
    $files = Get-ChildItem -Path "C:\ProgramData\Dalet\DaletLogs\"
    $files | Where-Object Name -Like "*DBG*" | Move-Item -Destination $strWorkPath
} else {
    Set-Location $strWorkPath
    $Command = $strToolsPath + "procdump64.exe -accepteula " + $strProcessName + ".exe " + $strWorkPath
    Invoke-Expression $Command | Out-Null
} 

<# Galaxy Client Screenshot #>
ProgBar "Taking Screenshot (Smile!)" 30
MaximizeGalaxy
$TempPath = $strWorkPath + $strCurrentTime + "_Screenshot.bmp"
$form.Hide()
ScreenShot($TempPath)
$form.Show()


<# Gathering Running Processes #>
ProgBar "Gathering Running Processes" 45
$TempPath = $strWorkPath + $strCurrentTime + "_Processes.txt"
Get-Process | Format-Table -Property ProcessName, CPU, TotalProcessorTime, PagedMemorySize, VirtualMemorySize, NonpagedSystemMemorySize, PagedSystemMemorySize, PeakPagedMemorySize, PeakWorkingSet, PeakVirtualMemorySizeTotalProcessorTime, StartTime, FileVersion, Threads | Out-File -FilePath $TempPath
    

<# Collecting System & Applications Event Logs #>
ProgBar "Collecting System & Applications Event Logs" 55
$Command = "C:\Windows\System32\wevtutil.exe" + " epl System " + $strWorkPath + $strCurrentTime + "_SystemLog.evtx"
Invoke-Expression $Command
$Command = "C:\Windows\System32\wevtutil.exe" + " epl Application " + $strWorkPath + $strCurrentTime + "_Application.evtx"
Invoke-Expression $Command


<# Collect Galaxy Client Logs for the past x hours #>
ProgBar "Collecting Galaxy Client Logs" 65
$DaletLogs = Get-ChildItem "C:\ProgramData\Dalet\DaletLogs\" -Recurse | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-$IntHours) }
foreach ($item in $DaletLogs) {
    if ($item.PSIsContainer -eq $false) {
        $NewfileName = $strWorkPath + $strCurrentTime + $item.Name
        Copy-Item $item.FullName -Destination $NewFileName 
    }
}
Copy-Item "C:\ProgramData\Dalet\LocalChannels.xml" -Destination ($strWorkPath + $strCurrentTime + "_LocalChannels.xml") -ErrorAction SilentlyContinue | Out-Null
Copy-Item "C:\ProgramData\Dalet\OneCutOutputRouting.xml" -Destination ($strWorkPath + $strCurrentTime + "_OneCutOutputRouting.xml") -ErrorAction SilentlyContinue | Out-Null

<# Collect Galaxy Server side Logs #>
ProgBar "Collecting Galaxy Servers Logs" 75
if ([System.IO.File]::Exists($StrServersLogsXML)) {
    $xml = [xml](Get-Content -Path $StrServersLogsXML)
    $siteName = (select-xml -Path $StrServersLogsXML -XPath "/LogCollector/SiteName" | select-object -expandproperty Node).'#text'
    $hosts = $xml.LogCollector.Hosts.Host
    foreach ($currentHost in $hosts) {
        $hostName = $currentHost.Hostname
        $hostAlias = $currentHost.HostAlias
        $agents = $currentHost.Agents.Agent
        Write-Host "dealing with agent $agent"
        foreach ($agent in $agents) {
            Write-Host "dealing with agent $agent"     
            $path = "\\$hostName\c$\ProgramData\Dalet\DaletLogs\$siteName-$agent@$hostAlias"
            $serverLogs = Get-ChildItem "$path" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $NewfileName = $strWorkPath + $strCurrentTime + $serverLogs.Name
            Copy-Item $serverLogs.FullName -Destination $NewFileName
        }
    }
}

<# Gather Windows Environment Variables #>
ProgBar "Collecting Environment Settings" 85
$TempPath = $strWorkPath + $strCurrentTime + "_Environment.txt"
Get-ChildItem env: | Out-File $TempPath
 
<# Compress all files into a single Zip #>
ProgBar "Compressing Everything" 90
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
$includeBaseDirectory = $false
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory("$strWorkPath","$strDestination",$compressionLevel,$includeBaseDirectory)

ProgBar "Galaxy Logs Collection Completed!" 100

<# Clean Temp Directory #>
Get-ChildItem -Path $strWorkPath -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue
       
<# Kill Galaxy Client if user clicked on Save and Close #>
if ($global:result -eq [System.Windows.Forms.DialogResult]::Yes) { Stop-Process -processname $strProcessName }
$form.Dispose()

<# Good Bye! #>
exit
