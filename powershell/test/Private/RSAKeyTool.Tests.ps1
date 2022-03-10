. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Private key to PKCS8' {
        It 'Throws empty parameters' {
            { PrivateKeyToPKCS8($null) } | Should -Throw
        }

        It 'Returns non empty byte array' {
            $key = Create-RSAKey -KeyLength 4096
            $parameters = $key.ExportParameters($true)
	        $rawKey = [RSAKeyUtils]::PrivateKeyToPKCS8($parameters)

            $rawKey.Length | Should -BeGreaterThan 0
        }
    }

    Describe 'CreateOctetString' {
        It 'Non empty asn value returns sequence' {
            $param = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $result = [RSAKeyUtils]::CreateOctetString($param)

            $result.GetBytes() | Should -Be @(4, 4, 1, 2, 4, 5)
        }

        It 'Non empty asn value returns proper length' {
            $param = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $result = [RSAKeyUtils]::CreateOctetString($param)

            $result.GetBytes().Length | Should -Be 6
        }
    }

    Describe 'IsEmpty byte' {
        It 'Returns true if null byte array' {
            { [RSAKeyUtils]::IsEmpty([byte[]]($null)) } | Should -BeTrue
        }

        It 'Returns true if empty byte array' {
            { [RSAKeyUtils]::IsEmpty([byte[]](@())) } | Should -BeTrue
        }

        It 'Returns false if non empty byte array' {
            [RSAKeyUtils]::IsEmpty([byte[]](@(0x04, 0x05))) | Should -BeFalse
        }
    }

    Describe 'IsEmpty string array' {
        It 'Returns true if null string array' {
            { [RSAKeyUtils]::IsEmpty([string[]]($null)) } | Should -BeTrue
        }

        It 'Returns true if empty string array' {
            { [RSAKeyUtils]::IsEmpty([string[]](@())) } | Should -BeTrue
        }

        It 'Returns false if non empty string array' {
            [RSAKeyUtils]::IsEmpty([string](@("hello", "test"))) | Should -BeFalse
        }
    }

    Describe 'IsEmpty asn type' {
        It 'Returns true if null asn type' {
            { [RSAKeyUtils]::IsEmpty([asnType]($null)) } | Should -BeTrue
        }

        It 'Returns false if non empty asn type' {
            $param = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            [RSAKeyUtils]::IsEmpty($param) | Should -BeFalse
        }
    }

    Describe 'IsEmpty asn type array' {
        It 'Returns true if null asn type array' {
            { [RSAKeyUtils]::IsEmpty([AsnType[]]($null)) } | Should -BeTrue
        }

        It 'Returns true if empty asn type array' {
            { [RSAKeyUtils]::IsEmpty([AsnType[]](@())) } | Should -BeTrue
        }

        It 'Returns false if non empty asn type array' {
            $param1 = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $param2 = [AsnType]::new([byte]0x012, [byte[]](@(0x06, 0x07)))
            [RSAKeyUtils]::IsEmpty([AsnType[]](@($param1, $param2))) | Should -BeFalse
        }
    }

    Describe 'CreateInteger' {
        It 'Normal parameters returns non empty value' {
            [RSAKeyUtils]::CreateInteger([byte[]](@(0x04, 0x05))) | Should -Not -BeNullOrEmpty
        }

        It 'Pass null returns non empty value' {
            [RSAKeyUtils]::CreateInteger([byte[]]@()) | Should -Not -BeNullOrEmpty
        }

        It 'First value is 2' {
            $result = [RSAKeyUtils]::CreateInteger([byte[]]@())

            $result.GetBytes()[0] | Should -Be 2
        }
    }

    Describe 'CreateNull' {
        It 'First byte is 5' {
            $result = [RSAKeyUtils]::CreateNull()

            $result.GetBytes()[0] | Should -Be 5
        }

        It 'Second byte is 0' {
            $result = [RSAKeyUtils]::CreateNull()

            $result.GetBytes()[1] | Should -Be 0
        }
    }

    Describe 'Duplicate' {
        It 'Duplicates array' {
            [byte[]]$array = @(0x04, 0x05)
            $result = [RSAKeyUtils]::Duplicate($array)

            $result | Should -Be $array
        }

        It 'Empty array should not throw' {
            { [RSAKeyUtils]::Duplicate(@()) } | Should -Not -Throw
        }

        It 'Duplicates empty array' {
            $result = [RSAKeyUtils]::Duplicate(@())

            $result | Should -BeNullOrEmpty
        }
    }

    Describe 'CreateIntegerPos' {
        It 'Empty array should not throw' {
            { [RSAKeyUtils]::CreateIntegerPos([byte[]]@()) } | Should -Not -Throw
        }

        It 'Empty array returns sequence' {
            $result = [RSAKeyUtils]::CreateIntegerPos([byte[]]@())

            $result.GetBytes() | Should -Be @(2, 1, 0)
        }

        It 'Empty array returns non empty' {
            $result = [RSAKeyUtils]::CreateIntegerPos([byte[]]@())

            $result.GetBytes().Length | Should -Be 3
        }

        It 'Non empty array returns sequence' {
            [byte[]]$array = @(0x04, 0x05)

            $result = [RSAKeyUtils]::CreateIntegerPos($array)

            $result.GetBytes() | Should -Be @(2, 2, 4, 5)
        }

        It 'Non empty array returns fixed size' {
            [byte[]]$array = @(0x04, 0x05)

            $result = [RSAKeyUtils]::CreateIntegerPos($array)

            $result.GetBytes().Length | Should -Be 4
        }
    }

    Describe 'Concatenate' {
        It 'Empty asn type array should not throw' {
            { [RSAKeyUtils]::Concatenate([AsnType[]]@()) } | Should -Not -Throw
        }

        It 'Empty asn type array returns null' {
            $result = [RSAKeyUtils]::Concatenate([AsnType[]]@())

            $result| Should -Be $null
        }

        It 'Empty asn type array returns empty' {
            $result = [RSAKeyUtils]::Concatenate([AsnType[]]@())

            $result.Length | Should -Be 0
        }

        It 'Non empty asn type array returns concatenated' {
            $param1 = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $param2 = [AsnType]::new([byte]0x012, [byte[]](@(0x06, 0x07)))

            $result = [RSAKeyUtils]::Concatenate([AsnType[]]@($param1, $param2))

            $result.Length | Should -Be 8
        }

        It 'Non empty asn type array returns sequence' {
            $param1 = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $param2 = [AsnType]::new([byte]0x03, [byte[]](@(0x06, 0x07)))

            $result = [RSAKeyUtils]::Concatenate([AsnType[]]@($param1, $param2))

            $result | Should -Be @(1, 2, 4, 5, 3, 2, 6, 7)
        }
    }

    Describe 'CreateSequence' {
        It 'Empty asn type array should throw' {
            { [RSAKeyUtils]::CreateSequence([AsnType[]]@()) } | Should -Throw
        }

        It 'Non empty asn type array returns fixed size' {
            $param1 = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $param2 = [AsnType]::new([byte]0x012, [byte[]](@(0x06, 0x07)))

            $result = [RSAKeyUtils]::CreateSequence([AsnType[]]@($param1, $param2))

            $result.GetBytes().Length | Should -Be 10
        }

        It 'Non empty asn type array returns sequence' {
            $param1 = [AsnType]::new([byte]0x01, [byte[]](@(0x04, 0x05)))
            $param2 = [AsnType]::new([byte]0x03, [byte[]](@(0x06, 0x07)))

            $result = [RSAKeyUtils]::CreateSequence([AsnType[]]@($param1, $param2))

            $result.GetBytes() | Should -Be @(48, 8, 1, 2, 4, 5, 3, 2, 6, 7)
        }
    }

    Describe 'CreateOid' {
        It 'Returns null if empty string' {
            $result = [RSAKeyUtils]::CreateOid("")
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null if only value' {
            $result = [RSAKeyUtils]::CreateOid("hello")
            $result | Should -BeNullOrEmpty
        }

        It 'Returns calculated sequence for specific string' {
            $result = [RSAKeyUtils]::CreateOid("1 2 3")
            $result.GetBytes() | Should -Be @(6, 2, 42, 3)
        }

        It 'Returns proper length for specific string' {
            $result = [RSAKeyUtils]::CreateOid("1 2 3")
            $result.GetBytes().Length | Should -Be 4
        }
    }

    Describe 'CreateOid byte array' {
        It 'Empty byte array should not throw' {
            { [RSAKeyUtils]::CreateOid([byte[]]@()) } | Should -Not -Throw
        }

        It 'Returns null if empty byte array' {
            $result = [RSAKeyUtils]::CreateOid([byte[]]@())
            $result | Should -BeNullOrEmpty
        }

        It 'Byte array returns sequence' {
            [byte[]]$array = @(0x04, 0x05)
            $result = [RSAKeyUtils]::CreateOid($array)
            $result.GetBytes() | Should -Be @(6, 2, 4, 5)
        }

        It 'Byte array returns proper length' {
            [byte[]]$array = @(0x04, 0x05)
            $result = [RSAKeyUtils]::CreateOid($array)

            $result.GetBytes().Length | Should -Be 4
        }
    }

    Describe 'GetBytes' {
        It 'Null octets' {
            $asn = [AsnMessage]::new($null, "hello")

            $asn.GetBytes() | Should -Be $null
        }

        It 'Not empty octets' {
            [byte[]]$array = @(0x04, 0x05)
            $asn = [AsnMessage]::new($array, "hello")

            $asn.GetBytes() | Should -Be $array
        }
    }

    Describe 'GetFormat' {
        It 'Empty string' {
            [byte[]]$array = @(0x04, 0x05)
            $asn = [AsnMessage]::new($array, "")

            $asn.GetFormat() | Should -Be ""
        }

        It 'Not empty string' {
            [byte[]]$array = @(0x04, 0x05)
            $asn = [AsnMessage]::new($array, "hello")

            $asn.GetFormat() | Should -Be "hello"
        }
    }
}