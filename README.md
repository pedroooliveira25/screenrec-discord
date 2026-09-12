# ScreenRec

Programa que muda a sala do seu Discord.

## Como usar

1. Abra pelo **Abrir-ScreenRec.bat** (neste PC vale também o
   atalho **ScreenRec** de ícone roxo com a letra S).
2. Confira se a sala **pathbit** esta selecionada.
3. Clique em **LIGAR SALA** e aguarde a barrinha verde terminar.
   O Discord fecha e abre sozinho ja dentro da sala.
4. Quando terminar, clique em **DESLIGAR**.
   O Discord volta ao normal e o programa fecha sozinho.

## Senha

Na primeira vez, digite a senha, marque **Salvar senha** e clique em
LIGAR SALA. Depois disso voce nao precisa digitar de novo.
O botao **VER** mostra a senha digitada e **OCULTAR** esconde.

## Se algo der errado

- Discord nao abre ou trava carregando: abra o programa e clique em
  DESLIGAR para voltar ao normal.
- Fechar a janela do programa tambem restaura o Discord sozinho.
- Se nada resolver, avise o Pedro.

## Para usar em outro computador

1. Copie as pastas `app`, `assets`, `config`, `scripts` + os arquivos
   `Abrir-ScreenRec.bat` e `README.md`.
2. NÃO copie: `ScreenRec.lnk` (atalho com caminho desta máquina),
   `.auth.json` (senha criptografada só abre neste PC),
   `.state.json`, `.sysproxy-backup.json`, `erro.log`.
3. No outro PC, abra pelo `Abrir-ScreenRec.bat` (duplo clique).
   Requisitos: Windows 10/11, Discord instalado, sem precisar de admin.
4. Digite a senha uma vez com **Salvar senha** marcado e pronto.

## Atalho com ícone (quem clonou do GitHub)

O `ScreenRec.lnk` do repositório não funciona em outro PC (caminho
absoluto). Depois de clonar, dê duplo clique no **`Criar-Atalho.bat`** —
ele gera o `ScreenRec.lnk` com os caminhos dessa máquina + ícone roxo.
A partir daí use o atalho normalmente.

## Importante

- Se a sala não responder em 60 segundos (2 tentativas), o programa troca
  sozinho para outra sala válida e avisa na tela.
- Com o app aberto, ele testa a sala a cada 1 minuto: se cair 2 vezes
  seguidas, recarrega sozinho (desmarque "Recarregar sozinho" para desligar).
- Chamadas de voz continuam normais (a sala muda so o resto do Discord).
- Nao apague os arquivos e pastas daqui de dentro: o programa precisa
  deles para funcionar.
