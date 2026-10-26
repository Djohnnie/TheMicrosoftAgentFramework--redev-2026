$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$slideDirectory = Join-Path $repositoryRoot "_slides"
$resourceDirectory = Join-Path $repositoryRoot "_resources"
$slideNames = @("slide-01.svg", "slide-02.svg", "slide-03.svg")
$repositoryUrl = "https://github.com/Djohnnie/TheMicrosoftAgentFramework--redev-2026"

foreach ($slideName in $slideNames) {
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
    if ($slideName -eq "slide-03.svg") {
        if (-not $document.SelectSingleNode("//*[local-name()='a' and @href='$repositoryUrl']")) {
            throw "Slide 3 is missing its repository link."
        }
        $qrGroup = $document.SelectSingleNode("//*[local-name()='g' and @transform='translate(1327 185) scale(0.44921875)']")
        if (-not $qrGroup -or $qrGroup.SelectNodes("./*[local-name()='path']").Count -lt 400) {
            throw "Slide 3 is missing its inline repository QR artwork."
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
