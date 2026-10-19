---
tags: [roadmap]
atualizado: 2026-10-17
---
# Roadmap

Voltar: [[INDEX]] · O que **não foi verificado** fica na nota de cada sistema.

## Concluído (commits no `feat/panels-super-auras`)
| Commit | O que entrou |
|---|---|
| `ba5eefa` … `f55d350` (12/10) | Painéis 3D, super soco, automáticos, auras, cenário do Blender, limites do mapa, salão do corredor, casa de feitiçaria, montarias, progressão, efeitos para os outros jogadores |
| `72e7ccd`, `40a0577` | Economia rebalanceada, árvore de skills, auras de voo, plots do vulcão, poções na casa da bruxa, custos de rebirth |
| `8f61f5c` | Sala do chefe (rotunda), portal e cena de entrada |
| `7c99025` | Golem: modelo e animações no Blender, IA, efeitos dos golpes |
| `1efcf3e` | Efeitos 3D do golem, sala de testes da equipe (`/lab`), laboratório de VFX |
| `11ee231` | Elenco de anime, animação de descanso, editor de HUD com o bug da opacidade corrigido (e a exclusão das capas e do ícone antigos, feita pelo dono) |
| `7cf1373` | Sala do chefe por jogador, montaria na tecla M, sorteio mais raro, layout do HUD só no celular, Esmagamento e gancho novos do golem |

## Em andamento (sem commit)
- Comando `/spawn` para admin (testado: `tests/spawn.luau`, 8 checagens) — ver [[Bosses]].
- Esta documentação (`CLAUDE.md`, `docs/`).
- Painel do balcão de poções desviando do caldeirão (17/10, **não testado no jogo**): rodar
  `tests/potion_panel.luau` num Play próprio e olhar de verdade ([[HUD]]).
- INDEX com uma aba por mundo (BLACK CLOVER / VOLCANO), Poder pelo dano no golem e skills LUCK e
  DEFENSE (17/10). Testado: `tests/progression.luau` (36), `golem` (30), `slice3` (10), `menus` (23),
  `worlds` (49), `admin` (32); capturas das abas e da árvore. Ver [[Economia]], [[Personagens]], [[Bosses]].
- Skill HEALTH com vida numerada no HUD e sorteio da vitória com sorte ×1,5 + pena de 30 vitórias
  (17/10). **Escrito, não testado**: rodar `tests/progression.luau` e `golem.luau` num Play próprio e
  capturar a barra de vida, a árvore (6 ramos) e a barra do chefe.

- Coleta de dinheiro em cima do skate/tapete corrigida (17/10): checagem por posição na placa. Testado:
  `tests/collect_mounted.luau` (21; terreno, skate, tapete, fora do alcance, sem pagar em dobro). Não
  testado com toque real no celular.

- Espada de antimagia do Asta, só para dev (17/10): `/sword` põe no inventário (slot 1 da hotbar),
  tecla 1 equipa e guarda, braço relaxado com a lâmina saindo do quadril. Testado: `tests/sword.luau` (19),
  tecla 1 no cliente (equipa) e capturas da pose nova. Falta: golpes, dano e VFX (próxima etapa), outro jogador, avatar R6,
  slot 1 no celular, teclas 2 a 9 com personagens na mochila. Ver [[Jogador]].
- Combo M1 da espada (17/10): 3 golpes com as duas mãos (IK), dano validado no servidor pela
  lâmina, aura da espada seguindo a aura equipada, rastros e impactos por golpe. Testado:
  `tests/sword_combat.luau` (26, com a ponta nunca abaixo do chão), `sword` (19), `spawn` (8); espada
  1,4× maior (`Config.Sword.size`) com trava do chão; capturas de lado, de frente, aura VOID
  e FROST e contra o golem. Falta: outro jogador, celular, R6, lag alto, desempenho. Ver [[Jogador]],
  [[VFX]].
- VFX da espada, segunda versão (17/10): texturas novas do Blender, fios de energia na lâmina,
  raios, meia-lua por golpe, impactos novos. Testado: `sword_combat` (26) e `sword` (19) depois da
  mudança; gravações a 30 qps (VOID, FROST, sem aura). Falta: outro jogador, desempenho. Ver [[VFX]].
- Rastros da espada em magia roxa (18/10): meia-lua que nasce com a lâmina, estrias rolando, cauda
  dissolvendo, pó de estrelas, impactos roxos. Testado: gravações do combo, 0 erros. Falta: o dono
  olhar no jogo, outro jogador, rodar `sword_combat`. Ver [[VFX]].
