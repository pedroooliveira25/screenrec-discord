# Plano de Contingência — ScreenRec

O que fazer quando algo falha. Sem senha, sem segredo aqui dentro.

## Resposta rápida por cenário

| Cenário | Resposta |
|---|---|
| Sala atual caiu | Automático: app testa a cada 60s, 2 falhas = troca sozinho. Manual: escolha outra sala no combo e LIGAR |
| Todas as salas caem | DESLIGAR (Discord volta ao normal, modo direto) + cadastrar reserva nova (ver abaixo) |
| Discord não abre / trava carregando | Restauração limpa (comandos abaixo) |
| App congelou no LIGAR | Feche a janela (restaura sozinho). Se não fechar: mate o `powershell` do app no Gerenciador de Tarefas |
| Senha não entra / pede toda hora | Digite 1x com **Salvar senha** marcado. Senha salva num PC não funciona em outro (normal) |
| PC novo / quem clonou | `git clone` + `Criar-Atalho.bat` + senha 1x (ver README) |
| Atualizar quem clonou | Na pasta: `git pull origin main`, reabra o app |

## Restauração limpa do Discord (emergência)

No PowerShell:

```powershell
Get-Process -Name "Discord" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3
$exe = Get-ChildItem "$env:LOCALAPPDATA\Discord" -Filter "Discord.exe" -Recurse |
  Where-Object { $_.FullName -like "*app-*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Start-Process -FilePath $exe.FullName -WorkingDirectory (Split-Path -Parent $exe.FullName)
```

## Cadastrar proxy reserva (quando tudo cai)

1. Ache candidatos (listas públicas ou provedor privado)
2. Teste antes (não cadastre no escuro):
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-region.ps1`
3. Adicione em `config/regions.json`:
   ```json
   { "nome": "reserva3", "proxy": "http://IP:PORTA", "descricao": "Reserva ..." }
   ```
   Com auth: acrescente `"usuario": "login"` (a senha vai via app, nunca no arquivo)
4. Valide pelo app (LIGAR) e só então `commit + push`

## Checagem de saúde (rotina)

- `scripts\test-region.ps1` — testa todas as salas de uma vez
- Meta: **sempre 2+ salas válidas**. Com 1 só, não há failover
- Proxy público morre sem aviso: revalide toda semana

## O que NUNCA sobe pro GitHub

`.auth.json` (senha), `.state.json`, `.sysproxy-backup.json`, `erro.log`, `ScreenRec.lnk`.
Cada máquina gera o próprio atalho (`Criar-Atalho.bat`) e a própria senha.

## Dependências externas (dono: Pedro)

- VPS `45.86.245.81` (Seattle, RapidSeedbox): SSH aberto, proxy 8080 parado.
  Reviver = SSH + subir o serviço, ou painel da provedora. Sem isso, `pathbit` segue morto
- Proxy privado BR/SP (<50ms): contratar + entregar IP:porta + login + senha p/ cadastro
