<div align="center">

# PowerShell Toolbox
##### Compiling various powershell scripts useful for automating IT tasks.

<img alt="PowerShell Toolbox" height="280" src="/assets/powershell-toolbox.png" />
</div>

## Get-PrinterDNSConfiguration

This PowerShell script creates a WPF application for viewing printer DNS settings. It resolves DNS information for provided printer names or for all printers on a specified print server. The script also allows to send a test print via TCP/IP on port 9100 using RAW ZPL or PJL.

<img alt="Get-PrinterDNSConfiguration screenshot" src=""/>

### Usage:
- Run the script in PowerShell.
- Input printer names as a comma-separated list **with no spaces** **OR** print server name.
- Click "Run" to resolve DNS information.
- Select a printer in the result grid and click "Print" to send a test print.
