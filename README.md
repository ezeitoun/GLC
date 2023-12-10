# Galaxy Logs Collector v1.1.0

This PowerShell script is designed to simplify the process of gathering Galaxy Logs (both user and server-side) for troubleshooting purposes.

Extract the provided ZIP file to a preferred location (placing the script on the local client machine is recommended).<br />
Once completed, you have two options: create a shortcut to the GLC.BAT file or run GLC.ps1 Create (with Admin rights) to generate a shortcut on the Desktop, complete with a default hotkey (Ctrl + Shift + F12).<br />
If you opt for automatic creation, The following shortcut will be create on the desktop:<br />
![image001](https://github.com/ezeitoun/GLC/assets/57022870/948dfbd5-acfc-4a7e-9230-5729ddce6933)


You can either double-click the shortcut to execute the Galaxy Logs Collector or press Ctrl+Shift+F12 within the client (or any other location).<br />
A popup will appear, prompting for an incident report/description.
![GLC-POPUP](https://github.com/ezeitoun/GLC/assets/57022870/7199d9f2-9e8e-467b-8b9e-eeb507190817)<br />
In this window, users can input details about their activities when the issue occurred.<br />
Clicking "Save and Close" will collect the logs (including DMP generation or copying a Galaxy Client generated one) and close (kill) the Dalet Galaxy client.<br />
Alternatively, clicking "Save" will collect the logs (and generate a DMP file) without terminating the client. This option is suitable for freezes that typically resolve after a period.

As of version 1.1.0, the script collects the following:
  - Input User for Incident Report
  - Generate or Copy DMP File (⚠️)
  - Capture Galaxy Client Screenshot
  - Gather Running Processes Information
  - Collect System & Applications Event Logs
  - Collect Galaxy Client Logs
  - Collect Galaxy Servers Logs
  - Gather Windows Environment Variables
⚠️ To enable DMP support, Please download ProcDump x64 (https://learn.microsoft.com/en-us/sysinternals/downloads/procdump) and extract it to the GLC location.<br />
(Galaxy Client Screenshot Capture Improvement, Server-side log collections by Laurnet Goetz (lgoetz@dalet.com)

The script can be configure by modifying the following variables:
- $strProcessName (default "DaletGalaxy"), If a different process (OneCutSA) is being used rather DaletGalaxy.
- $strToolsPath (default "C:\GLC\"), Script location (and where ProcDump should be copied to!)
- $strStoragePath (default "C:\GLC\Files\"), The location were all compressed archive of the collected data will be written.
- $strWorkPath (default $env:TEMP + "\GLC\"), Temp files location (default would be %TEMP%\GLC)
- $StrServersLogsXML (default "\\yourShare\LogsToCollect.xml"), XML file containing required server-side logs, If file doesnt exist, This step will skipped.
- $BolClose (default $true), Configure if the "Save and Close" button will appear.
- $IntHours (default 4), Galaxy Client log collection range (in hours).

Server-side log collection:
In this updated GLC version (1.1.0), it is now feasible to collect particular agent logs alongside the local logs of the host where the script is initiated. <br />
This is achieved through the configuration of an XML file that specifies the desired servers and agents for the log gathering process. <br />
We advise against the wholesale collection of logs from all agents on every machine, as it may have an adverse impact on network traffic.<br />
Instead, we recommend a targeted approach, focusing on specific strategic agents such as dbServers, DaletPlusServers, and NATServers, as these are commonly implicated in most issues requiring investigation.<br />
For additional logs from specific hosts, like BrioMediaAgents located within the studios, it is suggested to tailor the log gathering accordingly.<br />
(The SiteName, HostName, HostAlias and the agents name for the XML file (sample included in the repository), Can be obtain from the Dalet Remote Admin)<br />
⚠️ Windows users running the script should have Read rights to C:\ProgramData\Dalet\DaletLogs of each server. (access will be done via UNC)

