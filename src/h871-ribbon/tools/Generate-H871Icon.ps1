param(
    [Parameter(Mandatory = $true)]
    [string]$CustomizationDirectory
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CustomizationDirectory -PathType Container)) {
    throw "Customization directory does not exist: $CustomizationDirectory"
}

Add-Type -AssemblyName System.Drawing

$iconDirectory = Join-Path $CustomizationDirectory "bitmaps\bmp\commands\H871"
New-Item -ItemType Directory -Path $iconDirectory -Force | Out-Null
$iconPath = Join-Path $iconDirectory "part_filter.bmp"

$bitmap = [System.Drawing.Bitmap]::new(32, 32, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::FromArgb(22, 48, 76))

$cyan = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(53, 190, 205))
$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(53, 190, 205), 2.2)

# Simple H mark + filter bars: readable at small toolbar sizes.
$graphics.FillRectangle($cyan, 4, 5, 4, 22)
$graphics.FillRectangle($cyan, 17, 5, 4, 22)
$graphics.FillRectangle($cyan, 4, 14, 17, 4)
$graphics.DrawLine($pen, 23, 8, 28, 8)
$graphics.DrawLine($pen, 25, 8, 25, 24)
$graphics.DrawLine($pen, 22, 24, 28, 24)
$graphics.DrawLine($pen, 22, 20, 28, 20)

$bitmap.Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Bmp)

$pen.Dispose()
$cyan.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "H871 icon created: $iconPath"
