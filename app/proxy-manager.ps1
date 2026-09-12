# proxy-manager.ps1 — aplica/restaura proxy SÓ no Discord (padrão).
# Sistema inteiro só via -SystemWide (opcional).
Add-Type -AssemblyName System.Windows.Forms

$RootDir  = Split-Path -Parent $PSScriptRoot
$StateFile = Join-Path $RootDir ".state.json"
$ConfigFile = Join-Path $RootDir "config\regions.json"
$AuthFile = Join-Path $RootDir ".auth.json"
$RelayPort = 18081
$ProxyTimeoutSec = 60
$ProxyMaxRetries = 2
$ProxyTestUrl = "http://ip-api.com/json/?fields=status,query"

function Get-Regions {
    if (-not (Test-Path -LiteralPath $ConfigFile)) { throw "Config não achada: $ConfigFile" }
    $json = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
    return $json.regioes
}

function Get-RegionProxy([string]$Nome) {
    $r = (Get-Regions) | Where-Object { $_.nome -eq $Nome } | Select-Object -First 1
    if (-not $r) { throw "Região '$Nome' não cadastrada em config/regions.json" }
    return $r.proxy
}

function Get-DiscordExe {
    # Direto no Discord.exe da pasta app-*: garante que a flag --proxy-server
    # chega no Electron. (Via Update.exe o Squirrel pode engolir flags extras
    # e o Discord abrir sem proxy, parecendo que "nao funcionou".)
    $base = Join-Path $env:LOCALAPPDATA "Discord"
    $cand = Get-ChildItem -LiteralPath $base -Filter "Discord.exe" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*app-*" } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($cand) { return $cand.FullName }
    $update = Join-Path $base "Update.exe"
    if (Test-Path -LiteralPath $update) { return $update }
    throw "Discord não encontrado em $base"
}

function Stop-Discord {
    Get-Process -Name "Discord" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    # Espera o processo morrer de verdade (senao o novo launch gruda na instancia velha).
    for ($i = 0; $i -lt 10; $i++) {
        if (-not (Get-Process -Name "Discord" -ErrorAction SilentlyContinue)) { break }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 500
    }
}

function Start-DiscordClean {
    $exe = Get-DiscordExe
    $wd = Split-Path -Parent $exe
    if ($exe -like "*Update.exe") {
        Start-Process -FilePath $exe -ArgumentList "--processStart", "Discord.exe" -WorkingDirectory $wd
    } else {
        Start-Process -FilePath $exe -WorkingDirectory $wd
    }
}

function Start-DiscordWithProxy([string]$ProxyUrl) {
    $exe = Get-DiscordExe
    # Flag Chromium/Electron: todo o tráfego do Discord passa pelo proxy.
    $flag = "--proxy-server=$ProxyUrl"
    Stop-Discord
    $wd = Split-Path -Parent $exe
    if ($exe -like "*Update.exe") {
        Start-Process -FilePath $exe -ArgumentList "--processStart", "Discord.exe", "--", $flag -WorkingDirectory $wd
    } else {
        Start-Process -FilePath $exe -ArgumentList $flag -WorkingDirectory $wd
    }
}

function Save-State([string]$Regiao, [string]$Proxy) {
    @{ ativo = $true; regiao = $Regiao; proxy = $Proxy; desde = (Get-Date).ToString("o") } |
        ConvertTo-Json | Set-Content -LiteralPath $StateFile -Encoding UTF8
}

function Clear-State {
    if (Test-Path -LiteralPath $StateFile) { Remove-Item -LiteralPath $StateFile -Force }
}

function Get-State {
    if (-not (Test-Path -LiteralPath $StateFile)) { return $null }
    try { return (Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json) }
    catch { return $null }
}

function Get-RegionUser([string]$Nome) {
    $r = (Get-Regions) | Where-Object { $_.nome -eq $Nome } | Select-Object -First 1
    if ($r -and $r.usuario) { return [string]$r.usuario }
    return ""
}