- Shidori (18/10): tecla Z, estamina nova, nó na árvore, poses, VFX/SFX, dano 1,6× do soco. Testado:
  `shidori` 34/34, `sword_combat`, `hud`, `sync`. Falta: celular de verdade, dois jogadores, R6,
  desempenho, com a espada na mão. Ver [[Shidori]].
- Rastro da espada contínuo e vivo (18/10, quarta versão): arco redondo, sem dentes nem contas,
  halo, núcleo quente, cores vivas. Testado: capturas e gravações do combo nos meus Plays. Falta: o
  dono olhar e salvar o place, `sword_combat`, aura equipada, outro jogador. Ver [[VFX]].
- Efeitos da espada editáveis no Studio (18/10): `ReplicatedStorage.SwordVFX` (partículas, beams,
  trails, luz) com padrões em `Shared/SwordVfx.luau`; o código só clona. Testado no Play. Falta: o dono
  salvar o place com a pasta; testar com aura equipada. Ver [[VFX]].

## Pendente — agente
- `tests/golem.luau` falha em "soco tira 1, crítico tira 2" (deu 30/60): o teste é anterior à
  fórmula do `CombatBalance` (o soco ainda usa a mesma conta, agora em `deal` no `Boss.luau`).
  Atualizar o teste para `CombatBalance.punchDamage`.
- Rodar as suítes que não rodaram depois das mudanças de 17/10: `hud.luau`, `mounts.luau`,
  `slice2.luau`, `sync.luau`, `boss.luau`. A lista completa de regressão nunca foi registrada; montar
  com os módulos de `src/server/tests` que não são passeios (`view_*`, `fx_*`, `setup_*`) nem utilitários.
- Golem: dano escalando com Poder/rebirths, sons, mundo 2 testado de verdade, dois jogadores; aplicar a
  receita dos golpes novos a Stomp, Sweep e Pulse se o dono quiser ([[Bosses]], [[VFX]]).
- Elenco: conferir variantes magma e shiny, desempenho com 18 avatares, avisos de console, cabelos
  repetidos (Mimosa, Mereoleona, Fuegoleon) ([[Personagens]]).
- HUD: testar com toque real ou emulador ([[HUD]]).
- Animação de descanso: avaliar em movimento; animação do bêbado no Blender conforme o dono ([[Animacoes]]).
- Placas das paredes mostram "x10 Luck", que não reflete mais a chance real do sorteio ([[Economia]]).

## Pendente — depende do dono
- Ids de **Game Pass** e produtos (`Config.Auto.*.passId` em 0) e de **áudio** (ou decidir só sons embutidos).
- Escolher o **anime do mundo 2** (a aba do INDEX se chama "VOLCANO" até lá: `Config.Worlds[2].index`).
- Decidir sobre os `art/*.png` apagados (restaurar de `7c99025` ou aceitar).
- Salvar o place no Studio (guarda o `Workspace.AnimRigs.RestRig` da animação de descanso).
- Apagar ou não o place antigo 134862178096515 (não usado; perguntar antes).
- Confirmar o que são os "quick events" do HUD.
- Página pública (18/10): nome, descrição, gênero, ícone e capa da corrida feitos; falta enviar
  `capa-2-golem.png` e `capa-3-carga.png` (ver `art/pagina-do-jogo.md`).
- Avaliar a animação do bêbado.

## Ideias aprovadas, não feitas
Feitiços com recarga e roleta de aura (casa de feitiçaria) · troca de personagens entre jogadores ·
ranking global em placar físico · evento da parede dourada · tutorial com seta · som e música ·
mundo 2 completo · montarias por Robux e sorte do servidor paga. **Recusado:** roubo de renda (PvP).

## Bugs conhecidos
1. Aviso no console sem origem: `rbxassetid://203785492 failed: Asset type does not match requested
   type` (visto de novo em 17/10). Já apareceu também `rbxassetid://1014915761 ... asset is archived`
   (talvez acessório do elenco).
2. O `Workspace` do place aberto tem dois filhos chamados "Lighting" (causa desconhecida).
3. Animação do bêbado: pé esquerdo afunda até 0,25 por alguns quadros.
4. Aparência: poça de luz da aura quase invisível em grama clara; lateral externa do corredor é um paredão liso.
