---
tags: [sistema]
aliases: [Combate, Auras, Montarias]
---
# Jogador: combate, movimento, auras e montarias

Voltar: [[INDEX]] · Relacionado: [[Economia]], [[Animacoes]], [[VFX]], [[Bosses]]

## Soco e combate
- Socar o saco dá Poder (servidor em `init.server.luau`; cliente `Bag.luau`). O mesmo soco acerta o
  golem quando o jogador está perto dele ([[Bosses]]).
- Crítico: 4 % de base, até 20 % com a skill. Super soco: 1,5 % de chance, 20× o ganho, com minigame de
  tecla (`Super.luau`; números em `Config.Crit` e `Config.Super`). Automáticos (auto click, auto super)
  em `Auto.luau`, dependem de game pass.
- Sem PvP.

## Movimento (`src/client/Move.luau`)
Dash na tecla Q (ButtonX no controle; botão DASH no toque), pulo duplo, corrida com LeftShift ou
automática depois de um tempo andando. A animação de descanso parado está em [[Animacoes]].

## Auras (`src/client/Aura.luau`, `Config.Auras`, `Config.AuraFx`)
- Sete auras toon (EMBER, SPARK, FROST, VENOM, STORM, SOLAR, VOID): fogo em flipbook, anéis de trail,
  círculo mágico e vento no chão (SurfaceGui), lascas, estrelas, pilares, raios. A força cresce com o
  Poder. Texturas desenhadas por `tools/blender/aura_textures.py` (ids em `src/shared/Textures.luau`).
- A primeira aura chega sozinha com 1K de Poder. Em movimento a aura vira rastro de cometa (estilo voo do
  Dragon Ball; skill `roblox-motion-aura`).

## Montarias (`src/client/Mount.luau`, `src/server/Mounts.luau`, `Config.Mounts`)
- Só visuais (não mudam a velocidade): skate flutuante ($10K) e tapete voador ($100K), modelados no
  Blender, com poses animadas por código.
- Desde 17/10: no menu MOUNTS o primeiro clique compra (e já monta), os seguintes só escolhem; **a tecla
  M** sobe e desce (atributo `Riding`, não salvo; o jogador entra a pé). No toque há o botão RIDE/OFF
  acima do DASH. A montaria escolhida fica no perfil (`mount`).

## Espada de antimagia do Asta (só dev, desde 17/10)
- A Exterminadora de Demônios (Demon Slayer) de *Black Clover*: `tools/blender/asta_sword.py` gera
  `assets/models/asta_sword.fbx` (1,9k triângulos: lâmina com seção em losango, guarda em cruz com
  anel, cabo enrolado, pomo) e a textura `assets/textures/asta_blade.png` (aço escuro azulado com
  manchas pretas, gume e aresta marcados). Fonte: `E:\Projetos roblox\Blender\Asta Sword\asta_sword.blend`.
- Medidas: 4,9 studs no total (lâmina 4,1, largura 0,94), mais ou menos a altura do boneco R15, como
  no anime. Referências: imagens do dono, modelo do Sketchfab (só miniatura e dados da API: a página
  não abre sem navegador) e a UGC "Asta's Demon-Slayer Sword" do catálogo (só miniatura).
- Inventário (pedido do dono, 17/10): `/sword` (admin pelo `Admin.isAdmin`, conferido no servidor
  pelo UserId) põe a espada no inventário, não na mão: aparece o **slot 1** à esquerda da hotbar de
  personagens (`src/client/Sword.luau`, com ícone 3D; os personagens passam para as teclas 2 a 9,
  `Hud.luau`). Tecla 1 ou clique equipa e guarda pelo remote
  `SwordToggle`, que só age para quem tem o atributo `SwordOwned` (escrito só pelo servidor).
  `/sword off` tira do inventário. A espada **não** entra na lista de personagens do perfil (vender
  e colocar no pedestal continuam só para personagens). Vale só na sessão e volta à mão depois de
  renascer. Quem não é admin não recebe nada (o comando nem aparece no autocompletar).
- O ícone vem de uma cópia do modelo que o servidor põe em `PlayerGui.SwordIcon` (ScreenGui com
  `ResetOnSpawn = false`: um Model solto no PlayerGui some ao renascer). O modelo original fica em
  ServerStorage.
- Na mão: Weld na RightHand (R6: Right Arm). Peças sem colisão, sem massa e não ancoradas; escala pelo
  `BodyHeightScale`. Usar `Weld` com C0, não `WeldConstraint`: mover o cabo fora do Workspace
  recaptura a distância e a lâmina fica para trás. Lâmina em SmoothPlastic: Metal com a textura escura
  vira uma barra preta.
- Pose (17/10, terceira versão, pela imagem de referência do dono): camada "sword" do cliente com
  o braço relaxado ao lado do corpo; a lâmina sai da mão na altura do quadril, para a frente e um
  pouco para fora, quase na horizontal. Recusadas: lâmina para trás arrastando ("faca") e guarda
  com o braço erguido ("tronxo"). A pegada (`GRIP_R15` no servidor) depende da pose: se a pose
  mudar, medir de novo. Conferida em 17/10: lâmina para (0,40; -0,05; -0,91) no espaço do boneco,
  ponta a 1,8 stud do chão, capturas de frente, de lado e de cima. Fica acima
  da caminhada e da corrida e abaixo da montaria e do soco.
