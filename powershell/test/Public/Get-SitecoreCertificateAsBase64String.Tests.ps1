. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    function rehydrateCertificate([string] $base64String, [securestring] $password) {
        $rawData = [System.Convert]::FromBase64String($base64String)
        return [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($rawData, $password)
    }

    function getDnsName([System.Security.Cryptography.X509Certificates.X509Certificate2] $cert)
    {
        return $cert.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::DnsName, $false)
    }

    Describe 'Get-SitecoreCertificateAsBase64String' {

        It 'requires $Password' {
            $result = Test-ParamIsMandatory -Command Get-SitecoreCertificateAsBase64String -Parameter Password
            $result | Should -Be $true
        }

        It 'throws if $DnsName is null' {
            { Get-SitecoreCertificateAsBase64String -DnsName $null } | Should -Throw
        }

        It 'throws if $DnsName is empty' {
            { Get-SitecoreCertificateAsBase64String -DnsName "" } | Should -Throw
        }

        It 'generates certificate Base64 string with $Password' {
            $password = ConvertTo-SecureString -String "Test123" -Force -AsPlainText
            $result = Get-SitecoreCertificateAsBase64String -Password $password

            $result | Should -Not -BeNullOrEmpty
            $result.length | Should -BeGreaterThan 0
            { rehydrateCertificate $result $password } | Should -Not -Throw
        }

        It 'uses localhost as default $DnsName' {
            $password = ConvertTo-SecureString -String "Test123" -Force -AsPlainText
            $result = Get-SitecoreCertificateAsBase64String -Password $password
            $cert = rehydrateCertificate $result $password
            $dnsName = getDnsName $cert
            $dnsName | Should -Be "localhost"
        }

        It 'uses provided $DnsName' {
            $password = ConvertTo-SecureString -String "Test123" -Force -AsPlainText
            $result = Get-SitecoreCertificateAsBase64String -DnsName "test.com" -Password $password
            $cert = rehydrateCertificate $result $password
            $dnsName = getDnsName $cert
            $dnsName | Should -Be "test.com"
        }

        It 'should not throw with default key length' {
            $password = ConvertTo-SecureString -String "Test123" -Force -AsPlainText
            { Get-SitecoreCertificateAsBase64String -DnsName "test.com" -Password $password } | Should -Not -Throw
        }

        It 'wrong rsa key length fails validation' {
            $password = ConvertTo-SecureString -String "Test123" -Force -AsPlainText
            { Get-SitecoreCertificateAsBase64String -DnsName "test.com" -Password $password -KeyLength 2000} | Should -Throw
        }
    }
}