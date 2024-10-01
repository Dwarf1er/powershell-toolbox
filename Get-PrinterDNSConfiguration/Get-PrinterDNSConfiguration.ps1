# Load the PresentationFramework assembly for creating a WPF window
Add-Type -AssemblyName PresentationFramework

# Create a synchronized hashtable to hold UI elements and data
$Global:syncHash = [hashtable]::Synchronized(@{})

# Create a new runspace
$newRunspace = [runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA" # Set the apartment state to Single-Threaded Apartment
$newRunspace.ThreadOptions = "ReuseThread" # Optimize thread usage by reusing threads
$newRunspace.Open() # Open the runspace
$newRunspace.SessionStateProxy.SetVariable("syncHash",$Global:syncHash) # Set the synchronized hashtable in the runspace

# Create a PowerShell object and define the script block for UI creation
$psCmd = [PowerShell]::Create().AddScript({
    # Define XAML markup for the WPF window
    [xml]$xaml = @"
	<Window
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		x:Name="Window"
		Title="Printer DNS Configuration Tool" Height="800" Width="1000">
		<Window.Resources>
			<Style TargetType="TextBlock" x:Key="CellTextStyle">
				<Style.Triggers>
					<DataTrigger Binding="{Binding ReversePointerMatch}" Value="False">
						<Setter Property="Foreground" Value="Red"/>
						<Setter Property="FontWeight" Value="Bold"/>
					</DataTrigger>
					<DataTrigger Binding="{Binding ReversePointerMatch}" Value="True">
						<Setter Property="Foreground" Value="Green"/>
						<Setter Property="FontWeight" Value="Bold"/>
					</DataTrigger>
				</Style.Triggers>
			</Style>

		</Window.Resources>
		<Grid>
			<Grid.RowDefinitions>
				<RowDefinition Height="Auto"/>
				<RowDefinition Height="Auto"/>
				<RowDefinition Height="Auto"/>
				<RowDefinition Height="*"/>
			</Grid.RowDefinitions>
			
			<Grid.ColumnDefinitions>
				<ColumnDefinition Width="Auto"/>
				<ColumnDefinition Width="*"/>
			</Grid.ColumnDefinitions>
			
			<Label Content="Printer Name(s) as a comma-separated list:" Grid.Row="0" Grid.Column="0"/>
			<TextBox x:Name="printerNames" Grid.Row="0" Grid.Column="1" Margin="10,10,10,0"/>

			<Label Content="Print Server Name:" Grid.Row="1" Grid.Column="0" Margin="0,10,0,0"/>
			<TextBox x:Name="printServerName" Grid.Row="1" Grid.Column="1" Margin="10,10,10,10"/>

		    <Grid Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2">
			<Grid.ColumnDefinitions>
			    <ColumnDefinition Width="*" />
			    <ColumnDefinition Width="*" />
			</Grid.ColumnDefinitions>
			
			<Button x:Name="btnRun" Content="Run" Margin="10,10,5,10" Padding="20,0,20,0" HorizontalAlignment="Right"/>
			<Button x:Name="btnPrint" Content="Print" Grid.Column="1" Margin="5,10,10,10" Padding="20,0,20,0" HorizontalAlignment="Left"/>
		    </Grid>
			
			<DataGrid x:Name="dataGridResults" Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" AutoGenerateColumns="False">
				<DataGrid.Resources>
					<SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#C0C0C0"/>
				</DataGrid.Resources>
				<DataGrid.Columns>
					<DataGridTextColumn Header="Printer Name" Binding="{Binding PrinterName}" Width="*">
						<DataGridTextColumn.ElementStyle>
							<Style TargetType="TextBlock" BasedOn="{StaticResource CellTextStyle}"/>
						</DataGridTextColumn.ElementStyle>
					</DataGridTextColumn>
					<DataGridTextColumn Header="IP Address" Binding="{Binding IPAddress}" Width="*">
						<DataGridTextColumn.ElementStyle>
							<Style TargetType="TextBlock" BasedOn="{StaticResource CellTextStyle}"/>
						</DataGridTextColumn.ElementStyle>
					</DataGridTextColumn>
					<DataGridTextColumn Header="Reverse Pointer" Binding="{Binding ReversePointer}" Width="*">
						<DataGridTextColumn.ElementStyle>
							<Style TargetType="TextBlock" BasedOn="{StaticResource CellTextStyle}"/>
						</DataGridTextColumn.ElementStyle>
					</DataGridTextColumn>
					<DataGridTextColumn Header="Reverse Pointer Match" Binding="{Binding ReversePointerMatch}" Width="*">
						<DataGridTextColumn.ElementStyle>
							<Style TargetType="TextBlock" BasedOn="{StaticResource CellTextStyle}"/>
						</DataGridTextColumn.ElementStyle>
					</DataGridTextColumn>
				</DataGrid.Columns>
			</DataGrid>
		</Grid>
	</Window>
"@
	# Load XAML into a reader and create WPF objects from it
	$reader=(New-Object System.Xml.XmlNodeReader $xaml)
	$Global:syncHash.Window=[Windows.Markup.XamlReader]::Load($reader)
	$Global:syncHash.printerNames = $Global:syncHash.Window.FindName("printerNames")
	$Global:syncHash.printServerName = $Global:syncHash.Window.FindName("printServerName")
	$Global:syncHash.btnRun = $Global:syncHash.Window.FindName("btnRun")
	$Global:syncHash.btnPrint = $Global:syncHash.Window.FindName("btnPrint")
	$Global:syncHash.dataGridResults = $Global:syncHash.Window.FindName("dataGridResults")
	$Global:syncHash.zplString = [System.Text.Encoding]::ASCII.GetBytes("^XA^CFA,30^FO100,100^FDPRINT TEST^FS^XZ")
	$Global:syncHash.pjlString = [System.Text.Encoding]::ASCII.GetBytes(@"
@PJL JOB
@PJL RDYMSG DISPLAY="PRINT TEST"
@PJL ENTER LANGUAGE = PCL
PRINT TEST
@PJL EOJ
"@)

	# Define the Click event handler for the "Run" button
	$Global:syncHash.btnRun.Add_Click({
		# Create a new runspace for background processing
		$newRunspace = [runspacefactory]::CreateRunspace()
		$newRunspace.Open()
		
		# Set variables in the new runspace
		$newRunspace.SessionStateProxy.SetVariable("syncHash",$Global:syncHash) 
		$scriptBlock = {
			param (
				$syncHash, # Synchronized hashtable containing UI elements
				$printerNamesText, # Text entered in printerNames TextBox
				$printServerNameText # Text entered in printServerName TextBox
			)
			
			# Clear the DataGrid in the UI
			$syncHash.dataGridResults.Dispatcher.Invoke([Action]{
				$syncHash.dataGridResults.Items.Clear()
			})
			
			# Initialize an array to store printer names
			$printers = @()
			
			# Check if printerNamesText is not empty
			if ($printerNamesText -ne "") {
				# Split printer names by comma and store in $printers array
				$printers = $printerNamesText.Split(",")
			}
			# If printerNamesText is empty, check if printServerNameText is not empty
			elseif ($printServerNameText -ne "") {
				# Get printer names from the print server and store in $printers array
				$printers = Get-Printer -ComputerName $printServerNameText | Select-Object -ExpandProperty Name
			}

			$syncHash.Window.Dispatcher.Invoke([Action]{
				$syncHash.printerNames.Clear()
				$syncHash.printServerName.Clear()
			})
			
			# Iterate through each printer name
			foreach ($printer in $printers) {
				# Resolve IP address for the printer
				$ipAddress = (Resolve-DnsName -Name $printer -ErrorAction SilentlyContinue).IPAddress
				if ($ipAddress -eq $null) {
					$ipAddress = "NOT FOUND"
				}

				# Initialize variables for IP address, reverse pointer, and reverse pointer match
				$ipAddresses = $ipAddress
				$reversePointer = "NOT FOUND"
				
				# Check if IP address is not "NOT FOUND"
				if ($ipAddress -ne "NOT FOUND") {
					# If IP address is an array, convert it to a comma-separated string
					if($ipAddress.GetType().Name -eq "Object[]") {
						$ipAddresses = $ipAddress -join "`n"
						$ipAddress = $ipAddress[0]
					}
					# Resolve reverse pointer for the IP address
					$reversePointerTest = (Resolve-DnsName -Name $ipAddress -ErrorAction SilentlyContinue).NameHost
					if ($reversePointerTest) {
						$reversePointer = $reversePointerTest -join "`n"
					}
				}

				# Check if reverse pointer matches printer name
				$reversePointerMatch = $false
				if ($reversePointer -eq $printer) {
					$reversePointerMatch = $true
				}
				
				# Create a custom object with printer details
				$result = [PSCustomObject]@{
					"PrinterName" = $printer
					"IPAddress" = $ipAddresses.ToString()
					"ReversePointer" = $reversePointer
					"ReversePointerMatch" = $reversePointerMatch
				}
				
				# Update the UI with the result
				$syncHash.dataGridResults.Dispatcher.Invoke([Action]{
					$syncHash.dataGridResults.Items.Add($result)
				})
			}
		}

		# Create a PowerShell object with the script block and arguments
		$ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($Global:syncHash).AddArgument($Global:syncHash.printerNames.Text).AddArgument($Global:syncHash.printServerName.Text)
		$ps.Runspace = $newRunspace
		$ps.BeginInvoke()
	})

	$Global:syncHash.btnPrint.Add_Click({
		# Create a new runspace for background processing
		$newRunspace = [runspacefactory]::CreateRunspace()
		$newRunspace.Open()
		
		# Set variables in the new runspace
		$newRunspace.SessionStateProxy.SetVariable("syncHash",$Global:syncHash) 
		$scriptBlock = {
			param (
				$syncHash
			)

			$syncHash.Window.Dispatcher.Invoke([Action]{
				if($syncHash.dataGridResults.SelectedItem -ne $null) {
					$tcpClient = New-Object System.Net.Sockets.TcpClient
					$printerIpAddress = ($syncHash.dataGridResults.SelectedItem).IPAddress
					$printerCommand = $syncHash.pjlString
					$tcpClient.Connect($printerIpAddress, 9100)
					$networkStream = $tcpClient.GetStream()

					if((Invoke-RestMethod $printerIpAddress | Select-String -Pattern "Zebra" -Quiet)) {
						$printerCommand = $syncHash.zplString
					}

					$networkStream.Write($printerCommand, 0, $printerCommand.Length)
					$networkStream.Close()
					$tcpClient.Dispose()
				}
			})
		}

		# Create a PowerShell object with the script block and arguments
		$ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($Global:syncHash)
		$ps.Runspace = $newRunspace
		$ps.BeginInvoke()
	})

        $Global:syncHash.Window.Add_KeyDown({
            param(
                [Parameter(Mandatory)][Object]$sender,
                [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
            )
            if ($e.Key -eq "Enter") {
                $Global:syncHash.Window.Dispatcher.Invoke([Action]{
                    $Global:syncHash.btnRun.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
                })
            }
        })

	# Show the WPF window
	$Global:syncHash.Window.ShowDialog() | Out-Null
	$Global:syncHash.Error = $Error
})

# Set the runspace for the PowerShell object
$psCmd.Runspace = $newRunspace

# Begin asynchronous execution of the PowerShell script
$data = $psCmd.BeginInvoke()
