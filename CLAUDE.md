# Instruções para o agente — Wall Breaker Titans

Jogo de Roblox feito em código (Rojo 7.7.1). A base de conhecimento está em `docs/` (vault do
Obsidian = esta pasta). Comece por `docs/INDEX.md`.

## Como usar a documentação
- Leia **só** o documento do sistema que a tarefa toca (ver `docs/INDEX.md`), mais `docs/Projeto.md`
  quando a tarefa envolver regras gerais, Git ou decisões do dono.
- A documentação descreve; o código manda. **Confira o código atual antes de mudar algo** e não confie
  em número de linha ou valor citado nos docs (os números do jogo estão em `src/shared/Config.luau`).
- Comece pela busca do símbolo/termo ligado à tarefa (`rg` ou busca do editor). Leia só os módulos
  encontrados e trechos relevantes; não abra arquivos inteiros grandes por padrão. Leia dependências
  diretas apenas quando forem necessárias para entender a mudança.
- Não carregue `PROMPT.md`, `ROADMAP_IMPLEMENTACAO.md`, histórico de conversas, dumps do mapa,
  `sourcemap.json`, capturas ou arquivos binários (`.rbxl`, `.rbxlx`, `.rbxm`, `.fbx`, `.png`) como
  contexto geral. Consulte cada um só quando a tarefa tratar diretamente do assunto nele contido ou
  pedir esse material. Eles não são instruções permanentes.
- Em chamadas MCP, peça/retorne só os objetos, propriedades e resultados necessários. Não despeje a
  árvore inteira do Studio, o conteúdo completo de um place, logs ou capturas em lote sem necessidade.
  Use o Studio MCP para tarefas que dependem do estado do Studio; use o Blender MCP para trabalho 3D.
- Ao inspecionar pastas, filtre pelo caminho e extensão relevantes e limite a saída. Evite listagens
  recursivas completas e comandos que imprimam arquivos inteiros sem necessidade.
- Ao terminar uma tarefa que mude comportamento, decisão, bug ou pendência, **atualize o documento do
  sistema e o `docs/ROADMAP.md`**. Marque o que foi verificado e o que não foi. Não crie documento novo
  se um existente cobre o assunto; não copie histórico de conversa.
- `E:\Projetos roblox\Contextos_foda\` guarda os contextos antigos (histórico). Consulte só se um doc
  apontar para lá. `fodao.md` dessa pasta não é base do projeto.

## Regras do dono (permanentes)
- Responder sempre em **português (pt-BR)**, curto. "Responda primeiro" = responder antes de codar.
- **Commit e push só quando o dono pedir.** Mensagem em inglês curto, **sem** `Co-Authored-By`.
  Listar os caminhos no `git add`; `copia.rbxl` e `.env` nunca entram; nunca imprimir o `.env`.
- **Nunca parar nem testar numa sessão de Play que você não abriu.** Confira o estado do Studio antes;
  abra a sua, use e feche. Módulo de teste novo só existe num Play novo.
- A escolha da ferramenta é sua (código, Blender, Eclipse Animator, plugins); diga em uma linha qual usou.
  3D novo no Blender, com capricho; exceção: personagens (avatar do catálogo, ver `docs/Personagens.md`).
- Sem PvP e sem roubo de renda entre jogadores. Um anime por mundo.
- Skills novas em `E:\Projetos roblox\skills`, com junção em `C:\Users\brend\.claude\skills`.
- Diferencie sempre o que foi testado do que não foi; não afirme que passou sem ter rodado.
