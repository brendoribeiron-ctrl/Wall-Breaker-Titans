---
tags: [sistema]
aliases: [Elenco]
---
# Personagens (elenco de anime)

Voltar: [[INDEX]] · Relacionado: [[Economia]] · Skill: `roblox-catalog-anime-characters`

## Decisão
Pedido do dono: um anime por mundo, fiel, com a base do *Build an Anime Farm*; mundo 1 = **Black Clover**.
Os modelos feitos no Blender (`tools/blender/anime.py`) foram **recusados** ("feio"); ficaram como
arquivo em `assets/anime_blender/`. Rota atual, a partir do *Asta Timeskip* (Creator Store 8894831008):
cada personagem é um **avatar R6 montado com peças públicas do catálogo** (cabelo, rosto, camisa e calça
clássicas, acessórios) por `Players:CreateHumanoidModelFromDescription` no servidor.

## Como funciona
- `src/shared/AnimeCast.luau`: chave → ids do catálogo (`hair`, `face`, `shirt`, `pants`, `back`, `waist`, `shoulder`).
- `Config.Characters[i].model` aponta para a chave. **Os ids dos personagens foram mantidos** (saves não
  quebram); mudaram só nomes e aparência. Não mudar ids, raridades nem renda.
- `src/server/CharacterMeshes.luau` monta todos no início em `ReplicatedStorage.CharacterMeshes` (pivô na
  sola, frente -Z) e refaz os pedestais de quem já entrou.
- `src/shared/CharacterModels.luau`: `build(id, scale)` clona o avatar (tinge magma e shiny) ou usa o
  boneco antigo enquanto o avatar não chegou; `render(viewport, id)`. Usado por `Pedestals`, `Hud`,
  `Menus` e `Roll`.
- INDEX (`Menus.luau`): uma aba por mundo, com a lista em `Config.IndexByWorld` (título em
  `Config.Worlds[i].index`: "BLACK CLOVER" e "VOLCANO"). As versões de magma ficam só na aba do vulcão;
  shiny não entra. Os cartões de uma aba só são montados quando ela abre. Os atributos `Index` e
  `Levels` passaram a levar os ids de magma (que já eram salvos no perfil); com isso o preço de venda de
  personagem de magma na mochila passou a usar o nível certo. Testado em `tests/progression.luau` e
  `menus.luau`, com captura das duas abas.
- Teste: `src/server/tests/anime.luau` (345 checagens; passou em 17/10, antes das mudanças da tarde).

## Elenco do mundo 1 (por raridade)
Comum: Magna, Luck, Secre · Incomum: Vanessa, Zora, Mimosa · Raro: Noelle, Yuno, Nacht ·
Épico: Asta, Mereoleona, Fuegoleon · Lendário: Yami, Zenon, Dante · Mítico: Julius, Lucius, Asta Demônio.
Fora por falta de peças no catálogo: Finral, Gauche, Charmy, Licht, Leopold.

## Não verificado
- Variantes magma e shiny (camisa e calça não aceitam tinta).
- Desempenho com 18 avatares em miniaturas; montagem no jogo publicado (só rodou no Studio).
- Cabelos repetidos (Mimosa, Mereoleona, Fuegoleon) — aceitar ou trocar é do dono.

## Riscos
Nome e aparência de anime existente podem gerar denúncia/moderação; peças de terceiros podem sumir (o
teste deve falhar claro se faltar roupa ou cabelo).
