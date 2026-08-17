param(
    [string]$Message = "IA_Life : J'ai fini"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.ShowInTaskbar = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = $Message
$label.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 200)
$label.Font = New-Object System.Drawing.Font("Consolas", 54, [System.Drawing.FontStyle]::Bold)
$label.AutoSize = $false
$label.Dock = 'Fill'
$label.TextAlign = 'MiddleCenter'
$form.Controls.Add($label)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({
    $timer.Stop()
    $form.Close()
})
$form.Add_Shown({ $timer.Start() })

[System.Windows.Forms.Application]::Run($form)
