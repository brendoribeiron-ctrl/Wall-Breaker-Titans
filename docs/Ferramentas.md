---
tags: [ferramentas]
aliases: [Testes, Fluxo de trabalho]
---
# Ferramentas, testes e admin

Voltar: [[INDEX]] · Skills: `roblox-live-game-iteration`, `roblox-agent-studio-playtest`, `roblox-studio-pipeline`

## Ciclo
editar → conferir sintaxe → Play **próprio** → testes pela ponte → capturas → parar o Play que você
abriu. Scripts auxiliares (`play.cjs`, `syntax.cjs`, `sheet.ps1`) em
`E:\Projetos roblox\skills\roblox-live-game-iteration\scripts`.

## Rojo e Studio
- `rojo serve` (porta 34872) + Connect no plugin do Studio. O Rojo sincroniza o modo de edição: arquivo
  novo só chega num Play aberto depois.
- Studio MCP (`Roblox_Studio`): obter o id da instância com `list_roblox_studios` (muda a cada abertura);
  `get_studio_state` antes de qualquer Play. O `require` do `execute_luau` roda em outra VM.

## Ponte e testes
- `node tools/bridge.cjs serve` (porta 34871, em segundo plano); plugin `tools/plugin/StudioBridge.lua`.
- `node tools/bridge.cjs run server src/server/tests/<nome>.luau <ms> [args]` — no Play não há
  `loadstring`: todo teste é módulo em `src/server/tests` (args chegam no atributo `Args` da pasta).
  Os testes usam o `TestHook` (só existe no Studio, em `init.server.luau`).
- Tipos de módulo em `src/server/tests` (52): suítes de checagem (ex.: `golem`, `hud`, `mounts`,
  `slice1-3`, `worlds`, `progress`, `anime`, `admin`, `spawn`), passeios de captura (`view_*`, `fx_*`) e
  utilitários (`setup_*`, `state`, `stop`, `tp`, `where`, `walk`, `give*`).
- A regeneração de vida do Roblox mascara dano: destruir o script `Health` do boneco ou medir a menor vida.

## Capturas
`powershell -File tools\screenshot.ps1 -Out <arquivo> [-Count N -IntervalMs M -DelayMs D] [-Window VfxLab]`
pega a janela inteira do Studio (~0,2 s por quadro na prática); recortar o viewport e juntar em folha de
contato com ffmpeg (`-f concat`; este ffmpeg não tem `-pattern_type glob` nem `drawtext`). `shots/` fica fora do Git.

## Blender e envio de assets
- Scripts em `tools/blender/` (`golem.py`, `golem_v2.py`, `boss_fx.py`, `boss_room.py`, `sanctum.py`,
  `mounts.py`, `volcano.py`, `wizard.py`, `aura_textures.py`, `kit.py`...), rodando com
  `"C:\Program Files\Blender Foundation\Blender 5.0\blender.exe" -b --factory-startup -P <script>`.
- Envio pela Open Cloud: `ROBLOX_CREATOR_ID=1033322591 node tools/upload_assets.cjs <pasta>` (FBX, PNG,
  `.rbxm` de animação); ids gravados em `Assets.luau`/`Textures.luau`/`Animations.luau`. Limite de 20k
  triângulos por malha. A memória do Windows não aguenta gerar texturas grandes de uma vez (`ONLY=...`).

## Comandos de admin (`src/server/init.server.luau`, `Admin.luau`)
Admin = Studio, `Config.Admins`, dono do jogo ou cargo alto no grupo.
`/giveall [jogador]` · `/give power|money <qtd> [jogador]` · `/reset [jogador]` · `/lab` e `/back`
(sala de testes da equipe, `DevArea.luau`) · `/spawn [golpe]` (ver [[Bosses]]) ·
`/sword` e `/sword off` (põe e tira a espada do Asta do inventário, slot 1; ver [[Jogador]]).
TestHook `swordcombat` (servidor) e TestUi `swordCombat` (cliente: click, spam, hold, lockAim, aim,
reset) para os testes do combo.
Não verificado: permissão de admin no jogo publicado.
