---
tags: [sistema]
aliases: [Interface, UI]
---
# HUD e interface

Voltar: [[INDEX]] · Relacionado: [[Jogador]] · Skills: `roblox-ui-juice`, `roblox-ui-mastery`

## Peças
- `src/client/Hud.luau` (HUD), `Menus.luau` (todas as janelas), `Windows.luau` (painéis 3D que flutuam
  na frente do boneco), `Stats.luau` (árvore de skills), `Ui.luau` (`Ui.autoScale` multiplica pelos
  atributos `PlatformScale` e `UserScale`; usado por várias janelas — mexer ali pede rodar os testes delas).
- `src/client/Platform.luau`: tipo de aparelho (`phone`/`tablet`/`console`/`desktop`); texto grande
  0,72× no celular e 0,86× no tablet; placa da cabeça 0,6× e 0,8×. `Fx.luau` e `Super.luau` também
  usam. Os quadros de tecla do super soco **não** encolhem no celular (no toque são os botões).

- Estamina (18/10): barra fina embaixo da vida (atributos `Stamina`/`StaminaMax`), só com o Shidori
  desbloqueado; fica apagada abaixo do custo. Botão `Shidori` (⚡, tecla Z, recarga em contagem) é filho
  direto do HUD e bloco do editor (`HudLayout.BLOCKS`). Ver [[Shidori]].

## Painel do balcão de poções (caldeirão)
- Bug: o painel às vezes nascia dentro do caldeirão (o painel fica 2,6 à frente e 3,4 à direita do
  boneco, e quem chega olha para o balcão).
- Correção (17/10): `Windows.set/toggle(name, open, near)`. Com `near` (o modelo `Sanctum.PotionShop`,
  passado por `openPotionShop` em `Menus.luau`), `chooseTurn` parte do boneco virado para o balcão e testa
  giros de 10 em 10° (os menores primeiro, para os dois lados) até painel e câmera ficarem livres: caixas
  das peças do balcão com folga `Config.Panel.clearance` (são `CanQuery = false`) e raycast no resto
  (paredes, estante). O boneco gira suave junto com a câmera na abertura; ao fechar, a câmera volta para
  `Custom` como antes. Janelas do HUD continuam sem giro.
- Teste novo `tests/potion_panel.luau` (16 direções, só as alcançáveis; comando `potionShop` do TestHook).

## Editor de HUD (celular)
- `src/client/HudEditor.luau`: engrenagem só no toque; arrastar blocos (MENU, SHORTCUTS, MONEY & POWER,
  HOTBAR, JUMP), tamanho 50-160 %, opacidade 20-100 %, RESET, RESET ALL, DONE (salva).
- Layout validado por `src/shared/HudLayout.luau`, vai ao servidor pelo remote `HudLayout` (≤ 1200
  caracteres, 1 salvamento a cada 0,5 s) e fica no perfil (`hud`), chegando pelo atributo `HudLayout`.
- **Desde 17/10 o layout salvo só vale no toque**: no PC o HUD fica no padrão, e volta o layout ao trocar
  para o celular.
- Bug da opacidade (HUD sumia e não voltava): **corrigido** (commit `11ee231`). Causa: o Roblox guarda
  float32 e o editor comparava com o valor em precisão dupla, tratando a própria escrita como mudança
  externa; agora guarda o valor lido de volta e compara com folga de 1e-4.

## Não verificado
- Painel do caldeirão: **nada rodou no jogo**. `tests/potion_panel.luau` nunca rodou (o Studio estava num
  Play de outra pessoa); só o analisador Luau do VS Code, sem erros.
- Toque real em aparelho ou emulador (arrastar com o dedo, barras, botão de pular, posição da engrenagem).
- `tests/hud.luau` ganhou a checagem "PC ignora layout do celular" mas **não rodou** depois de 17/10.
- O que são os "quick events" do pedido original (interpretação: avisos na tela e minigame do super
  soco) — confirmar com o dono. No mínimo de 20 % a hotbar fica muito fraca (decisão de design do dono).
