<#
.SYNOPSIS
Create a certificate request and optionally submits it to a Certificate
Authority.

.LINK
http://blog.kloud.com.au/2013/07/30/ssl-san-certificate-request-and-import-from-powershell/

.EXAMPLE
.\New-CertificateRequest.ps1 -Subject CN=www.fabrikam.com

Creates a minimal certificate request for a website (https://www.fabrikam.com).

.EXAMPLE
.\New-CertificateRequest.ps1 -Subject CN=www.fabrikam.com -SubmitRequest -CertificateTemplate TechnologyToolboxWebServer

Creates a minimal certificate request and submits it to a CA with a specific template.

.EXAMPLE
.\New-CertificateRequest.ps1 -Subject "CN=mail.fabrikam.com,OU=IT,O=Fabrikam Technologies,L=Denver,S=CO,C=US" -SANs mail.fabrikam.com,autodiscover.fabrikam.com

Create a detailed certificate request with various Subject Alternative Names.
#>
Param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Enter the subject beginning with CN=")]
    [ValidatePattern("CN=")]
    [string] $Subject,
    [Parameter(
        HelpMessage = "Enter the Subject Alternative Names as a comma separated list")]
    [array] $SANs,
    [switch] $SubmitRequest,
    [Parameter(
        HelpMessage = "Enter the certificate template to use")]
    [string] $CertificateTemplate = "WebServer")

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
}

Process
{
    ### Preparation
    [string] $subjectDomain = $subject.Split(',')[0].Split('=')[1]
    If ($subjectDomain -match "\*.")
    {
        $subjectDomain = $subjectDomain -replace "\*", "star"
    }

    [string] $tempFileName = [System.IO.Path]::GetTempFileName()

    [string] $infFile = $tempFileName.Replace('.tmp', '.inf')
    [string] $requestFile = $tempFileName.Replace('.tmp', '.req')
    [string] $responseFile = $tempFileName.Replace('.tmp', '.rsp')
    [string] $certFile = $tempFileName.Replace('.tmp', '.cer')

    ### INI file generation
    Write-Verbose "Creating certificate INF file ($infFile)..."

    New-Item -Type File $infFile | Out-Null
    Add-Content $infFile '[Version]'
    Add-Content $infFile 'Signature="$Windows NT$"'
    Add-Content $infFile ''
    Add-Content $infFile '[NewRequest]'
    Add-Content $infFile ('Subject="' + $subject + '"')
    Add-Content $infFile 'Exportable=TRUE'
    Add-Content $infFile 'KeyLength=2048'
    Add-Content $infFile 'KeySpec=1'
    Add-Content $infFile 'KeyUsage=0xA0'
    Add-Content $infFile 'MachineKeySet=True'
    Add-Content $infFile 'ProviderName="Microsoft RSA SChannel Cryptographic Provider"'
    Add-Content $infFile 'ProviderType=12'
    Add-Content $infFile 'SMIME=FALSE'
    Add-Content $infFile 'RequestType=PKCS10'
    Add-Content $infFile '[Strings]'
    Add-Content $infFile 'szOID_ENHANCED_KEY_USAGE = "2.5.29.37"'
    Add-Content $infFile 'szOID_PKIX_KP_SERVER_AUTH = "1.3.6.1.5.5.7.3.1"'
    Add-Content $infFile 'szOID_PKIX_KP_CLIENT_AUTH = "1.3.6.1.5.5.7.3.2"'

    If ($SANs)
    {
        Add-Content $infFile 'szOID_SUBJECT_ALT_NAME2 = "2.5.29.17"'
        Add-Content $infFile '[Extensions]'
        Add-Content $infFile '2.5.29.17 = "{text}"'

        foreach ($SAN in $SANs)
        {
            [string] $temp = '_continue_ = "dns=' + $SAN + '&"'
            Add-Content $infFile $temp
        }
    }

    ### Certificate request generation
    Write-Verbose "Creating certificate request ($requestFile)..."

    certreq.exe -New $infFile $requestFile | Out-Null

    If ($LASTEXITCODE -ne 0)
    {
        Throw "certreq.exe failed with exit code $LASTEXITCODE"
    }

    If ($SubmitRequest -eq $false)
    {
        Get-Content -Path $requestFile
    }
    Else
    {
        ### Online certificate request and import
        Write-Verbose "Submitting certificate request ($requestFile) to CA..."

        certreq.exe `
            -Submit `
            -attrib "CertificateTemplate:$CertificateTemplate" `
            $requestFile `
            $certFile | Out-Null

        If ($LASTEXITCODE -ne 0)
        {
            Throw "certreq.exe failed with exit code $LASTEXITCODE"
        }

        Write-Verbose "Accepting certificate ($certFile)..."

        certreq.exe -Accept $certFile | Out-Null

        If ($LASTEXITCODE -ne 0)
        {
            Throw "certreq.exe failed with exit code $LASTEXITCODE"
        }
    }


    Write-Verbose "Removing temporary files..."

    Remove-Item $infFile
    Remove-Item $requestFile

    If (Test-Path $responseFile)
    {
        Remove-Item $responseFile
    }

    If (Test-Path $certFile)
    {
        Remove-Item $certFile
    }
}