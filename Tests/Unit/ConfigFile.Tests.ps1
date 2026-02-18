BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Read-GwtConfigFile' {
    BeforeEach {
        $script:testDir = Join-Path ([System.IO.Path]::GetTempPath()) "gwt-cfg-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
    }

    AfterEach {
        Remove-Item $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'reads key from config file' {
        $configFile = Join-Path $script:testDir 'config'
        'GWT_MAIN_BRANCH=develop' | Set-Content $configFile

        $result = InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $Path
        }
        $result | Should -Be 'develop'
    }

    It 'returns empty for missing key' {
        $configFile = Join-Path $script:testDir 'config'
        'GWT_ALIAS=wt' | Set-Content $configFile

        $result = InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $Path
        }
        $result | Should -BeNullOrEmpty
    }

    It 'returns empty for missing file' {
        $result = InModuleScope GWT {
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path '/nonexistent/path/config'
        }
        $result | Should -BeNullOrEmpty
    }

    It 'handles comments and blank lines' {
        $configFile = Join-Path $script:testDir 'config'
        @(
            '# This is a comment'
            'GWT_ALIAS=gw'
            ''
            '# Another comment'
            'GWT_MAIN_BRANCH=develop'
        ) | Set-Content $configFile

        $result = InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $Path
        }
        $result | Should -Be 'develop'
    }

    It 'handles quoted values' {
        $configFile = Join-Path $script:testDir 'config'
        'GWT_POST_CREATE_CMD="npm install"' | Set-Content $configFile

        $result = InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Read-GwtConfigFile -Key 'GWT_POST_CREATE_CMD' -Path $Path
        }
        $result | Should -Be 'npm install'
    }

    It 'reads empty value for key with no value' {
        $configFile = Join-Path $script:testDir 'config'
        'GWT_ALIAS=' | Set-Content $configFile

        $result = InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Read-GwtConfigFile -Key 'GWT_ALIAS' -Path $Path
        }
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Write-GwtConfigFile' {
    BeforeEach {
        $script:testDir = Join-Path ([System.IO.Path]::GetTempPath()) "gwt-cfg-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
    }

    AfterEach {
        Remove-Item $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'adds new key to config file' {
        $configFile = Join-Path $script:testDir 'config'
        '# gwt config' | Set-Content $configFile

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value 'develop' -Path $Path
        }

        (Get-Content $configFile -Raw) | Should -BeLike '*GWT_MAIN_BRANCH=develop*'
    }

    It 'replaces existing key without duplicates' {
        $configFile = Join-Path $script:testDir 'config'
        'GWT_MAIN_BRANCH=old' | Set-Content $configFile

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value 'develop' -Path $Path
        }

        $content = Get-Content $configFile -Raw
        $count = ([regex]::Matches($content, 'GWT_MAIN_BRANCH')).Count
        $count | Should -Be 1
        $content | Should -BeLike '*GWT_MAIN_BRANCH=develop*'
    }

    It 'removes key when value empty' {
        $configFile = Join-Path $script:testDir 'config'
        'GWT_MAIN_BRANCH=develop' | Set-Content $configFile

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value '' -Path $Path
        }

        (Get-Content $configFile -Raw) | Should -Not -BeLike '*GWT_MAIN_BRANCH*'
    }

    It 'creates parent directories' {
        $configFile = Join-Path $script:testDir 'subdir/gwt/config'

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value 'develop' -Path $Path
        }

        (Get-Content $configFile -Raw) | Should -BeLike '*GWT_MAIN_BRANCH=develop*'
    }

    It 'preserves other keys' {
        $configFile = Join-Path $script:testDir 'config'
        @(
            'GWT_ALIAS=wt'
            'GWT_MAIN_BRANCH=old'
            'GWT_NO_FZF=1'
        ) | Set-Content $configFile

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value 'develop' -Path $Path
        }

        $content = Get-Content $configFile -Raw
        $content | Should -BeLike '*GWT_ALIAS=wt*'
        $content | Should -BeLike '*GWT_MAIN_BRANCH=develop*'
        $content | Should -BeLike '*GWT_NO_FZF=1*'
    }

    It 'can write empty value explicitly with KeepEmpty' {
        $configFile = Join-Path $script:testDir 'config'
        '# config' | Set-Content $configFile

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_ALIAS' -Value '' -Path $Path -KeepEmpty
        }

        (Get-Content $configFile -Raw) | Should -BeLike '*GWT_ALIAS=*'
    }

    It 'sanitizes dangerous characters' {
        $configFile = Join-Path $script:testDir 'config'
        '# config' | Set-Content $configFile

        InModuleScope GWT -Parameters @{ Path = $configFile } {
            param($Path)
            Write-GwtConfigFile -Key 'GWT_POST_CREATE_CMD' -Value 'echo hello`whoami`end' -Path $Path
        }

        $content = Get-Content $configFile -Raw
        $content | Should -Not -BeLike '*`*'
        $content | Should -Not -BeLike '*$*'
    }
}