function Ensure-RelayType {
    if (-not ([System.Management.Automation.PSTypeName]'ProxyRelay').Type) {
        $cs = Get-Content -LiteralPath (Join-Path $PSScriptRoot "ProxyRelay.cs") -Raw
        Add-Type -TypeDefinition $cs -Language CSharp
    }
}

function Save-Auth([string]$Regiao, [string]$Pass) {
    $all = @{}
    if (Test-Path -LiteralPath $AuthFile) {
        try {
            $j = Get-Content -LiteralPath $AuthFile -Raw | ConvertFrom-Json
            foreach ($p in $j.PSObject.Properties) {
                $all[$p.Name] = @{ user = [string]$p.Value.user; pass = [string]$p.Value.pass }
            }
        } catch { $all = @{} }
    }
    $enc = ConvertFrom-SecureString (ConvertTo-SecureString $Pass -AsPlainText -Force)
    $all[$Regiao] = @{ user = ""; pass = $enc }
    $all | ConvertTo-Json | Set-Content -LiteralPath $AuthFile -Encoding UTF8
}

function Get-AuthPass([string]$Regiao) {
    if (-not (Test-Path -LiteralPath $AuthFile)) { return "" }
    try {
        $j = Get-Content -LiteralPath $AuthFile -Raw | ConvertFrom-Json
        $e = $j.$Regiao
        if (-not $e -or -not $e.pass) { return "" }
        # DPAPI: senha salva em outro PC/usuario nao descriptografa aqui.
        # Retorna vazio para o usuario digitar de novo, sem quebrar o app.
        $sec = ConvertTo-SecureString ([string]$e.pass)
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr) }
        finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    } catch { return "" }
}

function Clear-Auth([string]$Regiao) {
    if (-not (Test-Path -LiteralPath $AuthFile)) { return }
    try {
        $j = Get-Content -LiteralPath $AuthFile -Raw | ConvertFrom-Json
    $all = @{}
    foreach ($p in $j.PSObject.Properties) {
        if ($p.Name -ne $Regiao) {
            $all[$p.Name] = @{ user = [string]$p.Value.user; pass = [string]$p.Value.pass }
        }
    }
    if ($all.Count -eq 0) { Remove-Item -LiteralPath $AuthFile -Force }
    else { $all | ConvertTo-Json | Set-Content -LiteralPath $AuthFile -Encoding UTF8 }
    } catch { return }
}

function Start-AuthRelay([string]$ProxyUrl, [string]$User, [string]$Pass) {
    Ensure-RelayType
    $u = [Uri]$ProxyUrl
    [ProxyRelay]::Start($RelayPort, $u.Host, $u.Port, $User, $Pass)
    return ("http://127.0.0.1:" + $RelayPort)
}

function Stop-AuthRelay {
    try {
        if (([System.Management.Automation.PSTypeName]'ProxyRelay').Type) { [ProxyRelay]::Stop() }
    } catch { }
}

function Test-LaunchUrl([string]$LaunchUrl, [int]$TimeoutSec = 0) {
    if ($TimeoutSec -le 0) { $TimeoutSec = $ProxyTimeoutSec }
    try {
        $t = Invoke-WebRequest -Uri $ProxyTestUrl -Proxy $LaunchUrl -TimeoutSec $TimeoutSec -UseBasicParsing | ConvertFrom-Json
        return ($t.status -eq "success" -and $t.query)
    } catch { return $false }
}

# Monitor: testa a sala ATIVA (via relay local se tem auth). $true = tudo bem.
function Test-ActiveProxy([int]$TimeoutSec = 15) {
    $st = Get-State
    if (-not $st -or -not $st.ativo) { return $true }
    $r = (Get-Regions) | Where-Object { $_.nome -eq ([string]$st.regiao) } | Select-Object -First 1
    if (-not $r) { return $false }
    $user = ""
    if ($r.usuario) { $user = [string]$r.usuario }
    $launch = [string]$r.proxy
    if ($user -ne "") { $launch = ("http://127.0.0.1:" + $RelayPort) }
    try {
        $t = Invoke-WebRequest -Uri $ProxyTestUrl -Proxy $launch -TimeoutSec $TimeoutSec -UseBasicParsing | ConvertFrom-Json
        return ($t.status -eq "success" -and $t.query)
    } catch { return $false }
}

