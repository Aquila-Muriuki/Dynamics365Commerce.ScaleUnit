using namespace System.Security.Cryptography.X509Certificates

<#
.SYNOPSIS
Ensure that the certificate exists, if the certificate is missing, create one.

.DESCRIPTION
Ensure that the certificate exists, if the certificate is missing, create one.

.PARAMETER CheckOnly
Only check the certificate existence, do not create anything.
#>
[CmdletBinding()]
param(
    [switch]
    $CheckOnly
)
Import-Module (Join-Path $PSScriptRoot "ErrorDecorator.psm1")

function Get-CertificatesFromStore {
    param(
        [StoreLocation]
        $StoreLocation = [StoreLocation]::LocalMachine,

        [StoreName]
        $StoreName = [StoreName]::My,

        [string]
        [Parameter(Mandatory = $true)]
        $SubjectName
    )

    Write-Verbose "Checking for $SubjectName on local store"
    $store = [X509Store]::new($StoreName, $StoreLocation)
    try {
        $store.Open([OpenFlags]::ReadOnly)
        $store.Certificates | Where-Object { $_.Subject -eq $SubjectName -and $_.NotAfter -gt (Get-Date) }
    } finally {
        if ($store) {
            $store.Dispose()
        }
    }
}

function Import-CertificatesIntoStore {
    param(
        [StoreLocation]
        $StoreLocation = [StoreLocation]::LocalMachine,

        [StoreName]
        $StoreName = [StoreName]::My,

        [X509Certificate2]
        [Parameter(Mandatory = $true)]
        $Certificate
    )

    $store = $null
    try {
        $store = [X509Store]::new($StoreName, $StoreLocation)
        $store.Open([OpenFlags]::ReadWrite)
        $store.Add($Certificate)
        $store.Close()
        Write-Verbose "Certificate $($Certificate.SubjectName) installed"
    } catch {
        Write-CustomError "Failed to install certificate $($Certificate.SubjectName). Are you running this command as Administrator?"
        throw
    } finally {
        if ($store) {
            $store.Dispose()
        }
    }
}

$MachineName = [System.Net.Dns]::GetHostEntry("").HostName
$Subject = "Dynamics 365 Self-Hosted Sample Retail Server"
$certSubjectName = "CN=$Subject"

# Search for valid certificate in local store
$cert = Get-CertificatesFromStore -SubjectName $certSubjectName
if (($null -eq $cert)) {
    if (-not $CheckOnly) {
        Write-Host "Creating certificate for the '$MachineName' with subject '$Subject'"
        $cert = New-SelfSignedCertificate -DnsName "$MachineName" `
            -CertStoreLocation "cert:\LocalMachine\My" `
            -Subject $certSubjectName `
            -NotAfter (Get-Date).AddMonths(24)`
            -KeySpec KeyExchange # This is to mitigate the CryptographicException: Invalid provider type specified.

        Write-Host "Adding certificate for the '$MachineName' with subject '$Subject' to Trusted Root, the thumbprint is '$($cert.Thumbprint)'."
        Import-CertificatesIntoStore -Certificate $cert -StoreName ([StoreName]::Root)
    }
} else {
    Write-Verbose "The certificate for the '$MachineName' with subject '$Subject' already exists, the thumbprint is '$($cert.Thumbprint)'."
}

#return the thumbprint of the found valid certificate
if (($null -ne $cert)) {
    $cert.Thumbprint
}
else
{
    $null
}

# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCQ9QtfXSQkzLFv
# kJXOAJECN+WkdvAMjr4um+ZklrLFEKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
# DkyjTQVBAAAAAAOvMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwOTAwWhcNMjQxMTE0MTkwOTAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOS8s1ra6f0YGtg0OhEaQa/t3Q+q1MEHhWJhqQVuO5amYXQpy8MDPNoJYk+FWA
# hePP5LxwcSge5aen+f5Q6WNPd6EDxGzotvVpNi5ve0H97S3F7C/axDfKxyNh21MG
# 0W8Sb0vxi/vorcLHOL9i+t2D6yvvDzLlEefUCbQV/zGCBjXGlYJcUj6RAzXyeNAN
# xSpKXAGd7Fh+ocGHPPphcD9LQTOJgG7Y7aYztHqBLJiQQ4eAgZNU4ac6+8LnEGAL
# go1ydC5BJEuJQjYKbNTy959HrKSu7LO3Ws0w8jw6pYdC1IMpdTkk2puTgY2PDNzB
# tLM4evG7FYer3WX+8t1UMYNTAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQURxxxNPIEPGSO8kqz+bgCAQWGXsEw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMTgyNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAISxFt/zR2frTFPB45Yd
# mhZpB2nNJoOoi+qlgcTlnO4QwlYN1w/vYwbDy/oFJolD5r6FMJd0RGcgEM8q9TgQ
# 2OC7gQEmhweVJ7yuKJlQBH7P7Pg5RiqgV3cSonJ+OM4kFHbP3gPLiyzssSQdRuPY
# 1mIWoGg9i7Y4ZC8ST7WhpSyc0pns2XsUe1XsIjaUcGu7zd7gg97eCUiLRdVklPmp
# XobH9CEAWakRUGNICYN2AgjhRTC4j3KJfqMkU04R6Toyh4/Toswm1uoDcGr5laYn
# TfcX3u5WnJqJLhuPe8Uj9kGAOcyo0O1mNwDa+LhFEzB6CB32+wfJMumfr6degvLT
# e8x55urQLeTjimBQgS49BSUkhFN7ois3cZyNpnrMca5AZaC7pLI72vuqSsSlLalG
# OcZmPHZGYJqZ0BacN274OZ80Q8B11iNokns9Od348bMb5Z4fihxaBWebl8kWEi2O
# PvQImOAeq3nt7UWJBzJYLAGEpfasaA3ZQgIcEXdD+uwo6ymMzDY6UamFOfYqYWXk
# ntxDGu7ngD2ugKUuccYKJJRiiz+LAUcj90BVcSHRLQop9N8zoALr/1sJuwPrVAtx
# HNEgSW+AKBqIxYWM4Ev32l6agSUAezLMbq5f3d8x9qzT031jMDT+sUAoCw0M5wVt
# CUQcqINPuYjbS1WgJyZIiEkBMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOrrvVETKnkmohM5oPXfHhft
# VWKcZBZQhz8A6fUDQi/3MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAIdh/PTEuV/FRrTqpuBaqA2hWffzwdVgOXg+5VGXkZ0GkRfXodM0HxVMM
# K/CR23N9zT2iGpGqDiHs+DdgtlaNTo9TYP1Kty6llcCzv736xcfJl4Wza3K6usEr
# 1x5WH0Nq4ZKGz65Otn2dR+llNRGKY5fmCIJnuWaOWlexFNh8OxmaFhIrs/oSnpMa
# odrVHaWKnAF8UEaAU63ouc54UkpvdeiNQeq/4BHsnp6M+OBRg3mIz5vepwMVqxgC
# 02K/vGC6qZH4JUrEOhCA9f9yGZGbishVnqeUrDAB6hq91qqddc3JgPEZnHujr2Ro
# ny9WlFz63MdaTidk4IGtXvMp93KODaGCF5YwgheSBgorBgEEAYI3AwMBMYIXgjCC
# F34GCSqGSIb3DQEHAqCCF28wghdrAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFRBgsq
# hkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCDup+6HXVxYMFJPh8235BN2S4Mx51L/x4O1FgEwKLo0AAIGZhfNEu51
# GBIyMDI0MDQyMzEwMjEyMi40OFowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBOTM1LTAz
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCC
# Ee0wggcgMIIFCKADAgECAhMzAAAB6Q9xMH5d8RI2AAEAAAHpMA0GCSqGSIb3DQEB
# CwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4NDUy
# NloXDTI1MDMwNTE4NDUyNlowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMx
# JzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBOTM1LTAzRTAtRDk0NzElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAKyajDFBFWCnhNJzedNrrKsA8mdXoDtplidPD/LH3S7U
# NIfz2e99A3Nv7l+YErymkfvpOYnOMdRwiZ3zjkD+m9ljk7w8IG7sar7Hld7qmVC3
# jHBVRRxAhPGSU5nVGb18nmeHyCfE7Fp7MUwzjWwMjssykrAgpAzBcNy1gq8LJDLq
# Q7axUsHraQXz3ZnBximIhXHctPUs90y3Uh5LfkpjkzHKVF1NLsTUmhyXfQ2BwGIl
# +qcxx7Tl4SKkixM7gMif/9O0/VHHntVd+8I7w1IKH13GzK+eDSVRVj66ur8bxBEW
# g6X/ug4jRF/xCD7eHJhrIewj3C28McadPfQ2vjXHNOnDYjplZoiE/Ay7kO92QQbN
# Xu9hPe1v21O+Jjemy6XVPkP3fz8B80upqdUIm0/jLPRUkFIZX6HrplxpQk7GltIi
# MiZo4sXXw06OZ/WfANq2wGi5dZcUrsTlLRUtHKhOoMLEcbiZbeak1Cikz9TVYmeO
# yxZCW4rx5v4wMqWT0T+E4FgqzYp95Dgcbt05wr7Aw5qYZ/C+Qh7t2TKXObwF4BRA
# LwvGsBDKSFIfL4VpD3cMCV9BijBgO3MZeoTrA4BN4oUjfS71iXENPMC4sMrTvdyd
# 0xXipoPd65cDrFQ0KjODuuKGIdRozjcCZv0Qa5GXTbb7I/ByWbKSyyTfRrhGne/1
# AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUkX4zicUIdiO4iPRa6/6NyO0H7E4wHwYD
# VR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# VGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
# BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0
# cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
# B4AwDQYJKoZIhvcNAQELBQADggIBAFaxKn6uazEUt7rUAT3Qp6fZc+BAckOJLhJs
# uG/N9WMM8OY51ETvm5CiFiEUx0bAcptWYsrSUdXUCnP8dyJmijJ6gC+QdBoeYuHA
# EaSjIABXFxppScc0hRL0u94vTQ/CZxIMuA3RX8XKTbRCkcMS6TApHyR9oERfzcDK
# 9DOV/9ugM2hYoSCl0CwvxLMLNcUucOjPMIkarRHPBCB4QGvwTgrbBDZZcj9knFlL
# /53cV3AbgSsEXPNSJJtXabfGww/dyoJEUO0nULf8meNcwKGeb1ssMPXBontM+nnB
# h2/Q6X35o3S3UGY7MKPwOaoq5TDOAIr1OO3DkpSNo7pCN6AfOd1f+1mtjv3Z19EB
# evl0asqSmywgerqutY7g+Uvc5L7hyIv+Xymb6g0ldYZdgkvkfos2crJclUTD/UVs
# 7j4bP5Th8UXGzZLxTC+sFthxxVD074WWPvFMB4hMmwem0C9ESoJz79jHOEgqQDzx
# DxCEkpQO1rNq0kftk52LQsIrCCpA7gfzUpkYNIuS0W81GGHxkEB6efWlb7lQEZjP
# YamBzFVcpPUK5Rh2UdH0Po2tWEap2EZODs6D93/ygyU8bdiO6oXGJ2IiygDDb4yE
# jXNesiLnq3omQnvknr0X6WSH2bIkmk2THjWxIHVcraMlaCrtWUG4/UG5eNneqDKb
# 2vXC/Qy1MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG
# 9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIw
# MTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az
# /1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V2
# 9YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oa
# ezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkN
# yjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7K
# MtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRf
# NN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SU
# HDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoY
# WmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5
# C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8
# FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TAS
# BgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1
# Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUw
# UzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIB
# hjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fO
# mhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggr
# BgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3
# DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEz
# tTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJW
# AAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G
# 82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/Aye
# ixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI9
# 5ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1j
# dEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZ
# KCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xB
# Zj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuP
# Ntq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvp
# e784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCA1Aw
# ggI4AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTkzNS0wM0UwLUQ5NDcxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAKtp
# h/XEOTasydT9UmjYYYrWfGjxoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDp0XOMMCIYDzIwMjQwNDIyMjMzODUy
# WhgPMjAyNDA0MjMyMzM4NTJaMHcwPQYKKwYBBAGEWQoEATEvMC0wCgIFAOnRc4wC
# AQAwCgIBAAICGNACAf8wBwIBAAICE78wCgIFAOnSxQwCAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEADm1YMHBnDsw73b1NIO9nqO/1MaDyA0SsJnnx+DUHbZ6M
# mXN8kSY7NCYGBYtOQf8P0BB9ssinNBj5siBKEYU2N6fme5YMd7F9ByeTnYO/Xo+x
# j7HedYQ0vGXj01qIgBYHFufHfrL328nTaCweZBvYezxwDzMx0WcGVbwLsIDVHllJ
# Qae/0y8DxBhKnMF3x3NnDtx/OKjwCUS8YHCQ8ZC5oZSKEQClofSggwM+H2mfISzf
# W1Ud71MAZE/EQj1jjrH8gSl5EKvcRxV7E43Cek/IUZa0dfnzASABfyl0dwOtkurK
# MR+KcN0A6JTWJmPi7+yLdFl4LKUpF7aKxcCdiTEsbTGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB6Q9xMH5d8RI2AAEAAAHp
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIIgTvOm/u+BInf40uOzct2+ZoshHRXU7rNj2ycstyU/q
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgpJCSeJdpNyaPVMpBYX7HZTiu
# JWisYPxPCaBVs32qxCUwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAekPcTB+XfESNgABAAAB6TAiBCCQwuZ9BPOSXQ7jZQOpNbHyqV8+
# erhMt5aYw7PT3avJRjANBgkqhkiG9w0BAQsFAASCAgAZmaQtSocEUJnc3R1CBvA2
# afVhhBPnbIwKxPSHbAn+Eil0U++FgEL+VtmLmKS4M6beeB/17uz5XCgnHc9Efmyp
# is8fV1TvM0y9xE3+/wnSg1v55YOUA6Q5EOmYTMfpBV1ax9um4l+90BBc/K2nG1xj
# cGp8nw3ALfDM8EAHZqlb2y7H7qMZ5V09HJCrjRq6odJMWe+4XC34NRp4Ks8MSD97
# 8ctbpr1S/h4n+tfMrYhLIlDnTDZprDs9HnggvDVxUlbdjMUaR5D9nkrCRjbQUyjT
# 5NzOhUAwWMIWDCvmP7v+tk1XGvVVo1R9I+i6eGdl0upgTSLk1HFL9x0OiZ6I8Z0O
# 1VQ9m2asqf3waFNcPVLWpfXDBuQBZjrfC+jDQTw/iXrO1LYsGWY95+pGsoSJrvGp
# JFujiWEOAgF60m5BJtdRj7JrXKpcHfo4oJE3EPqHuS2qjsmhOe5MNifZ9Glrnf/+
# aEX49E3qDJRaweoPVs4ZKklN3brDiFUzccMbzQoYMz6d1qybHpq4hOvCuE2y1AQb
# txec87L98PDs7t9zTcMP1CpxhVzKddu7CwUMUjKfkN+EpzwgmhpPSqKdCDj9en+i
# OtCSAajibYbhBwirqbgSlWc2Ka3uwVLZ9q3XPKPa1/7fHuwhlj0VCBWJo1S/0sbs
# uxoCXqP68Scf+ySiGMF2VA==
# SIG # End signature block
