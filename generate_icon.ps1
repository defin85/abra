# PowerShell скрипт для генерации PNG иконки из SVG
# Использует Windows Presentation Foundation для рендеринга SVG

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

function Convert-SvgToPng {
    param(
        [string]$svgPath,
        [string]$pngPath,
        [int]$width = 1024,
        [int]$height = 1024
    )
    
    # Читаем SVG
    $svgContent = Get-Content $svgPath -Raw
    
    # Создаем временный XAML с SVG
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="$width" Height="$height">
    <Viewbox Width="$width" Height="$height">
        <Grid>
            <Rectangle Width="$width" Height="$height" Fill="Transparent"/>
            <Image Source="$svgPath" Width="$width" Height="$height"/>
        </Grid>
    </Viewbox>
</Window>
"@
    
    # Альтернативный метод - использование Inkscape если установлен
    $inkscapePath = "C:\Program Files\Inkscape\bin\inkscape.exe"
    if (Test-Path $inkscapePath) {
        Write-Host "Используем Inkscape для конвертации..."
        & $inkscapePath -w $width -h $height $svgPath -o $pngPath
        return
    }
    
    # Если Inkscape не найден, используем альтернативный метод
    Write-Host "Inkscape не найден. Используйте один из следующих методов:"
    Write-Host "1. Установите Inkscape: https://inkscape.org/release/"
    Write-Host "2. Используйте онлайн конвертер: https://cloudconvert.com/svg-to-png"
    Write-Host "3. Откройте generate_icon.html в браузере для генерации PNG"
}

# Основной процесс
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$svgPath = Join-Path $scriptPath "assets\icons\app_icon_new.svg"
$pngPath = Join-Path $scriptPath "assets\icons\app_icon_new.png"

if (Test-Path $svgPath) {
    Write-Host "Конвертируем $svgPath в PNG..."
    Convert-SvgToPng -svgPath $svgPath -pngPath $pngPath -width 1024 -height 1024
} else {
    Write-Host "SVG файл не найден: $svgPath"
}