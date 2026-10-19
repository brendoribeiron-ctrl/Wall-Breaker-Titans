---
tags: [sistema]
aliases: [Efeitos]
---
# VFX

Voltar: [[INDEX]] · Relacionado: [[Bosses]], [[Jogador]], [[Ferramentas]] · Skills:
`roblox-boss-attack-overhaul`, `roblox-blender-stylized-vfx`, `vfx-particles-and-beams`, `roblox-reference-learning`

## Onde está
| Peça | Arquivo |
|---|---|
| Efeitos dos golpes originais do golem | `src/client/BossFx.luau` (fogo, ondas, rachaduras, entulho, lua crescente, "gather", onda do Pulso, morte; `BossFx.PALETTE` por mundo) |
| Peças 3D de efeito (Dome, Swirl, Ring, Band, Slash, SpikeA/B, Shard, Pillar) | `tools/blender/boss_fx.py` → `assets/models/boss_fx.fbx`, carregadas em `ReplicatedStorage.BossModels.Fx` |
| Peças de terra dos golpes novos (aviso no chão, espinho, rachadura, anéis, fumaça, brasas) | `src/client/BossFxEarth.luau` |
| Golpes novos | `src/client/BossFxSlamV2.luau`, `BossFxChargeV2.luau` (chamados por `BossFx` com o `kit` de helpers) |
| Efeitos gerais (flash, tremor, cubos, toast) | `src/client/Fx.luau` |
| Auras | ver [[Jogador]]; texturas em `assets/textures`, `Textures.luau` |
| Espada do Asta (aura na lâmina, rastros, impactos) | `src/client/SwordFx.luau` |

## Espada do Asta (17/10, segunda versão)
- Texturas próprias: `tools/blender/sword_fx.py` (Blender + numpy) → `energy_profile` (fita: dentro
  macio, borda de fora acesa, emenda no comprimento), `energy_body/trail/core`, `blade_flow` (fios
  correndo), `bolt` (raio), `spark` (faísca em pé, para `VelocityParallel`), `ring_glow`. Ids em
  `Textures.luau`.
- Aura na espada (Haki do Armamento), cor e força da aura equipada: casca ForceField semitransparente,
  fios de energia correndo pelas duas bordas da lâmina (Beams com `TextureSpeed`), véu fraco no meio,
  brilho, labaredas, fumaça preta, brasas, orbes e raios estalando (pretos e na cor da aura).
- Golpe: rastros presos na lâmina (preto da antimagia por baixo, aura por cima, fio na ponta), chuva
  de faíscas da ponta e, no fim de cada golpe, a meia-lua: Beams em curva (Catmull-Rom com 5 pontos)
  calculados pela própria animação (`SwordMoves`, não pelo quadro), que se desfazem da cauda para a
  cabeça. Impactos com faíscas em raio, flash curto, anel e orbes; golpe final com anéis, rachadura,
  coluna de faíscas, pedras e raios no chão.
- **Armadilhas que custaram tempo:** Trail ligado só na hora do golpe (Enabled) não aparecia: fica
  sempre ligado e quem mostra/esconde é a `Transparency`. Beam de meia-lua com `FaceCamera = false`
  some de quina em vários ângulos: usar `FaceCamera = true` (a curva vem das tangentes). Golpe
  encadeado cancelava a meia-lua do anterior: ela sai sempre no fim da janela. A captura por
  screenshot (~7 qps) perde o golpe: gravar a janela a 30 qps com ffmpeg `gdigrab`
  (`shots/sword/m1/rec.sh`) e disparar pela ponte (`tests/sword_show.luau`).
- Não verificado / a melhorar: visto por outro jogador; desempenho com várias espadas; celular. O VFX
  Studio e plugins não foram usados (tudo por código + Blender).

## Espada do Asta — magia roxa (18/10, terceira versão dos rastros)
- Pedido do dono: rastros de magia roxa. Paleta fixa nos golpes (não segue a aura; a casca da lâmina
  continua na cor da aura): `VOID` (quase preto, contraste com céu claro e Bloom), `VIOLET`, `MAGENTA`,
  `LILAC`. Branco puro saiu de tudo que é grande (virava borrão com o Bloom).