- A lâmina traz os Attachments `BladeBase`, `BladeMid` e `BladeTip` (rastros, luz e acerto).
- Tamanho (pedido do dono, 17/10): `Config.Sword.size` = 1,4 × o modelo (× a altura do avatar);
  com o avatar de teste a espada mede ~7,4 studs. Trava do chão (`SwordMoves.aboveFloor`, cliente e
  hitbox do servidor): se a ponta fosse descer abaixo de `floorMargin` (0,3) do chão, a espada gira
  para cima em volta da pegada, só o necessário. Medido: ponta mais baixa no combo 0,30; parada, 1,1.
  Chão suposto plano (a altura vem do HumanoidRootPart): em rampa ou degrau pode encostar.

### Combo M1 da espada (17/10)
- Botão esquerdo (toque; R2 no controle) com a espada na mão; segurar encadeia sozinho. Com a
  espada, o clique não soca o saco nem o golem (`Bag.blocked`).
- Três golpes (`src/shared/SwordMoves.luau`, usado pelo cliente e pelo servidor): **corte diagonal**
  da direita alta para a esquerda baixa, **varredura horizontal** da esquerda para a direita na
  cintura, **golpe final** de cima, batendo no chão. Cada chave tem corpo (quadril, tronco, pernas;
  tornozelos e pescoço automáticos) e onde a espada fica no espaço do tronco; o gume é calculado
  pelo eixo de giro do corte. Preparo com pausa no alto, aceleração, seguimento e recuperação.
- Janelas por golpe: `hit` (dano), `trail` (rastro), `chain` (clique que encadeia; antes dela o
  clique fica guardado, um só). Depois do golpe final, pausa de `Config.Sword.finisherRest`.
- Duas mãos: `src/client/SwordCombat.luau` roda depois de todas as camadas de `Pose.luau`
  (`Pose.after`): o corpo segue as chaves e os dois braços vão até o cabo por IK de dois ossos (o
  punho gira). A mão direita leva a espada (solda da mão); a esquerda segura 0,42 abaixo. As medidas
  vêm do rig real (Motor6D ou `AnimationConstraint`, que os avatares deste jogo usam), escaladas
  pelo comprimento do braço. Durante o golpe: velocidade × `moveScale` (`Move.speedScale`), giro
  automático desligado e o corpo vira para o golem (ou para onde a câmera olha) no preparo.
- Dano (servidor, `src/server/SwordCombat.luau`): o cliente só diz "comecei o golpe"; o servidor
  decide qual golpe vale pelo ritmo (com folga `tolerance`), recusa cedo demais e, durante a janela
  `hit`, calcula a cada quadro os pontos da lâmina (mesma pose + rig + HumanoidRootPart) e testa os
  alvos. Golem: `Boss.bladeHit` (cilindro do corpo + `bodyMargin`), um acerto por golpe, dano =
  `Config.Sword.damage[golpe]` × dano do soco (mesma fórmula, crítico e Poder ganho do soco:
  `deal` em `Boss.luau`). Alvos novos entram na tabela `TARGETS`.
- Para os golpes especiais futuros: `SwordMoves` aceita golpes novos (chaves + janelas), o
  servidor reaproveita o teste da lâmina e `TARGETS`, os efeitos reaproveitam `SwordFx`.
  Sem buffs nem golpes especiais por enquanto.
- Efeitos: ver [[VFX]] (aura na espada, rastros por golpe, impactos).
- Testado em 17/10: `tests/sword_combat.luau` (25: golpe, lentidão, rastro, espada no lugar e mão
  esquerda no cabo (erro < 0,25), volta ao controle, clique guardado, combo 1-2-3, 20 cliques no
  mesmo quadro = 1 golpe, servidor aceita/recusa/encadeia, guardar cancela, aura VOID/FROST/sem
  aura, 3 acertos no golem com dano = vida tirada, longe não acerta, renascer limpa). Capturas de
  lado e de frente (duas mãos no cabo, giro do tronco, golpe final no chão) e contra o golem
  (o bloom forte da sala deixa difícil de ler).
- Não verificado: visto por outro jogador (efeitos por `swing`/`impact`, pose pelo espelho),
  celular (toque arrastando a câmera também golpeia, como o soco), avatar R6 (sem golpe: o rig
  precisa das juntas do R15), lag alto, desempenho com muitos jogadores.
- Testado: `tests/sword.luau` (19 checagens: não-admin sem nada, slot sem espada não equipa, vai para
  o inventário e não para a mão, ícone, slot equipa e guarda, solda, sem física, massa igual,
  textura, pontos de VFX, tamanho, renascer, `/sword off`); tecla de verdade no cliente (equipa e
  guarda); capturas da pose de guarda e do slot.
- Não verificado: visto por outro jogador, avatar R6 ou com escala diferente, socar o saco e montar
  com a espada, slot da espada no celular e no layout do editor de HUD, desempenho, jogo publicado.

## Shidori (habilidade da tecla Z, desde 18/10)
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

## Outros jogadores
Aura, poses (corrida, dash, soco, montaria) e efeitos de impacto aparecem para os outros: o cliente
manda a pose final das juntas 15×/s (≤ 96 bytes) e o servidor repassa (`Pose.luau`, `Others.luau`).
Placa sobre a cabeça e painel PLAYERS mostram Poder e dinheiro.

## Não verificado
- Nada disto foi testado com dois jogadores (o Studio do agente tem um cliente só).
- Montaria na tecla M: `tests/mounts.luau` e `sync.luau` foram atualizados mas **não rodaram**.
- Auras em movimento ("intensa mas suave") dependem do olho do dono; custo de desempenho com muitos jogadores.
