---
tags: [projeto]
atualizado: 2026-10-17
---
# Projeto

Voltar: [[INDEX]] · Tarefas e bugs: [[ROADMAP]]

## O jogo
Simulador de farm. Socar o saco dá **Poder**; na zona de carga o jogador carrega e corre por um
corredor quebrando paredes (cada parede pede um Poder mínimo). Quem limpa o corredor entra pela sala
do chefe e, ao vencer o golem, sorteia um personagem pela raridade; quem para antes sorteia pela última
parede quebrada. Personagens vão para pedestais do terreno e rendem dinheiro por segundo. Detalhes em
[[Economia]], [[Bosses]] e [[Personagens]].

## Onde as coisas estão
| O quê | Onde |
|---|---|
| Projeto | `E:\Projetos roblox\Teste_foda` (Rojo 7.7.1, `default.project.json`) |
| GitHub | https://github.com/brendoribeiron-ctrl/Run- (público) |
| Place no Studio | "Correr", placeId 104851029057967, universo 10770483571 |
| Números do jogo | `src/shared/Config.luau` |
| Código | `src/shared` → ReplicatedStorage.Shared · `src/server` → ServerScriptService.Server · `src/client` → StarterPlayerScripts.Client · testes em `src/server/tests` |
| Ferramentas | `tools/` (ponte, capturas, envio de assets, scripts do Blender) — ver [[Ferramentas]] |
| Modelos e texturas exportados | `assets/models`, `assets/textures`, `assets/animations` (ids em `src/shared/Assets.luau`, `Textures.luau`, `Animations.luau`) |
| Projetos do Blender (.blend) | `E:\Projetos roblox\Blender\` |
| Chave da Roblox | `.env` (fora do Git, nunca imprimir); `ROBLOX_CREATOR_ID=1033322591` vai na linha de comando |
| Backup do place | `copia.rbxl` (fora do Git) |
| Skills do agente | `E:\Projetos roblox\skills\` (junção em `C:\Users\brend\.claude\skills\`) |

## Decisões do dono
- Respostas em pt-BR, curtas. Commit/push só quando pedir, **sem** `Co-Authored-By`.
- Nunca parar nem testar num Play que o agente não abriu.
- Ferramenta é escolha do agente; 3D novo no Blender. **Exceção:** personagens viraram avatares do
  catálogo depois que os modelos do Blender foram recusados (ver [[Personagens]]).
- Sem PvP e sem roubo de renda entre jogadores (recusado).
- **Um anime por mundo.** Mundo 1 = Black Clover. Mundo 2 (vulcão): anime **não escolhido**.
- Economia: mundo 1 termina com 1 rebirth aos 50K; mundo 2 aos 500K.
- Sala de testes da equipe é dentro do jogo (`/lab`, `/back`); o `VfxLab` é ferramenta do agente.
- Cada jogador luta com o chefe na própria sala (decidido em 17/10; ver [[Bosses]]).
- Golpes novos do golem (Esmagamento e gancho): o dono aprovou o resultado ("gostei") em 17/10.
- Layout do HUD editado no celular **não** vale no PC (17/10; ver [[HUD]]).
- Chegar na parede de uma raridade não garante a raridade; Mítico raro até o fim (17/10; ver [[Economia]]).

## Estado do Git (verificado em 18/10)
- `main` (local e remota) continua em `7c99025`. Branch `feat/panels-super-auras` em `7cf1373`
  (enviado). Branch `claude/project-thread-oad38f` com o commit `bb6c321` (Shidori, estamina, espada,
  arte da página, `docs/`, `CLAUDE.md`, `PROMPT.md`), **enviado**, sem pull request aberto. Branch
  local `backup/antes-sem-claude` (65eb9c7) guarda o histórico de antes de tirar o `Co-Authored-By`.
- Fora do Git de propósito: `.env`, `copia.rbxl`, `/shots/`, `.obsidian/`, `.vscode/` e
  `run_videos_para_skills/` (14 MB). Perguntar ao dono antes de incluir algum.
- Página do jogo no Creator Hub (universo 10770483571): nome, descrição, gênero, ícone e a capa da
  corrida já estão lá; faltam as capas do golem e da carga. Detalhes em `art/pagina-do-jogo.md`.

## Riscos
- Personagens com nome e aparência de anime existente podem gerar denúncia de direitos autorais ou
  moderação; as peças do catálogo são de terceiros e podem sumir.
- Fora do Studio o DataStore é real: testes que mexem no perfil só no Studio. Mudar o formato do perfil
  exige migração em `PlayerData.sanitize`.

## Divergências com a memória do agente (registradas, não resolvidas)
- A memória "use Blender para 3D" não cita a exceção dos personagens.
- A ferramenta de commits sugere o trailer `Co-Authored-By`; a regra do dono prevalece (sem trailer).
