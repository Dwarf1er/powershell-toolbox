# Get-PrinterDNSConfiguration

This PowerShell script creates a WPF application for viewing printer DNS settings. It resolves DNS information for provided printer names or for all printers on a specified print server. The script also allows to send a test print via TCP/IP on port 9100 using RAW ZPL or PJL.<br/>
**Note**: This script makes use of powershell runspaces to run the UI and any powershell operations in separate threads to avoid locking the UI while long running operations are taking place, each result is added to the result grid as they finish.

<img alt="Get-PrinterDNSConfiguration screenshot" src="/assets/get-printerdnsconfiguration-screenshot.png"/>

## Usage:
- Run the script in PowerShell.
- Input printer names as a comma-separated list **with no spaces** **OR** print server name.
- Click "Run" to resolve DNS information.
- Select a printer in the result grid and click "Print" to send a test print.