- Meia-lua no jeito do tutorial "sword swipes" (`run_videos_para_skills/2026-10-18_swords_vfx`, v1):
  nasce no **começo** da janela do rastro e a cabeça anda pelo arco junto com a lâmina (ease-out);
  nada à frente da cabeça; cauda dissolvendo atrás; depois some da cauda para a cabeça abrindo um
  pouco. Camadas: fundo `VOID` (alpha 0.5), corpo violeta translúcido (alpha 0.45), **estrias**
  (`slash_streaks`, textura nova em `tools/blender/sword_fx.py`) rolando com `TextureSpeed`, fio lilás
  na borda; golpe final ganha um eco de estrias por fora. 8 trechos de Beam por camada; cada trecho tem
  `TextureLength` = o próprio comprimento, então as estrias emendam e rolam em fase. Pó de magia
  (estrelinhas + orbes) cai por onde a cabeça passa; flash lilás na cabeça no fim.
- Rastros presos na lâmina: corpo com `slash_streaks`, borda em lilás/magenta fraca (a branca virava
  uma cunha estourada). Impactos e golpe no chão em roxo; rachadura roxa fica 2,2 s.
- `slash_streaks` subiu pelo Studio MCP (`upload_image`), não pelo `upload_assets.cjs`: o `.env` está
  sem `ROBLOX_API_KEY`. Id e hash foram gravados à mão em `Textures.luau` / `uploaded.json`.
- **Efeitos editáveis no Studio (18/10, pedido do dono):** o visual mora em objetos de verdade em
  `ReplicatedStorage.SwordVFX` (ParticleEmitter, Beam, Trail, PointLight), editados nas Propriedades e
  nos Atributos. `SwordFx.luau` só clona e posiciona. Padrões em `src/shared/SwordVfx.luau`
  (`build()`); sem a pasta no place, o jogo usa os padrões. Pastas: `Blade` (aura na lâmina),
  `Swing` (rastros presos + faíscas da ponta), `Swipe` (camadas da meia-lua, `Dust`, `Flash`), `Hit`
  (acerto no alvo, `Burst`), `Ground` (golpe no chão: `Up`, `Flat`, raios). Atributos: `Count`/
  `HeavyCount` (leva de partículas), `UseAuraColor`, `Life1..3` (rastro por golpe, 0 = desligado),
  `Radius`/`Width`/`Alpha`/`Scroll`/`HeavyOnly` (meia-lua). Tamanhos na escala 1 (o código multiplica).
  Criar no place: `tools/vfx/sword_vfx.luau` (refazer: `sword_vfx_reset.luau`), modo de edição; **o
  dono precisa salvar o place** (a pasta não está no Git e o Rojo não mexe nela). Mudanças feitas
  durante o Play valem no próximo golpe, mas somem ao parar.
  Substituiu o painel F6 + `SwordFxTune` (apagados: o dono queria editar no próprio Studio).
  Armadilha: `execute_luau` do MCP no cliente dá `require` próprio (outra cópia do módulo); para mexer
  no estado do jogo, usar o caminho `TestUi` (`SwordCombat.test`).
  Testado (18/10, Play): espada monta pelos modelos (4 Trails, 5 emissores), combo gravado igual ao
  anterior (`shots/sword/m1/templ.mp4`), 0 erros do jogo; mudar `Swipe.Body/Streaks.Color` e o atributo
  `Width` no Play deixou o próximo arco laranja e mais largo (`templ_orange.png`). Não testado: aura
  equipada com os modelos, outro jogador, `sword_combat`.
- Testado (18/10): gravações a 30 qps do combo sem aura (`shots/sword/m1/after*.mp4`, antes em
  `before.mp4`), 0 erros no log, nenhuma sobra no Terrain. **Não** rodei `sword_combat`/`sword` depois
  desta mudança (só mexeu no cliente de efeitos). Rojo não estava conectado no Studio: o código foi
  empurrado pela ponte (Source do módulo).

## Espada do Asta — rastro contínuo e vivo (18/10, quarta versão)
- Pedido do dono: o rastro parecia "Roblox 2016" (estrias quebradas, sem brilho); referências dele:
  VysVFX (fita estável, glow forte, cor viva). Mantida a paleta roxa, mais viva (`VIVID`, `PINK`,
  `HOT` em `SwordVfx.luau`).
