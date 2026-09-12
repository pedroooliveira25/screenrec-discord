# ScreenRec - app com botao (WinForms). Tema Pathbit: roxo + preto, cantos arredondados.
# Se existir assets\logo.png, ele aparece no cabecalho. Senao, vale o wordmark PATHBIT.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. (Join-Path $PSScriptRoot "proxy-manager.ps1")

$trapLog = Join-Path (Split-Path -Parent $PSScriptRoot) "erro.log"
trap {
    $detail = (Get-Date).ToString("o") + "`r`n" + $_.Exception.ToString() + "`r`n---`r`n"
    Add-Content -LiteralPath $trapLog -Value $detail -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show(
        "O app encontrou um problema e salvou os detalhes em erro.log. Me manda esse arquivo que eu corrijo.",
        "ScreenRec", "OK", "Error") | Out-Null
    continue
}

$BG      = [System.Drawing.ColorTranslator]::FromHtml("#0B0B10")
$CARD    = [System.Drawing.ColorTranslator]::FromHtml("#14141C")
$FIELD   = [System.Drawing.ColorTranslator]::FromHtml("#1C1C26")
$FOCUS   = [System.Drawing.ColorTranslator]::FromHtml("#2A2140")
$ROXO    = [System.Drawing.ColorTranslator]::FromHtml("#7C3AED")
$ROXOHOV = [System.Drawing.ColorTranslator]::FromHtml("#8B5CF6")
$LILAS   = [System.Drawing.ColorTranslator]::FromHtml("#C4B5FD")
$BRANCO  = [System.Drawing.Color]::White
$CINZA   = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
$VERDE   = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")
$VERM    = [System.Drawing.ColorTranslator]::FromHtml("#EF4444")
$VERMESC = [System.Drawing.ColorTranslator]::FromHtml("#B91C1C")