function Start-RegionProxy {
    param([Parameter(Mandatory=$true)][string]$Regiao, [switch]$SystemWide, [string]$Pass = "")
    $regions = @(Get-Regions)
    $first = $regions | Where-Object { $_.nome -eq $Regiao } | Select-Object -First 1
    if (-not $first) { throw "Região '$Regiao' não cadastrada em config/regions.json" }
    $ordered = @($first) + @($regions | Where-Object { $_.nome -ne $Regiao })
    foreach ($cand in $ordered) {
        $proxy = [string]$cand.proxy
        $user = ""
        if ($cand.usuario) { $user = [string]$cand.usuario }
        for ($try = 1; $try -le $ProxyMaxRetries; $try++) {
            Stop-AuthRelay
            $launch = $proxy
            if ($user -ne "" -and $Pass -ne "") { $launch = Start-AuthRelay $proxy $user $Pass }
            if (Test-LaunchUrl $launch) {
                # O relay de teste continua no ar: o Discord usa ele direto.
                Start-DiscordWithProxy $launch
                if ($SystemWide) { Set-SystemProxy $proxy }
                Save-State ([string]$cand.nome) $proxy
                return @{ Regiao = [string]$cand.nome; Proxy = $proxy; Trocou = ([string]$cand.nome -ne $Regiao) }
            }
        }
        Stop-AuthRelay
    }
    throw "Nenhum proxy respondeu em ${ProxyTimeoutSec}s (${ProxyMaxRetries}x cada). Adicione um reserva em config/regions.json."
}

function Stop-RegionProxy {
    param([switch]$SystemWide)
    Stop-AuthRelay
    Stop-Discord
    Start-DiscordClean
    if ($SystemWide) { Restore-SystemProxy }
    Clear-State
}

# --- Opcional: proxy do Windows inteiro (desligado por padrão) ---
$SysBackupFile = Join-Path $RootDir ".sysproxy-backup.json"
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

function Set-SystemProxy([string]$ProxyUrl) {
    $cur = @{
        ProxyEnable  = (Get-ItemProperty -Path $RegPath -Name ProxyEnable -ErrorAction SilentlyContinue).ProxyEnable
        ProxyServer  = (Get-ItemProperty -Path $RegPath -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer
        ProxyOverride = (Get-ItemProperty -Path $RegPath -Name ProxyOverride -ErrorAction SilentlyContinue).ProxyOverride
    }
    $cur | ConvertTo-Json | Set-Content -LiteralPath $SysBackupFile -Encoding UTF8
    Set-ItemProperty -Path $RegPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $RegPath -Name ProxyServer -Value ($ProxyUrl -replace "^https?://", "")
    # Não mandar localhost pelo proxy para não quebrar serviços locais.
    Set-ItemProperty -Path $RegPath -Name ProxyOverride -Value "<local>"
}

function Restore-SystemProxy {
    if (-not (Test-Path -LiteralPath $SysBackupFile)) { return }
    $b = Get-Content -LiteralPath $SysBackupFile -Raw | ConvertFrom-Json
    Set-ItemProperty -Path $RegPath -Name ProxyEnable -Value ([int]$b.ProxyEnable)
    if ($null -ne $b.ProxyServer) { Set-ItemProperty -Path $RegPath -Name ProxyServer -Value $b.ProxyServer }
    if ($null -ne $b.ProxyOverride) { Set-ItemProperty -Path $RegPath -Name ProxyOverride -Value $b.ProxyOverride }
    Remove-Item -LiteralPath $SysBackupFile -Force
}
