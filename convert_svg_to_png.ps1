# PowerShell скрипт для создания PNG из вашего SVG
# Использует .NET для рендеринга

Add-Type -AssemblyName System.Drawing

# Создаем bitmap 1024x1024 для высокого качества
$bitmap = New-Object System.Drawing.Bitmap 1024, 1024
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Розовый градиент как в вашем SVG
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0),
    [System.Drawing.Point]::new(1024, 1024),
    [System.Drawing.Color]::FromArgb(243, 92, 181),  # #F35CB5
    [System.Drawing.Color]::FromArgb(236, 0, 140)    # #EC008C
)

# Рисуем круг
$graphics.FillEllipse($brush, 0, 0, 1024, 1024)

# Рисуем белые элементы (упрощенная версия)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 20)

# Карандаш (диагональная линия)
$graphics.DrawLine($pen, 300, 300, 600, 600)

# Линейка (горизонтальная линия с отметками)
$graphics.DrawLine($pen, 200, 512, 824, 512)
# Отметки на линейке
for ($i = 0; $i -lt 5; $i++) {
    $x = 300 + ($i * 100)
    $graphics.DrawLine($pen, $x, 490, $x, 534)
}

# Угольник (прямой угол)
$graphics.DrawLine($pen, 400, 700, 400, 400)
$graphics.DrawLine($pen, 400, 400, 700, 400)

# Сохраняем как PNG
$outputPath = Join-Path $PSScriptRoot "assets\icons\app_icon.png"
$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Освобождаем ресурсы
$graphics.Dispose()
$bitmap.Dispose()
$brush.Dispose()
$whiteBrush.Dispose()
$pen.Dispose()

Write-Host "Иконка создана: $outputPath"