---
tags: [sistema]
aliases: [Chefe, Golem]
---
# Bosses (golem)

Voltar: [[INDEX]] · Relacionado: [[VFX]], [[Animacoes]], [[Economia]] · Skills:
`roblox-boss-attack-overhaul`, `roblox-enclosed-room-camera`, `roblox-portal-room-cutscene`

## Fluxo
Quem limpa o corredor entra por um portal (cena do cliente: agacha, salta, mergulha; faixas de cinema;
portas batendo) na sala do chefe. O golem dorme no círculo do centro; **Challenge** acorda ele (só quem
tem direito ao sorteio). Vencer = sorteio do personagem ([[Economia]]); morrer para o golem perde o
sorteio. Saída pela porta (prompt).

## Sala por jogador (desde 17/10)
- `src/server/BossRoom.luau`: cada jogador recebe a própria cópia da sala e do golem. Cópias de um mundo
  ficam em fila a `Config.BossRoom.spacing` (400 studs) em +X; a primeira (`BossRoom<mundo>`) é montada
  ao abrir o servidor, as outras (`BossRoom<mundo>_<n>`) quando faltam. O modelo da sala é baixado uma
  vez e clonado. Ao sair/morrer/viajar/desconectar a sala é liberada e o golem volta a dormir.
- O jogador sabe qual é a sua pelo atributo `RoomKey`; `Room` continua com o id do mundo.
- O cliente só anima e mostra o golem da própria sala.

## Golem (`src/server/Boss.luau`, cliente `src/client/Boss.luau`)
- Modelo em blocos do Blender (`tools/blender/golem.py`: 61 peças, 16 ossos, 11 animações), animações
  em `src/shared/GolemAnims.luau` ([[Animacoes]]). O servidor guarda posição, clip e vida; o cliente move
  as peças (`GolemPose.luau` + `BulkMoveTo`), mostra a barra de vida e a cena do despertar.
- Golpes: Stomp, Sweep, Slam (Esmagamento de Punhos), Charge (corrida + gancho), Pulse (magia, só se
  esquiva pulando). Dano no quadro do evento `impact` do clip; depois de cada golpe fica cansado.
  Raiva abaixo da metade da vida. Números dos golpes em `Config.Boss` (escala 1,5; `attacks` com
  dano, raio e alcance). **Vida e dano do jogador** vêm do balanceamento (abaixo), não mais de "80/110 socos".

## Balanceamento dos chefes (17/10)
- Arquivos: `src/shared/CombatBalance.luau` (fórmulas), `Config.Combat` (parâmetros), `Config.Bosses`
  (10 linhas: Poder mínimo, `ttk`, `hpScale`/`curve` opcionais). O chefe do mundo N é `Config.Bosses[N]`
  (`g.world.id`); o chefe 2 usa o golem do mundo 2 até haver modelo próprio. Chefe novo = uma linha.
- Fórmulas: `dano do soco = floor(baseDamage 10 x mult(Poder / Poder mínimo))`, crítico x2;
  `vida = baseDamage x 4 socos/s x (1 + 4%) x ttk` (chefe 1: 2496 por jogador). A curva do `mult` é
  linear entre (1; 1), (1,5; 1,5), (2; 3) — dá 60 s com 50K, 40 s com 75K, 20 s com 100K —, cai
  proporcional abaixo do mínimo (piso 0,25) e sobe até o teto 6 acima de 2x. Sem limite de tempo na luta.
- O Poder que vale é o do **começo da luta** (`fightPower` em `Boss.luau`); o Poder ganho batendo no golem
  não acelera a própria luta. Quem entra no meio usa o do 1º soco. Poder por soco: `Boss.onDamage` recebe
  socos cheios (1; crítico 2), não vida.
- `Config.Combat.enforceEntry` (false): se true, `Boss.challenge` recusa quem não tem o Poder mínimo.
- Servidor: intervalo de 0,22 s, alcance, sala e vida restante inalterados; o dano é do servidor.
- Testes: `tests/boss_balance.luau` (fórmulas, tabela dos 10, simulação, entrada, luta medida).
- Dano válido no golem dá Poder (`Boss.onDamage`, ligado em `init.server.luau`; ver [[Economia]]). O
  dano que o golem dá passa pela skill DEFENSE em `hurt` (único ponto de dano).
- Mundo 1 azul arcano, mundo 2 magma laranja (`GolemModels.luau`).

## Golpes novos (experimento ligado, aprovado pelo dono)
- `Config.Boss.slamV2` e `chargeV2`: animação nova (`tools/blender/golem_v2.py` → `GolemAnimsV2.luau`) e
  efeitos novos ([[VFX]]). `src/shared/GolemExperiment.luau` injeta os clips e diz qual clip cada golpe
  toca; `false` volta ao original. Dano, raio e alcance não mudaram; o impacto passou de 1,03 s para
  1,10 s (Slam) e de 0,57 s para 0,60 s (Charge).
- Verificado em Studio: o servidor toca `SlamV2`/`ChargeV2`; dano 42 e 34 (os originais); `golem.luau`
  (30 checagens) passa com os dois ligados e com o Slam desligado; nenhuma peça sobra na sala.

## Comando `/spawn` (admin, sem commit)
`/spawn` (ou `/spaw`) leva à sala do mundo atual e acorda o golem, sem direito ao sorteio.
`/spawn stomp|sweep|slam|charge|pulse` força o golpe com a luta rolando. Teste `tests/spawn.luau` (8 ok).

## Não verificado
- Dois jogadores ao mesmo tempo (salas separadas testadas só com um).
- Golem do mundo 2 jogado de verdade; sons (não há ids de áudio); dano escalando com o Poder (ideia em aberto).
- Sincronia exata animação × efeito quadro a quadro (as capturas pegam ~1 quadro a cada 0,2 s).
- `tests/boss.luau` não rodou depois da mudança para sala por jogador.
