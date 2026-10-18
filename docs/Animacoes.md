---
tags: [sistema]
aliases: [Animações]
---
# Animações

Voltar: [[INDEX]] · Relacionado: [[Bosses]], [[Jogador]] · Skills: `roblox-boss-attack-overhaul`,
`roblox-agent-studio-playtest`, `roblox-blender-kit-models`

Decisão do dono (16/10): a ferramenta é escolha do agente. Divisão aceita: clipes fixos por código como
`KeyframeSequence` (o dono pode lapidar no Eclipse Animator); movimento reativo por camadas procedurais
em `Pose.luau`; golem e modelos do Blender animados no Blender.

## Golem (Blender, sem animação do Roblox)
- `tools/blender/golem.py` grava a rotação de cada osso em `src/shared/GolemAnims.luau` (15 fps +
  eventos como `impact`); `.blend` em `E:\Projetos roblox\Blender\Golem\`. Rodar com
  `blender.exe -b --factory-startup -P <script>`.
- Golpes novos: `tools/blender/golem_v2.py` reaproveita o rig do `golem.py` (sem editá-lo) e grava
  `GolemAnimsV2.luau` a 30 fps. `SNAP=<pasta>` gera prévias. Detalhes e armadilhas na skill
  `roblox-boss-attack-overhaul`.

## Boneco do jogador
- **Descanso parado:** `tools/anim/rest_idle.luau` (roda em modo de edição pela ponte, grava
  `AnimSaves.RestIdle` no `Workspace.AnimRigs.RestRig`) → `tools/anim/export.cjs` (gera `.rbxm` binário;
  a Open Cloud rejeita `.rbxmx`) → `tools/upload_assets.cjs` → `src/shared/Animations.luau`
  (`rest_idle` = `rbxassetid://114064336167293`) → `Move.luau` troca o `idle` do script `Animate`.
  O servidor apaga `workspace.AnimRigs` ao iniciar. **O RestRig só existe no place do Studio: o dono
  precisa salvar o place.**
- **Boneco com a espada para animar no Eclipse (18/10):** `node tools/bridge.cjs run edit
  tools/anim/sword_rig.luau` cria `Workspace.AnimRigs.SwordRig` (clone do RestRig, R15 com
  `AnimationConstraint`, espada do Asta presa na mão direita como no `/sword`). Não precisa de Play
  (`/sword` só funciona no Play). Rodar de novo apaga o SwordRig antigo e o que foi salvo nele.
  Verificado: boneco e espada aparecem, 15 constraints, AnimSaves vazio; o Eclipse em si não foi aberto.
- Poses por código (corrida, dash, soco, montaria, portal): `src/client/Pose.luau`.
- Golpes da espada: chaves em `src/shared/SwordMoves.luau` + IK dos braços (`SwordCombat.luau`, gancho
  `Pose.after`). Os avatares deste jogo usam `AnimationConstraint` (não Motor6D): ler as juntas pelos
  attachments (`SwordMoves.rig`). Ver [[Jogador]].
- Eixos das juntas do R15: tronco/cabeça +X inclina para trás, +Z para a esquerda, +Y gira para a
  esquerda; membros +X balança para a frente, +Z para a direita; frente = -Z.

## Projeto paralelo: bêbado (Blender)
`E:\Projetos roblox\Blender\Machine Learning\Machine Learning.blend` (gerador `bebado_build.py` dentro).
Lições do dono: sem pulinho; pé de apoio parado; pernas nunca se atravessam; sem gangorra depois de parar;
braços soltos acompanhando; pouco tempo numa perna só; cabeça viva. Não editar o `.blend` em segundo
plano com o Blender do dono aberto.

## Não verificado
Descanso em movimento contínuo e com dois jogadores; o dono ainda avalia o bêbado.
