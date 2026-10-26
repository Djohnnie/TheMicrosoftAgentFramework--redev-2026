$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$slideDirectory = Join-Path $repositoryRoot "_slides"
$resourceDirectory = Join-Path $repositoryRoot "_resources"
$slideNames = @("slide-01.svg", "slide-02.svg", "slide-03.svg", "slide-04.svg")
$documentsToValidate = $slideNames + @("slide-template.svg")
$repositoryUrl = "https://github.com/Djohnnie/TheMicrosoftAgentFramework--redev-2026"

foreach ($slideName in $documentsToValidate) {
    $slidePath = Join-Path $slideDirectory $slideName
    if (-not (Test-Path -LiteralPath $slidePath -PathType Leaf)) {
        throw "Missing slide: $slidePath"
    }

    $document = [System.Xml.XmlDocument]::new()
    $document.XmlResolver = $null
    $document.Load($slidePath)

    $root = $document.DocumentElement
    if ($root.GetAttribute("viewBox") -ne "0 0 1920 1080") {
        throw "Unexpected canvas on $slideName; expected a 1920x1080 viewBox."
    }
    if (-not $document.SelectSingleNode("//*[local-name()='title']")) {
        throw "Missing accessible title in $slideName."
    }
    if (-not $document.SelectSingleNode("//*[local-name()='desc']")) {
        throw "Missing accessible description in $slideName."
    }
    $backgroundDots = $document.SelectSingleNode("//*[local-name()='pattern' and @id='background-dots' and @width='32' and @height='32']/*[local-name()='circle' and @r='1.5' and @fill-opacity='.14']")
    $dotOverlay = $document.SelectSingleNode("//*[local-name()='rect' and @width='1920' and @height='1080' and @fill='url(#background-dots)']")
    if (-not $backgroundDots -or -not $dotOverlay) {
        throw "Missing subtle full-canvas dot pattern in $slideName."
    }
    if ($slideName -ne "slide-01.svg") {
        $expectedHeader = switch ($slideName) {
            "slide-02.svg" { "&gt;&gt; THE SPEAKER"; break }
            "slide-03.svg" { "&gt;&gt; TAKE IT WITH YOU"; break }
            "slide-04.svg" { "&gt;&gt; THANK YOU FOR JOINING"; break }
            default { "&gt;&gt; SECTION TITLE" }
        }
        $header = $document.SelectSingleNode("//*[local-name()='text' and @x='88' and @y='86' and @font-size='30' and @fill='#dbf536']")
        if (-not $header -or $header.InnerText -ne $expectedHeader.Replace("&gt;", ">")) {
            throw "Missing doubled, green section header in $slideName."
        }
        $headerPrefix = $header.SelectSingleNode("./*[local-name()='tspan' and @fill='#40f59f']")
        if (-not $headerPrefix -or $headerPrefix.InnerText -ne ">>") {
            throw "Missing Azure-green header prefix in $slideName."
        }
        $zureLogo = $document.SelectSingleNode("//*[local-name()='svg' and @x='1676' and @y='53' and @width='156' and @viewBox='0 0 98 25']")
        if (-not $zureLogo -or $zureLogo.SelectNodes(".//*[local-name()='path']").Count -lt 1) {
            throw "Missing copied Zure logo SVG in $slideName."
        }
    }
    $footerLogo = $document.SelectSingleNode("//*[local-name()='svg' and @x='850' and @y='1009.53' and @width='760' and @height='70.47']")
    if (-not $footerLogo -or $footerLogo.SelectNodes(".//*[local-name()='path']").Count -lt 1) {
        throw "Missing inline footer logo in $slideName."
    }
    if ($slideName -eq "slide-01.svg") {
        $oredevHeader = $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='ØREDEV' and @font-size='51']")
        $locationHeader = $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='MALMÖ · SWEDEN' and @font-size='18']")
        $conferenceHeader = $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='DEVELOPER CONFERENCE' and @font-size='24']")
        $datesHeader = $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='4–6 NOVEMBER 2026' and @font-size='19.5']")
        $zureLogo = $document.SelectSingleNode("//*[local-name()='svg' and @x='1676' and @y='84' and @width='156' and @viewBox='0 0 98 25' and @aria-label='Zure logo']")
        if ($zureLogo -and $zureLogo.SelectNodes(".//*[local-name()='path']").Count -lt 2) {
            $zureLogo = $null
        }
        $speakerName = $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='Johnny Hooyberghs']")
        if (-not $oredevHeader -or -not $locationHeader -or -not $conferenceHeader -or -not $datesHeader -or -not $zureLogo -or -not $speakerName) {
            throw "Missing title-slide event branding, speaker name, or Zure logo."
        }
        if ($document.SelectSingleNode("//*[local-name()='line' and @x1='88' and @x2='1832' and @y1='980' and @y2='980']") -or
            $document.SelectSingleNode("//*[local-name()='a' and @href='$repositoryUrl']") -or
            $document.SelectSingleNode("//*[local-name()='text' and @x='1832' and @y='1054']")) {
            throw "Title slide should not include the standard footer divider, repository link, or slide number."
        }
        $applicationStack = $document.SelectSingleNode("//*[local-name()='g' and @aria-label='The application stack']")
        foreach ($provider in @("Microsoft Foundry", "OpenAI", "Ollama")) {
            if (-not $applicationStack.SelectSingleNode(".//*[local-name()='text' and normalize-space(.)='$provider']")) {
                throw "Missing $provider box in the title-slide application stack."
            }
        }
        foreach ($boxPosition in @("1311,222", "1627,354", "1627,622", "1311,755", "1182,622", "1132,354")) {
            $coordinates = $boxPosition.Split(",")
            if (-not $applicationStack.SelectSingleNode(".//*[local-name()='rect' and @x='$($coordinates[0])' and @y='$($coordinates[1])']")) {
                throw "Missing an evenly spaced application-stack box at $boxPosition."
            }
        }
        if (-not $applicationStack.SelectSingleNode(".//*[local-name()='rect' and @stroke='#dc8ea2']")) {
            throw "Missing the Oredev pink accent in the title-slide application stack."
        }
        if ($applicationStack.SelectSingleNode("./*[local-name()='circle' and @r='8']") -or
            $applicationStack.SelectSingleNode("./*[local-name()='path']") -or
            $applicationStack.SelectSingleNode("./*[local-name()='circle' and @stroke-dasharray]")) {
            throw "The title-slide application stack should not include decorative dots or curves."
        }
    } else {
        if (-not $document.SelectSingleNode("//*[local-name()='line' and @x1='88' and @x2='1832' and @y1='980' and @y2='980']")) {
            throw "Missing standard footer divider in $slideName."
        }
        $footerLink = $document.SelectNodes("//*[local-name()='a' and @href='$repositoryUrl']") |
            Where-Object { $_.InnerText -eq $repositoryUrl } |
            Select-Object -First 1
        if (-not $footerLink) {
            throw "Missing standard repository footer link in $slideName."
        }
        $pageNumber = $document.SelectSingleNode("//*[local-name()='text' and @x='1832' and @y='1054' and @fill='#dbf536']")
        if (-not $pageNumber -or $pageNumber.InnerText -notmatch '^\d{2} / 04$') {
            throw "Missing green slide number in the expected format in $slideName."
        }
    }
    if ($slideName -eq "slide-03.svg") {
        if (-not $document.SelectSingleNode("//*[local-name()='a' and @href='$repositoryUrl']")) {
            throw "Slide 3 is missing its repository link."
        }
        if ($document.SelectSingleNode("//*[local-name()='rect' and @x='1192' and @y='0' and @width='728' and @height='1080' and @fill='#dbf536']")) {
            throw "Slide 3 should not include the green panel behind the QR code."
        }
        $qrGroup = $document.SelectSingleNode("//*[local-name()='g' and @transform='translate(1167 195) scale(0.52734375)']")
        if (-not $qrGroup -or $qrGroup.SelectNodes("./*[local-name()='path']").Count -lt 400) {
            throw "Slide 3 is missing its inline repository QR artwork."
        }
        if ($qrGroup.SelectSingleNode(".//*[local-name()='image']")) {
            throw "Slide 3 should copy the QR SVG content instead of embedding it as an image."
        }
    }
    if ($slideName -eq "slide-04.svg") {
        foreach ($closingText in @("Questions?", "Thanks for being part of the conversation.", "What questions can I answer?")) {
            if (-not $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='$closingText']")) {
                throw "Slide 4 is missing closing-slide text: $closingText"
            }
        }
        if ($document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='Thank you']") -or
            $document.SelectSingleNode("//*[local-name()='text' and normalize-space(.)='for joining']")) {
            throw "Slide 4 should keep the thank-you message in the header, not the title."
        }
        $questionTitle = $document.SelectSingleNode("//*[local-name()='text' and @x='88' and @y='432' and @class='display' and normalize-space(.)='Questions?']")
        if (-not $questionTitle) {
            throw "Slide 4 title should be Questions?."
        }
        $qrGroup = $document.SelectSingleNode("//*[local-name()='g' and @transform='translate(1167 195) scale(0.52734375)']")
        if (-not $qrGroup -or $qrGroup.SelectNodes("./*[local-name()='path']").Count -lt 400 -or $qrGroup.SelectSingleNode(".//*[local-name()='image']")) {
            throw "Slide 4 is missing its inline repository QR artwork."
        }
    }
    if ($slideName -eq "slide-02.svg") {
        $speakerImage = $document.SelectSingleNode("//*[local-name()='image' and starts-with(@href, 'data:image/jpeg;base64,') and @clip-path='url(#speaker-photo-clip)']")
        if (-not $speakerImage) {
            throw "Slide 2 is missing its embedded, clipped speaker photo."
        }
        try {
            $imageBytes = [Convert]::FromBase64String($speakerImage.GetAttribute("href").Substring("data:image/jpeg;base64,".Length))
        } catch {
            throw "Slide 2 contains an invalid embedded speaker photo."
        }
        if ($imageBytes.Length -lt 4 -or $imageBytes[0] -ne 0xFF -or $imageBytes[1] -ne 0xD8 -or $imageBytes[2] -ne 0xFF) {
            throw "Slide 2's embedded speaker photo is not a valid JPEG."
        }
        $belgiumImage = $document.SelectSingleNode("//*[local-name()='image' and starts-with(@href, 'data:image/png;base64,') and @filter='url(#belgium-oredev)']")
        if (-not $belgiumImage) {
            throw "Slide 2 is missing its inline, theme-colored Belgium map."
        }
        try {
            $mapBytes = [Convert]::FromBase64String($belgiumImage.GetAttribute("href").Substring("data:image/png;base64,".Length))
        } catch {
            throw "Slide 2 contains invalid embedded Belgium map data."
        }
        if ($mapBytes.Length -lt 8 -or $mapBytes[0] -ne 0x89 -or $mapBytes[1] -ne 0x50 -or $mapBytes[2] -ne 0x4E -or $mapBytes[3] -ne 0x47) {
            throw "Slide 2's embedded Belgium map is not a valid PNG."
        }
    }

    Write-Output "Valid SVG: $slideName"
}

$qrPath = Join-Path $resourceDirectory "qrcode.svg"
if (-not (Test-Path -LiteralPath $qrPath -PathType Leaf)) {
    throw "Missing repository QR asset: $qrPath"
}

$qrDocument = [System.Xml.XmlDocument]::new()
$qrDocument.XmlResolver = $null
$qrDocument.Load($qrPath)
if ($qrDocument.DocumentElement.LocalName -ne "svg") {
    throw "Repository QR asset is not an SVG document."
}
Write-Output "Valid SVG: _resources\qrcode.svg"

Write-Output "Valid embedded JPEG: slide-02.svg"
Write-Output "Valid embedded Belgium PNG: slide-02.svg"
