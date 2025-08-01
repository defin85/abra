# Создание временной PNG иконки для тестирования
# Простая иконка с градиентом и буквой A

Add-Type -AssemblyName System.Drawing

# Создаем bitmap
$bitmap = New-Object System.Drawing.Bitmap 512, 512

# Создаем Graphics объект
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Заливаем фон градиентом
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0),
    [System.Drawing.Point]::new(512, 512),
    [System.Drawing.Color]::FromArgb(74, 144, 226),  # #4A90E2
    [System.Drawing.Color]::FromArgb(46, 92, 184)    # #2E5CB8
)

# Рисуем круг
$graphics.FillEllipse($brush, 0, 0, 512, 512)

# Рисуем букву A
$font = New-Object System.Drawing.Font("Arial", 200, [System.Drawing.FontStyle]::Bold)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center

$graphics.DrawString("A", $font, $textBrush, 256, 256, $format)

# Сохраняем как PNG
$outputPath = Join-Path $PSScriptRoot "assets\icons\app_icon.png"
$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Освобождаем ресурсы
$graphics.Dispose()
$bitmap.Dispose()
$brush.Dispose()
$textBrush.Dispose()
$font.Dispose()

Write-Host "Временная иконка создана: $outputPath"
Write-Host "Теперь запустите: flutter pub run flutter_launcher_icons"