- Três causas do visual quebrado, corrigidas:
  1. **Quinas:** a animação interpola as poses em linha reta, então a ponta faz um polígono.
     `pathOf` amostra 11 pontos e corta os cantos com Chaikin (4 passadas).
  2. **Dentes na borda:** com `FaceCamera = true` cada trecho de Beam vira para a câmera pela sua
     corda. Agora a fita é deitada no plano do golpe (`FaceCamera = false`) e o eixo Y dos
     attachments aponta na direção radial (`arcBeam`), então trechos vizinhos emendam.
  3. **Contas por trecho:** no Beam o eixo **X** da imagem corre na **largura**. Texturas novas
     `band_glow_x`, `band_body_x`, `band_core_x` (`tools/vfx/band_textures.cjs`, perfil em X, iguais
     no comprimento), enviadas pelo Studio MCP.
- Camadas da meia-lua: `Glow` (halo largo), `Body` (cor cheia), `Core` e `Edge` (linhas quentes na
  borda da ponta), `Echo` (golpe final). Sem `Under` e `Streaks`. Rastros presos: textura lisa,
  `SwingDark` desligado (`Life = 0`).
- Brilho: céu claro + camada aditiva vira branco. Halo e corpo com LightEmission baixa (0,15 / 0);
  só núcleo e fio aditivos; Brightness ≤ 1,6 (o Bloom tem Threshold 2 e estoura acima).
- Pasta do place refeita (`sword_vfx_reset.luau`); a anterior ficou em
  `ServerStorage.SwordVFX_v3_backup`. **O dono precisa salvar o place.**
- Testado (18/10, Plays meus): capturas paradas de lado e gravações do combo a 30 qps
  (`shots/sword/m1/v4*.mp4`, comparação em `antes_depois_lento.mp4`). Não testado: `sword_combat`,
  aura equipada, outro jogador, celular, sala do golem. A fita deitada some quando vista de quina
  (câmera no plano do golpe), não vi problema no combo gravado.

## Shidori (18/10)
`src/client/ShidoriFx.luau`, tudo por código (sem pasta editável no Studio). Núcleo branco (Brightness
2,2, estoura no Bloom de propósito), esfera azul, 16 raios (Beam com `bolt`, curva pelos eixos dos
attachments inclinados, trocados a cada 0,04–0,1 s, maiores com a carga), faíscas, luz pulsando; na
explosão, flash + risco horizontal virado para a câmera (`band_core_x`) + raios de 7 studs; rastro na
mão na investida; acerto com flash, anel, faíscas, raios e luz. Sons: Pro Sound Effects da loja do
Roblox (Electricity Static 1/7/18, Electric Whoosh). Referências vistas: `shots/shidori/ref` (3 TikToks). Ver [[Shidori]].

## Regras que custaram tentativa
- O jogo tem Bloom: cúpula de choque ou onda grande e clara viram um borrão branco que esconde tudo.
  Usar onda curta, tingida e transparente; flash ≤ 0,25.
- Decalques de chão na sala do chefe: as runas de neon do estrado ficam na altura do `kit.ground`;
  desenhar 0,25 acima (`Earth.floor`).
- Aviso de área: vermelho (como o "!"), feito com SurfaceGui + UICorner/UIStroke. A textura `circle` tem
  traço fino e some; ciano some no círculo mágico da sala.
- Rocha escura some no piso escuro: clarear e dar miolo de neon grosso.
- `LightEmission` baixo (0,3) nas labaredas das auras; corte preto pede `LightEmission = 0`.
- Tudo some sozinho (Debris ou fim do `run`); nada fica conectado entre um golpe e outro.

## Laboratório de VFX (ferramenta do agente)
`lab.project.json` → `VfxLab.rbxlx` (fora do Git): place só do Studio com o golem, para iterar sem
corrida/portal. Ponte própria na porta 34875 (`BRIDGE_PORT=34875`), sincronizar com
`node tools/labsync.cjs` (sem Rojo). Teste `lab/server/tests/fx.luau <golpe> [mundo] [câmera]`.

## Referências usadas
TikToks enviados pelo dono para os golpes novos (17/10): clarão de 1-2 quadros, estouro radial de
cristais, anéis subindo, coluna de luz, fumaça baixa rolando; antecipação com carga escura e pausa.
Sekiro (Demon of Hatred) para os golpes físicos do golem.

## Não verificado
Lua crescente em movimento; efeitos do golem no mundo 2; efeitos vistos por outro jogador; celular.
