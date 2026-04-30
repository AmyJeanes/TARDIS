$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceLanguageFolder = Join-Path $Root "i18n/languages"
$targetLanguageFolder = Join-Path $Root "lua/tardis/languages"

$targetLanguageFolder | Get-ChildItem | Remove-Item

$originLanguage = Get-Content -Raw (Join-Path $sourceLanguageFolder "en.json") | ConvertFrom-Json -AsHashtable

function Get-AITranslation {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LanguageName,
        [Parameter(Mandatory = $true)]
        [string]$LanguageCode,
        [Parameter(Mandatory = $true)]
        [string]$Phrase
    )

    $openAIKey = $env:TARDIS_OPENAI_API_KEY
    if (-not $openAIKey) {
        Write-Host "Skipping AI translation for $LanguageCode as TARDIS_OPENAI_API_KEY is not set."
        return [string]::Empty
    }

    Write-Host "Retrieving AI translation for ${LanguageCode}: $Phrase"

    $prompt = "Translate the following phrase from English to $LanguageName ($LanguageCode) language: `"$Phrase`". " +
    "Ensure the translation is accurate and idiomatic. " +
    "If you cannot translate it, return an empty string. " +
    "Do not include any additional text or explanations. " +
    "Do not return the original phrase in English, only the translated phrase. " +
    "Punctuation and capitalization should match the original phrase. " +
    "Variable replacement characters e.g. %s must be maintained. " +
    "Do not put a full stop at the end of your response unless the original phrase had one. "

    $body = @{
        model = "gpt-4.1"
        input = @(
            @{
                role    = "user"
                content = @(
                    @{ type = "input_text"; text = $prompt }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/responses" `
        -Headers @{ "Authorization" = "Bearer $openAIKey"; "Content-Type" = "application/json" } `
        -Method Post -Body $body

    $result = $response.output.content.text

    if (-not $result) {
        Write-Warning "AI translation for $LanguageCode returned an empty result"
        return [string]::Empty
    }

    return $response.output.content.text
}

Get-ChildItem $sourceLanguageFolder | ForEach-Object {
    $code = $_.BaseName
    $language = Get-Content -Raw $_.FullName | ConvertFrom-Json -AsHashtable
    $name = $language.Name

    if (-not $language) {
        $language = @{}
    }

    if (-not $language.Name) {
        $language.Name = [string]::Empty
    }

    if (-not $language.Author) {
        $language.Author = [string]::Empty
    }

    if (-not $language.Phrases) {
        $language.Phrases = @{}
    }

    $sortedPhrases = [ordered]@{}
    $phrasesToRemove = @()
    $language.Phrases.Keys | Where-Object { -not $originLanguage.Phrases.Contains($_) } | ForEach-Object {
        Write-Warning "Removing orphaned phrase $_ from language $code"
        $phrasesToRemove += $_
    }
    $phrasesToRemove | ForEach-Object { $language.Phrases.Remove($_) }
    $originLanguage.Phrases.Keys | Sort-Object | ForEach-Object {
        $key = $_
        if ($language.Phrases.Contains($key) -and -not [string]::IsNullOrWhiteSpace($language.Phrases[$key])) {
            $phrase = $language.Phrases[$key]
        }
        else {
            $phrase = Get-AITranslation -LanguageName $name -LanguageCode $code -Phrase $originLanguage.Phrases[$key]
            $language.Phrases[$key] = $phrase
        }
        $sortedPhrases[$key] = $phrase
    }

    $sortedLanguage = [ordered]@{}
    $sortedLanguage.Name = $language.Name
    $sortedLanguage.Author = $language.Author
    $sortedLanguage.Phrases = $sortedPhrases

    $sortedLanguage | ConvertTo-Json | Set-Content -Path $_.FullName

    $targetFilename = Join-Path $targetLanguageFolder "$($code.ToLower()).lua"

    if (-not $language.Name) {
        Write-Warning "Language $code has no name, skipping Lua file generation.."
        return
    }

    if ((-not $language.Phrases) -or ($language.Phrases.Keys.Count -eq 0)) {
        Write-Warning "Language $code has no phrases, skipping Lua file generation.."
        return
    }

    $content = [System.Text.StringBuilder]::new()

    $null = $content.AppendLine("-- AUTO GENERATED FILE - DO NOT EDIT --")
    $null = $content.AppendLine("-- SOURCE FILE: i18n/languages/$($_.Name) --")
    $null = $content.AppendLine()
    $null = $content.AppendLine("local T = {}")
    $null = $content.AppendLine("T.Code = `"$code`"")
    $null = $content.AppendLine("T.Name = `"$($language.Name)`"")
    $null = $content.AppendLine("T.Phrases = {")

    $language.Phrases.Keys | Where-Object { $language.Phrases[$_] } | Sort-Object | ForEach-Object {
        $key = $_
        $phrase = $language.Phrases[$key]
        $phrase = $phrase.Replace("`n", "\n")
        $phrase = $phrase.Replace("`"", "\`"")
        $null = $content.AppendLine("    [`"$key`"] = `"$phrase`",")
    }

    $null = $content.AppendLine("}")
    $null = $content.AppendLine()
    $null = $content.AppendLine("TARDIS:AddLanguage(T)")

    Write-Host "Writing language $code to $targetFilename"

    Set-Content -NoNewline -Path $targetFilename -Value $content
}