function New-RoundedPath([System.Drawing.Rectangle]$r, [int]$rad) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $rad * 2
    $p.AddArc($r.X, $r.Y, $d, $d, 180, 90)
    $p.AddArc($r.Right - $d, $r.Y, $d, $d, 270, 90)
    $p.AddArc($r.Right - $d, $r.Bottom - $d, $d, $d, 0, 90)
    $p.AddArc($r.X, $r.Bottom - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Set-Rounded($c, [int]$rad) {
    if ($c.Region) { $c.Region.Dispose() }
    $rect = New-Object System.Drawing.Rectangle(0, 0, $c.Width, $c.Height)
    $c.Region = New-Object System.Drawing.Region((New-RoundedPath $rect $rad))
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "ScreenRec - Pathbit"
$form.Size = New-Object System.Drawing.Size(460, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "None"
$form.BackColor = $BG
$form.ForeColor = $BRANCO
Set-Rounded $form 20

# --- Cabecalho (arrastavel) ---
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(460, 110)
$header.BackColor = $BG
$form.Controls.Add($header)

$logoBox = New-Object System.Windows.Forms.PictureBox
$logoBox.Location = New-Object System.Drawing.Point(24, 26)
$logoBox.Size = New-Object System.Drawing.Size(56, 56)
$logoBox.SizeMode = "Zoom"
$logoFile = Join-Path (Split-Path -Parent $PSScriptRoot) "assets\logo.png"
$hasLogo = $false
if (Test-Path -LiteralPath $logoFile) {
    try { $logoBox.Image = [System.Drawing.Image]::FromFile($logoFile); $hasLogo = $true } catch { }
}
if ($hasLogo) { $header.Controls.Add($logoBox) }

$brandX = 24
if ($hasLogo) { $brandX = 92 }

$fontBrand = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "PATH"
$lblPath.Font = $fontBrand
$lblPath.ForeColor = $BRANCO
$lblPath.Location = New-Object System.Drawing.Point($brandX, 20)
$lblPath.AutoSize = $true
$header.Controls.Add($lblPath)
$wPath = $lblPath.GetPreferredSize([System.Drawing.Size]::Empty).Width

$lblBit = New-Object System.Windows.Forms.Label
$lblBit.Text = "BIT"
$lblBit.Font = $fontBrand
$lblBit.ForeColor = $ROXOHOV
$lblBit.Location = New-Object System.Drawing.Point(($brandX + $wPath - 2), 20)
$lblBit.AutoSize = $true
$header.Controls.Add($lblBit)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "screenrec  -  discord por sala"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = $CINZA
$lblSub.Location = New-Object System.Drawing.Point(($brandX + 2), 66)
$lblSub.AutoSize = $true
$header.Controls.Add($lblSub)

$btnX = New-Object System.Windows.Forms.Button
$btnX.Text = "X"
$btnX.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnX.ForeColor = $CINZA
$btnX.BackColor = $BG
$btnX.FlatStyle = "Flat"
$btnX.FlatAppearance.BorderSize = 0
$btnX.Size = New-Object System.Drawing.Size(40, 36)
$btnX.Location = New-Object System.Drawing.Point(410, 8)
$header.Controls.Add($btnX)
$btnX.Add_Click({ $form.Close() })

# Arrastar a janela pelo cabecalho
$drag = @{ on = $false; x = 0; y = 0 }
$header.Add_MouseDown({
    $drag.on = $true
    $drag.x = [System.Windows.Forms.Cursor]::Position.X - $form.Location.X
    $drag.y = [System.Windows.Forms.Cursor]::Position.Y - $form.Location.Y
})
$header.Add_MouseMove({
    if ($drag.on) {
        $form.Location = New-Object System.Drawing.Point(
            ([System.Windows.Forms.Cursor]::Position.X - $drag.x),
            ([System.Windows.Forms.Cursor]::Position.Y - $drag.y))
    }
})
$header.Add_MouseUp({ $drag.on = $false })

# --- Corpo ---
$lblReg = New-Object System.Windows.Forms.Label
$lblReg.Text = "SALA"
$lblReg.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblReg.ForeColor = $CINZA
$lblReg.Location = New-Object System.Drawing.Point(28, 128)
$lblReg.AutoSize = $true
$form.Controls.Add($lblReg)

$comboWrap = New-Object System.Windows.Forms.Panel
$comboWrap.Location = New-Object System.Drawing.Point(28, 150)
$comboWrap.Size = New-Object System.Drawing.Size(404, 40)
$comboWrap.BackColor = $FIELD
Set-Rounded $comboWrap 10
$form.Controls.Add($comboWrap)

$combo = New-Object System.Windows.Forms.ComboBox
$combo.Location = New-Object System.Drawing.Point(8, 6)
$combo.Size = New-Object System.Drawing.Size(388, 28)
$combo.DropDownStyle = "DropDownList"
$combo.FlatStyle = "Flat"
$combo.BackColor = $FIELD
$combo.ForeColor = $BRANCO
$combo.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$comboWrap.Controls.Add($combo)
$combo.Add_Enter({ $comboWrap.BackColor = $FOCUS })
$combo.Add_Leave({ $comboWrap.BackColor = $FIELD })

$regionInfo = @{}
try {
    $items = Get-Regions
    foreach ($it in $items) {
        [void]$combo.Items.Add($it.nome)
        $regionInfo[$it.nome] = [string]$it.descricao + "  (" + [string]$it.proxy + ")"
    }
    $def = $combo.Items.IndexOf("pathbit")
    if ($def -ge 0) { $combo.SelectedIndex = $def }
    elseif ($combo.Items.Count -gt 0) { $combo.SelectedIndex = 0 }
} catch {
    [void]$combo.Items.Add("(edite config/regions.json)")
    $combo.SelectedIndex = 0
}

$lblDesc = New-Object System.Windows.Forms.Label
$lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblDesc.ForeColor = $CINZA
$lblDesc.Location = New-Object System.Drawing.Point(28, 194)
$lblDesc.Size = New-Object System.Drawing.Size(404, 40)
$form.Controls.Add($lblDesc)

function Refresh-Desc {
    $n = [string]$combo.SelectedItem
    if ($regionInfo.ContainsKey($n)) { $lblDesc.Text = $regionInfo[$n] }
    else { $lblDesc.Text = "" }
}
$combo.Add_SelectedIndexChanged({ Refresh-Desc; Refresh-Auth })
Refresh-Desc

$lblAuth = New-Object System.Windows.Forms.Label
$lblAuth.Text = "SENHA DO PROXY (opcional)"
$lblAuth.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblAuth.ForeColor = $CINZA
$lblAuth.Location = New-Object System.Drawing.Point(28, 238)
$lblAuth.AutoSize = $true
$form.Controls.Add($lblAuth)

$passWrap = New-Object System.Windows.Forms.Panel
$passWrap.Location = New-Object System.Drawing.Point(28, 258)
$passWrap.Size = New-Object System.Drawing.Size(238, 30)
$passWrap.BackColor = $FIELD
Set-Rounded $passWrap 10
$form.Controls.Add($passWrap)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(12, 5)
$txtPass.Size = New-Object System.Drawing.Size(214, 20)
$txtPass.BorderStyle = "None"
$txtPass.BackColor = $FIELD
$txtPass.ForeColor = $BRANCO
$txtPass.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$txtPass.UseSystemPasswordChar = $true
$passWrap.Controls.Add($txtPass)
$txtPass.Add_Enter({ $passWrap.BackColor = $FOCUS; $txtPass.BackColor = $FOCUS })
$txtPass.Add_Leave({ $passWrap.BackColor = $FIELD; $txtPass.BackColor = $FIELD })

$btnEye = New-Object System.Windows.Forms.Button
$btnEye.Text = "VER"
$btnEye.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnEye.ForeColor = $LILAS
$btnEye.BackColor = $FIELD
$btnEye.FlatStyle = "Flat"
$btnEye.FlatAppearance.BorderSize = 0
$btnEye.Location = New-Object System.Drawing.Point(270, 259)
$btnEye.Size = New-Object System.Drawing.Size(44, 28)
Set-Rounded $btnEye 8
$form.Controls.Add($btnEye)
$btnEye.Add_Click({
    if ($txtPass.UseSystemPasswordChar) {
        $txtPass.UseSystemPasswordChar = $false
        $btnEye.Text = "OCULTAR"
    } else {
        $txtPass.UseSystemPasswordChar = $true
        $btnEye.Text = "VER"
    }
})

$chkSave = New-Object System.Windows.Forms.CheckBox
$chkSave.Text = "Salvar senha"
$chkSave.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$chkSave.ForeColor = $CINZA
$chkSave.BackColor = $BG
$chkSave.Location = New-Object System.Drawing.Point(318, 260)
$chkSave.Size = New-Object System.Drawing.Size(114, 24)
$form.Controls.Add($chkSave)

function Refresh-Auth {
    $n = [string]$combo.SelectedItem
    $pw = Get-AuthPass $n
    if ($pw -ne "") { $txtPass.Text = $pw; $chkSave.Checked = $true }
    else { $txtPass.Text = ""; $chkSave.Checked = $false }
}
Refresh-Auth

$btnOn = New-Object System.Windows.Forms.Button
$btnOn.Text = "LIGAR SALA"
$btnOn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnOn.ForeColor = $BRANCO
$btnOn.BackColor = $ROXO
$btnOn.FlatStyle = "Flat"
$btnOn.FlatAppearance.BorderSize = 0
$btnOn.Location = New-Object System.Drawing.Point(28, 296)
$btnOn.Size = New-Object System.Drawing.Size(196, 52)
Set-Rounded $btnOn 16
$form.Controls.Add($btnOn)
$btnOn.Add_MouseEnter({ $btnOn.BackColor = $ROXOHOV })
$btnOn.Add_MouseLeave({ $btnOn.BackColor = $ROXO })

$btnOff = New-Object System.Windows.Forms.Button
$btnOff.Text = "DESLIGAR"
$btnOff.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnOff.ForeColor = $BRANCO
$btnOff.BackColor = $VERMESC
$btnOff.FlatStyle = "Flat"
$btnOff.FlatAppearance.BorderSize = 0
$btnOff.Location = New-Object System.Drawing.Point(236, 296)
$btnOff.Size = New-Object System.Drawing.Size(196, 52)
Set-Rounded $btnOff 16
$form.Controls.Add($btnOff)
$btnOff.Add_MouseEnter({ $btnOff.BackColor = $VERM })
$btnOff.Add_MouseLeave({ $btnOff.BackColor = $VERMESC })

# --- Barra de loading verde (arredondada) ---
$track = New-Object System.Windows.Forms.Panel
$track.Location = New-Object System.Drawing.Point(28, 354)
$track.Size = New-Object System.Drawing.Size(404, 12)
$track.BackColor = $FIELD
Set-Rounded $track 6
$track.Visible = $false
$form.Controls.Add($track)

$fill = New-Object System.Windows.Forms.Panel
$fill.Location = New-Object System.Drawing.Point(2, 2)
$fill.Size = New-Object System.Drawing.Size(0, 8)
$fill.BackColor = $VERDE
$track.Controls.Add($fill)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 30
$timer.Add_Tick({
    $fill.Width = $fill.Width + 14
    if ($fill.Width -ge 400) { $fill.Width = 0 }
})

function Show-Loading([bool]$on) {
    $btnOn.Enabled = -not $on
    $btnOff.Enabled = -not $on
    $track.Visible = $on
    if ($on) { $fill.Width = 0; $timer.Start() } else { $timer.Stop() }
}

# --- Cartao de status (arredondado) ---
$cardPanel = New-Object System.Windows.Forms.Panel
$cardPanel.Location = New-Object System.Drawing.Point(28, 372)
$cardPanel.Size = New-Object System.Drawing.Size(404, 110)
$cardPanel.BackColor = $CARD
Set-Rounded $cardPanel 14
$form.Controls.Add($cardPanel)

$dot = New-Object System.Windows.Forms.Panel
$dot.Size = New-Object System.Drawing.Size(14, 14)
$dot.Location = New-Object System.Drawing.Point(16, 18)
$dot.BackColor = $CINZA
$cardPanel.Controls.Add($dot)

$lblStTitle = New-Object System.Windows.Forms.Label
$lblStTitle.Text = "STATUS"
$lblStTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblStTitle.ForeColor = $CINZA
$lblStTitle.Location = New-Object System.Drawing.Point(40, 15)
$lblStTitle.AutoSize = $true
$cardPanel.Controls.Add($lblStTitle)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Normal (sem proxy)"
$status.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$status.ForeColor = $BRANCO
$status.Location = New-Object System.Drawing.Point(16, 46)
$status.Size = New-Object System.Drawing.Size(372, 54)
$cardPanel.Controls.Add($status)

function Set-Status([string]$Texto, [string]$Cor) {
    $status.Text = $Texto
    if ($Cor -eq "verde") { $dot.BackColor = $VERDE }
    elseif ($Cor -eq "vermelho") { $dot.BackColor = $VERM }
    else { $dot.BackColor = $CINZA }
}

$st = Get-State
if ($st -and $st.ativo) {
    Set-Status ("ATIVO - " + [string]$st.regiao + " (" + [string]$st.proxy + ")") "verde"
}

$btnOn.Add_Click({
    $ErrorActionPreference = "Stop"
    Show-Loading $true
    try {
        $nome = $combo.SelectedItem.ToString()
        $pw = $txtPass.Text
        if ($chkSave.Checked -and $pw -ne "") { Save-Auth $nome $pw }
        elseif (-not $chkSave.Checked) { Clear-Auth $nome }
        $p = Start-RegionProxy -Regiao $nome -Pass $pw
        $rNome = $nome; $rProxy = [string]$p
        if ($p -is [hashtable] -and $p.ContainsKey("Regiao")) { $rNome = [string]$p.Regiao; $rProxy = [string]$p.Proxy }
        $msg = ("ATIVO - " + $rNome + " (" + $rProxy + "). Discord reiniciado com proxy.")
        if ($p -is [hashtable] -and $p.Trocou) { $msg = ("ATIVO - " + $rNome + " (" + $rProxy + "). O '" + $nome + "' não respondeu em 30s, troquei sozinho.") }
        Set-Status $msg "verde"
    } catch {
        Set-Status ("Erro: " + $_.Exception.Message) "vermelho"
    } finally {
        Show-Loading $false
    }
})

$btnOff.Add_Click({
    $ErrorActionPreference = "Stop"
    Show-Loading $true
    try {
        Stop-RegionProxy
        $form.Close()
    } catch {
        Set-Status ("Erro: " + $_.Exception.Message) "vermelho"
    } finally {
        Show-Loading $false
    }
})

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Fechar a janela restaura o Discord sozinho."
$lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblHint.ForeColor = $CINZA
$lblHint.Location = New-Object System.Drawing.Point(28, 494)
$lblHint.AutoSize = $true
$form.Controls.Add($lblHint)

$lblFoot = New-Object System.Windows.Forms.Label
$lblFoot.Text = "pathbit.com.br"
$lblFoot.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblFoot.ForeColor = $ROXOHOV
$lblFoot.Location = New-Object System.Drawing.Point(28, 514)
$lblFoot.AutoSize = $true
$form.Controls.Add($lblFoot)

# Faixa roxa inferior acompanhando o arredondamento
$bar = New-Object System.Windows.Forms.Panel
$bar.Location = New-Object System.Drawing.Point(28, 552)
$bar.Size = New-Object System.Drawing.Size(404, 4)
$bar.BackColor = $ROXO
$form.Controls.Add($bar)

# Fechar a janela restaura automaticamente.
$form.Add_FormClosing({
    try {
        $s = Get-State
        if ($s -and $s.ativo) { Stop-RegionProxy }
    } catch { }
})

$logFile = Join-Path (Split-Path -Parent $PSScriptRoot) "erro.log"
try {
    [void]$form.ShowDialog()
} catch {
    $detail = (Get-Date).ToString("o") + "`r`n" + $_.Exception.ToString() + "`r`n---`r`n"
    Add-Content -LiteralPath $logFile -Value $detail -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show(
        "O app encontrou um problema e salvou os detalhes em erro.log. Me manda esse arquivo que eu corrijo.",
        "ScreenRec", "OK", "Error") | Out-Null
}
