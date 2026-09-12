# test-region.ps1 — certifica quais regioes trocam o IP de saida.
# Uso: .\test-region.ps1
. (Join-Path (Split-Path -Parent $PSScriptRoot) "app\proxy-manager.ps1")
try {
    $d = Invoke-WebRequest -Uri "http://ip-api.com/json/?fields=status,country,query" -TimeoutSec 8 -UseBasicParsing | ConvertFrom-Json
    Write-Output ("SAIDA DIRETA (sem proxy): " + $d.query + " (" + $d.country + ")")
} catch {
    Write-Output ("SAIDA DIRETA: falhou (" + $_.Exception.Message + ")")
}
foreach ($r in (Get-Regions)) {
    if ($r.nome -eq "exemplo-local") { continue }
    try {
        $t = Invoke-WebRequest -Uri "http://ip-api.com/json/?fields=status,country,query" -Proxy $r.proxy -TimeoutSec 10 -UseBasicParsing | ConvertFrom-Json
        if ($t.status -eq "success" -and $t.query) {
            Write-Output ("OK    " + $r.nome + " => " + $t.query + " (" + $t.country + ")")
        } else {
            Write-Output ("FALHA " + $r.nome + " => proxy respondeu mas sem IP valido")
        }
    } catch {
        Write-Output ("FALHA " + $r.nome + " => " + $_.Exception.Message)
    }
}
