---
tags: [sistema]
aliases: [Progressão, Mundos, Monetização]
---
# Economia, progressão e mundos

Voltar: [[INDEX]] · Relacionado: [[Jogador]], [[Personagens]], [[Bosses]]

Todos os valores estão em `src/shared/Config.luau`; os números abaixo servem de orientação e podem
estar desatualizados — confira o Config.

## Loop principal
1. **Saco de pancada** (`Bag`, cliente `Bag.luau`): cada soco dá Poder. `Config.Bag.levels`: 25 níveis
   (1-15 no mundo 1, 16-25 no mundo 2).
2. **Corrida** (`src/server/Run.luau`, cliente `Run.luau`): carregar na zona de carga e correr; cada
   parede de `Config.Walls` (mundo 1) / `Config.VolcanoWalls` (mundo 2) pede um Poder mínimo e tem um
   tier de raridade. A corrida para na primeira parede que o jogador não quebra.
3. **Sorteio** (`Run.rollCharacter`): raridade pela tabela `Config.Roll.odds` do tier da última parede.
   Desde 17/10, chegar na parede de uma raridade **não garante** a raridade; a segunda parede do tier e
   a poção de sorte multiplicam do Raro para cima. Na última parede o Mítico fica em ~1,3 % (~1,5 % com
   poção 2×). Limpar o corredor leva à sala do chefe; o sorteio vem ao vencer o golem, com a tabela da
   última parede ([[Bosses]]).
4. **Pedestais** (`Pedestals.luau`): 1º grátis, depois 1K, 3K, 8K, 20K, 50K, 150K, 500K, 1,5M, 4M; um
   botão COLLECT por terreno (placa de pressão: `Touched` + checagem por posição do `HumanoidRootPart` a cada 0,15 s em `Pedestals.luau`, porque em skate/tapete o boneco sobe 1,7–1,9 e os pés não tocam a placa; testado em `tests/collect_mounted.luau`, 21 checagens). Nível do personagem (tecla F no pedestal, até 10, +25 %/nível).
   Venda = renda × `Config.Inventory.sellSeconds` (20 s). Fusão de 3 iguais = Shiny (3× a renda).

## Progressão (`src/server/Progress.luau`)
- **Rebirth:** custos 50K, 250K, 500K, 1M, 2M, 5M, 10M, 20M, 50M, depois ×2, ×2, ×2,5
  (`Config.rebirthCost`). Mundo 1 termina com 1 rebirth aos 50K; mundo 2 aos 500K.
- Poções (2× Poder, dinheiro ou sorte, 5 min, acumulam até 30 min) só na casa da bruxa.
- **Poder pelo golem** (desde 17/10): cada dano válido no golem dá Poder = dano × Poder do soco no saco
  (nível atual) × `Config.Boss.powerPerDamage` (1), com aura, rebirth, poção e amigos (os mesmos do saco).
  Desde 17/10 o "dano" aqui é em **socos cheios** (1; crítico 2), porque a vida tirada por soco cresce com o
  Poder ([[Bosses]], balanceamento). Só conta o que `Boss.punch` aceita (luta acordada, sala do jogador,
  alcance, ritmo de 0,22 s) e só a vida que restava. O cliente mostra o número sobre o golem.
- **Skills LUCK e DEFENSE** (`Config.Stats`, árvore com 5 ramos em `Stats.luau`, 10 nós, 30 % antes do
  mundo 2, compra validada em `buyStat`). LUCK: +5 %/nível na sorte do sorteio, multiplicando a poção, com
  teto `Config.Roll.maxLuck` (3) — afeta só raridades do Raro para cima (`Progress.luckBoost`). DEFENSE:
  −4 %/nível no dano do golem, teto 50 %, mínimo 1 (`Config.defendedDamage`, aplicado uma vez em
  `Boss.hurt`, depois da raiva). Custos: 500 e 450 × 2,2^nível.
- **Skill HEALTH** (6º ramo): vida máxima = `Config.Health.base` (100) + 20/nível (300 no 10; 160 no teto do
  mundo 1). O servidor põe no `Humanoid.MaxHealth` ao nascer (cheio) e quando o nível muda (soma só a
  diferença). O HUD mostra a vida com número (`❤ 140 / 160`, bloco Stats); a barra do Roblox foi desligada.
  **Não testado** (o Studio estava num Play do dono): checagens novas em `tests/progression.luau`.
- **Sorteio da vitória no chefe** (`Run.reward`): sorte do jogador × `Config.Boss.victoryLuck` (1,5), do
  Raro para cima. **Pena:** a `Config.Boss.pity`ª (30ª) vitória num mundo garante o melhor personagem dele
  (`Config.bestCharacter`: Demon Asta / Magma Demon Asta); o contador é por mundo (`profile.bossWins`,
  atributo `BossWins`) e zera quando esse personagem sai, garantido ou não. Só conta vitória com direito
  ao sorteio (`/spawn` não conta). A barra do chefe mostra "BOSS PITY n/30". **Não testado** (idem).
- Diária de 7 dias, 4 missões do dia, 6 recompensas de tempo de jogo, bônus de amigos (+10 % por
  amigo, até 50 %), árvore de skills (cliente `Stats.luau`).

## Mundos (`Config.Worlds`)
- Mundo 1: gramado/arcano. Mundo 2: vulcão (`offset` 9000, sufixo `_magma`, renda ×10), liberado pelo
  feiticeiro (`Wizard.luau`) por rebirths. O tema de anime do mundo 2 não foi escolhido.

## Monetização
- A loja mostra só game passes; `Config.Auto.*.passId` está em 0 (faltam os ids do dono).
- Planejado: VIP, 2× Poder, 2× dinheiro, auto click, auto super, montarias por Robux, sorte do servidor paga.

## Dados do jogador
`src/server/PlayerData.luau`: perfil versionado (`Config.DataVersion`), atributos replicados. Mudança de
formato pede migração em `sanitize`. Fora do Studio o DataStore é real.

## Não verificado
- Poder pelo golem: equilíbrio com o tempo de progressão (uma luta de 80 socos ≈ 80 socos no saco).
- LUCK/DEFENSE com jogador real (só testes pelo TestHook e captura da árvore).
- Tempo de progressão ("1h30 a 2h para zerar" é conta de papel).
- `tests/slice2.luau` foi atualizado para a tabela nova do sorteio mas **não rodou** depois da mudança.
- Placas das paredes ainda mostram "xN Luck", que não corresponde mais à chance real.
