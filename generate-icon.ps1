Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = $scriptDir
$outDir = Join-Path $repoRoot 'images'
$outPath = Join-Path $outDir 'icon.png'

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

# System.Drawing is supported on Windows. This generates a simple, clean 128x128 PNG.
Add-Type -AssemblyName System.Drawing

$size = 128
$bmp = New-Object System.Drawing.Bitmap $size, $size
$gfx = [System.Drawing.Graphics]::FromImage($bmp)

try
{
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $bg = [System.Drawing.Color]::FromArgb(255, 17, 24, 39)      # dark slate
    $accent = [System.Drawing.Color]::FromArgb(255, 56, 189, 248) # sky
    $fg = [System.Drawing.Color]::FromArgb(255, 243, 244, 246)    # near-white

    $gfx.Clear($bg)

    # Accent stripe
    $stripeBrush = New-Object System.Drawing.SolidBrush $accent
    $gfx.FillRectangle($stripeBrush, 0, 0, 10, $size)

    # Main mark: "{:" + "}" to evoke Kramdown IAL
    $fontMain = New-Object System.Drawing.Font('Consolas', 44, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fontSub = New-Object System.Drawing.Font('Consolas', 20, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brushFg = New-Object System.Drawing.SolidBrush $fg

    $mainText = '{:'
    $endText = '}'

    $mainSize = $gfx.MeasureString($mainText, $fontMain)
    $endSize = $gfx.MeasureString($endText, $fontMain)

    $xMain = [Math]::Round(($size - ($mainSize.Width + $endSize.Width - 8)) / 2)
    $yMain = 28

    $gfx.DrawString($mainText, $fontMain, $brushFg, $xMain, $yMain)
    $gfx.DrawString($endText, $fontMain, $brushFg, $xMain + $mainSize.Width - 8, $yMain)

    # Sub label
    $subText = 'IAL'
    $subSize = $gfx.MeasureString($subText, $fontSub)
    $xSub = [Math]::Round(($size - $subSize.Width) / 2)
    $ySub = 86
    $gfx.DrawString($subText, $fontSub, $brushFg, $xSub, $ySub)

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host ("Wrote: {0}" -f $outPath) -ForegroundColor Green
}
finally
{
    if ($null -ne $stripeBrush) { $stripeBrush.Dispose() }
    if ($null -ne $brushFg) { $brushFg.Dispose() }
    if ($null -ne $fontMain) { $fontMain.Dispose() }
    if ($null -ne $fontSub) { $fontSub.Dispose() }
    if ($null -ne $gfx) { $gfx.Dispose() }
    if ($null -ne $bmp) { $bmp.Dispose() }
}
