---
tags: [habilidade, combate]
aliases: [Chidori, Estamina]
---
# Shidori e estamina

Voltar: [[INDEX]] · Jogador: [[Jogador]] · Efeitos: [[VFX]] · HUD: [[HUD]] · Tarefas: [[ROADMAP]]
Pedido original: `PROMPT.md` (raiz). Relatório da entrega e gravações: `shots/shidori/` (fora do Git).
Skills do agente: `roblox-sword-vfx`, `roblox-reference-learning`, `roblox-agent-studio-playtest`.

Habilidade inspirada no Chidori: eletricidade concentrada na mão esquerda, **sem espada**. Reaproveita
a técnica do VFX da espada (ver [[VFX]]), não a espada.
Pedido em `PROMPT.md`. Eletricidade concentrada na mão esquerda, sem espada.
- **Arquivos:** `Config.Shidori` e `Config.Stamina` (números), `src/shared/ShidoriMoves.luau`
  (poses por chaves), `src/server/Shidori.luau` (validação, estados, recarga, dano),
  `src/server/Stamina.luau` (estamina nova), `src/client/Shidori.luau` (Z, botão Y do controle, botão
  na tela, pose, investida, mira), `src/client/ShidoriFx.luau` (VFX/SFX), `Boss.handHit`.
- **Números:** custo 50 de estamina (máx. 100), recarga 7 s contada do início, dano 1,6× o soco M1
  pelo mesmo `deal()` do Boss (Poder da luta e curva de `CombatBalance`; crítico aplicado depois,
  uma vez). Estamina regenera 10/s depois de 1 s sem gastar (escolha documentada no Config; o jogo
  não tinha estamina). Desbloqueio: nó `shidori` da árvore de skills ($1.500, 1 nível).
- **Fases (s):** preparo 0–0,22, acúmulo até 0,78 (agacha, mão esquerda baixa ao lado do joelho),
  explosão 0,9 (flash, risco horizontal, raios longos), investida 0,92–1,16 (LinearVelocity, 34
  studs/s, mira no chefe a até 30 studs ou na câmera), dano 0,98–1,24 (+0,35 s de folga no servidor
  pelo atraso da posição), recuperação até 1,62.
- **Estados** (atributo `ShidoriState`): Ready → Activating → Active → Recovering → Cooldown. Morte,
  renascer ou montar cortam ("stop" para todos). `ShidoriReady` = hora do servidor em que libera.
- **Poses:** calibradas no avatar do Studio (AnimationConstraint): inclinar o tronco à frente joga o
  braço pendurado para trás; descer o Root pede joelho muito dobrado. Ajuste ao vivo:
  TestUi `shidori` `{action="tweak"|"freeze"|"aim"}`.
- **Testado (18/10, Plays meus):** `tests/shidori.luau` 34/34 (bloqueio, compra, Z pelo cliente,
  estamina 100→50, recusa na recarga e com 30, regeneração, dois pedidos juntos = um, dano no golem
  = 1,6× soco ou crítico, um acerto, longe não acerta, investida anda, renascer limpa); depois
  `sword_combat` 26/26, `hud` 26, `sync` 9. Gravações em `shots/shidori/`.
- **Não testado:** botão no celular de verdade e o editor do HUD movendo o botão; outro jogador vendo
  (a pose vai pelo espelho de poses, os efeitos rodam em todos, mas não abri 2 clientes); R6;
  desempenho no celular; com a espada na mão (o IK da espada pode brigar com o braço esquerdo).
  Durante a cinemática da sala do chefe o servidor ainda aceita o Shidori (o boneco fica preso no
  cliente).
