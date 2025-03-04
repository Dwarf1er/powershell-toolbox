param(
    [switch]$Help,
    [string]$Website,
    [string]$DownloadPath = "C:\Users\$env:Username\Documents\Certificates\"  
)

function Show-Help {
    @"
Install-GitSslCertificate - Downloads the SSL certificate of a specified website and configures Git to use it.

Usage: Install-GitSslCertificate.ps1 [OPTIONS] -Website <website>

Parameters:
-Website <website>        The website to retrieve the SSL certificate from.
                            Example: "https://example.com"

-DownloadPath <path>      The local directory to save the SSL certificate. Default is
                            "C:\Users\$env:Username\Documents\Certificates\" (recommended).
                            Example: "C:\path\to\save\certificates\" 

-Help                     Show this help message and exit.
"@
}

if ($Help) {
    Show-Help
    exit
}

if ($Website -eq "") {
    Write-Host "You must provide a URL to the -Website parameter."
    Show-Help
    exit
}

if ((-not (Test-Path -Path $DownloadPath))) {
    Write-Host "$DownloadPath directory was not found, now creating $DownloadPath"
    New-Item -Path $DownloadPath -ItemType Directory -Force
}

function Get-WebsiteCertificate {
    [CmdletBinding()] param(
        [Parameter(Mandatory = $true)]
        [System.Uri] $Uri
    )
    
    $webRequest = [Net.WebRequest]::Create($Uri)
    try {
        $null = $webRequest.GetResponse()
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($webRequest.ServicePoint.Certificate)
    }
    catch {
        Write-Host "Error retrieving certificate from $Uri"
        return $null
    }
    
    return $certificate
}

function Convert-CertificateToBase64AsciiPem {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]] $CertificateBytes
    )

    $base64EncodedCertificate = [Convert]::ToBase64String($CertificateBytes)

    $pemFormattedCertificate = "-----BEGIN CERTIFICATE-----`r`n"
    $pemFormattedCertificate += $base64EncodedCertificate -replace "(.{64})", ('$1' + "`r`n")
    $pemFormattedCertificate += "`r`n-----END CERTIFICATE-----"

    return $pemFormattedCertificate
}

if ($Website -notmatch '^https?://') {
    $Website = "https://$Website"
}

$cleanWebsite = $Website -replace '^https?://', ''
$domain = ($cleanWebsite -split '\.')[-2..-1] -join '.'
$certificateName = "_.$domain"
$certificatePath = Join-Path -Path $DownloadPath -ChildPath $certificateName

$certificate = Get-WebsiteCertificate -Uri $Website
$certificateBytes = $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
$base64EncodedCertificate = Convert-CertificateToBase64AsciiPem -CertificateBytes $certificateBytes

Set-Content -Value $base64EncodedCertificate -Encoding ASCII -Path $certificatePath

Write-Host "SSL certificate downloaded and saved to $certificatePath"

try {
    $gitExePath = (Get-Command git -ErrorAction Stop).Source
    Write-Host "Git found at $gitExePath.\n Configuring Git with the SSL certificate."

    $absoluteCertificatePath = [System.IO.Path]::GetFullPath($certificatePath)

    & $gitExePath config --global http.sslBackend "openssl"
    & $gitExePath config --global http.$Website.sslCAInfo $absoluteCertificatePath

    Write-Host "Git configured with the SSL certificate."
}
catch {
    Write-Host "Git is not installed or not found in the system PATH."
}
