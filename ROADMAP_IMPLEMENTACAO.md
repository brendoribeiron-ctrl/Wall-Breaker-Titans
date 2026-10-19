# ROADMAP — Correções e melhorias do jogo Roblox

Quero implementar algumas melhorias no projeto atual do meu jogo no Roblox Studio.

Antes de modificar qualquer coisa, analise os scripts, módulos, interfaces e sistemas existentes relacionados a cada tarefa. Entenda como as mecânicas funcionam atualmente e procure corrigir os problemas sem quebrar funcionalidades que já estão funcionando.

Trabalhe diretamente nos arquivos do projeto, respeitando a arquitetura existente. Evite reescrever sistemas inteiros sem necessidade e valide as alterações antes de considerá-las concluídas.

## 1. Corrigir a coleta de dinheiro sobre o skate e o tapete

**Problema:** O botão de coletar dinheiro não funciona corretamente quando o jogador está em cima do skate ou do tapete.

**O que fazer:**
- Investigue a causa real do problema, verificando a detecção de proximidade, colisões, raycasts e a lógica de interação existente.
- Corrija o sistema para permitir que o jogador colete dinheiro normalmente mesmo quando estiver sobre o skate ou o tapete.
- Preserve as restrições atuais de distância e as demais regras de coleta.
- Evite duplicação de recompensas ou coleta indevida à distância.

**Critério de aceitação:** O botão de coleta funciona normalmente tanto em terreno comum quanto sobre o skate e o tapete.

## 2. Separar os personagens do segundo mundo no Index

**Problema:** Os personagens do segundo mundo estão sendo associados à categoria de Black Clover, mas devem pertencer a uma categoria independente.

**O que fazer:**
- Crie uma nova aba ou categoria no Index para os personagens do segundo mundo.
- Mantenha os personagens de Black Clover na categoria original.
- Garanta que os personagens do segundo mundo apareçam na nova aba.
- Preserve os dados existentes, incluindo raridades, ícones, desbloqueios e progresso.
- Verifique se os filtros, a navegação e a exibição dos personagens continuam funcionando corretamente.

Não duplique personagens nem remova registros existentes desnecessariamente.

**Critério de aceitação:** Cada mundo possui sua própria categoria no Index, com os personagens classificados corretamente e sem perda de dados.

## 3. Corrigir o posicionamento do painel do caldeirão

**Problema:** Em determinadas situações, quando o jogador interage com o caldeirão, o painel aparece dentro da estrutura do próprio objeto, prejudicando a visualização.

**O que fazer:**
- Ao iniciar a interação com o caldeirão, ajuste automaticamente a orientação da câmera para um ângulo que permita visualizar corretamente o painel.
- Considere a posição do jogador e o lado pelo qual ele se aproxima.
- Faça a rotação da câmera de maneira suave, evitando movimentos bruscos.
- Garanta que o painel não fique encoberto pela estrutura do caldeirão.
- Se necessário, ajuste também a posição do painel para garantir sua visibilidade.
- Ao fechar o painel, restaure o controle normal da câmera do jogador.

Não utilize apenas uma rotação fixa que funcione em uma única posição. A solução deve funcionar independentemente da direção de aproximação.

**Critério de aceitação:** O painel abre em uma posição visível, sem ficar dentro do caldeirão, e a câmera retorna ao comportamento normal após a interação.

## 4. Ajustar a iluminação da sala do boss de magma e preparar uma futura expansão

### 4.1. Reduzir o brilho excessivo

**Problema:** A sala do boss de magma está brilhosa demais, prejudicando a visualização do ambiente e dos elementos do combate.

**O que fazer:**
- Analise a iluminação, os materiais emissivos, as partículas, as luzes locais e os efeitos de pós-processamento.
- Reduza o excesso de brilho sem eliminar a identidade visual de magma e ambiente vulcânico.
- Melhore o contraste entre o boss, os ataques, os jogadores e o cenário.
- Garanta que os efeitos visuais não prejudiquem a leitura das animações e dos indicadores de perigo.
- Evite alterações desnecessárias que prejudiquem o desempenho.

O objetivo é manter uma sala visualmente marcante, mas com uma iluminação equilibrada e confortável para jogar.

### 4.2. Preparar a possibilidade de adicionar outro boss no futuro

Atualmente, a sala utiliza o boss existente. Planejo adicionar futuramente outro boss, com um modelo 3D diferente e ataques próprios.

**Importante: NÃO vamos criar, modelar, importar ou implementar o segundo boss nesta etapa.**

Neste momento, quero apenas manter essa possibilidade em mente durante a análise e evitar decisões técnicas que dificultem uma expansão futura.

- Não crie modelos 3D, personagens, animações ou ataques para o novo boss.
- Não duplique o boss atual para simular um segundo boss.
- Não substitua o boss existente.
- Não faça alterações desnecessárias na arquitetura atual apenas para antecipar essa expansão.
- Caso identifique uma melhoria estrutural simples e útil para permitir a adição de novos bosses futuramente, avalie se ela pode ser feita sem aumentar desnecessariamente o escopo desta tarefa.

**Critério de aceitação:** A sala atual apresenta iluminação equilibrada, o boss existente continua funcionando e nenhuma implementação do segundo boss é realizada.

## 5. Melhorar o sistema de nível de poder e a árvore de habilidades

Quero que o nível de poder do jogador tenha uma relação mais consistente com seu desempenho no combate contra os bosses. Além disso, a árvore de habilidades deve oferecer os atributos Sorte e Defesa.

### 5.1. Relacionar o nível de poder ao dano causado aos bosses

**Problema:** O nível de poder precisa refletir melhor a contribuição do jogador durante o combate.

**O que fazer:**
- Analise como o nível de poder é calculado atualmente.
- Implemente uma regra para que o dano efetivamente causado aos bosses contribua para a progressão do jogador.
- Defina uma fórmula configurável e compatível com a economia e os atributos existentes.
- Evite progressão artificial por eventos duplicados, dano inválido ou exploração de mecânicas.
- Preserve os demais métodos de progressão existentes, salvo quando houver incompatibilidades reais.

Não escolha valores arbitrários sem analisar o balanceamento atual do jogo.

### 5.2. Adicionar o atributo Sorte

Adicione o atributo **Sorte (Luck)** à árvore de habilidades.

- Permita que o jogador invista pontos nesse atributo seguindo as regras atuais de progressão.
- Prepare sua integração com sistemas compatíveis, como chances de recompensas ou raridades, quando esses sistemas existirem.
- Respeite os limites de probabilidade e evite recompensas garantidas indevidamente.
- Caso não exista uma mecânica compatível no momento, implemente o atributo e sua estrutura sem inventar sistemas de recompensa fora do escopo.

### 5.3. Adicionar o atributo Defesa

Adicione o atributo **Defesa (Defense)** à árvore de habilidades para permitir que o jogador suporte mais dano durante os combates.

- Faça com que investir em Defesa reduza o dano recebido.
- Utilize uma fórmula progressiva e configurável.
- Estabeleça limites para impedir que o jogador se torne invulnerável.
- Garanta que a defesa seja aplicada corretamente aos ataques relevantes.
- Evite aplicar a mitigação duas vezes ou criar inconsistências entre diferentes fontes de dano.

### 5.4. Integrar os atributos à interface e ao combate

- Integre Sorte e Defesa à árvore de habilidades existente.
- Exiba os valores atuais e os custos de melhoria de forma clara.
- Respeite os pontos disponíveis, os requisitos e as regras de progressão.
- Valide as compras e alterações de atributos no servidor.
- Verifique se os atributos realmente influenciam os sistemas correspondentes, em vez de apenas atualizar números na interface.

**Critério de aceitação:** O jogador consegue investir em Sorte e Defesa, visualizar seus atributos e perceber o efeito da Defesa durante o combate. O nível de poder também passa a considerar o dano válido causado aos bosses.

## 6. Regras gerais de implementação

Durante toda a execução:

1. Analise os arquivos existentes antes de editar.
2. Identifique as dependências entre os sistemas afetados.
3. Reutilize a arquitetura atual sempre que possível.
4. Evite duplicar lógica ou criar sistemas paralelos desnecessários.
5. Mantenha a autoridade do servidor sobre progressão, atributos e recompensas.
6. Valide os dados recebidos do cliente e as chamadas de eventos remotos quando aplicável.
7. Centralize os parâmetros de balanceamento para facilitar ajustes posteriores.
8. Preserve funcionalidades existentes que não estejam diretamente relacionadas às mudanças.
9. Faça alterações modulares e fáceis de reverter.
10. Não declare uma funcionalidade concluída sem verificar sua implementação e executar os testes possíveis.

## 7. Ordem de execução

Execute as tarefas na seguinte ordem:

1. Audite os sistemas e identifique os arquivos envolvidos.
2. Corrija a coleta de dinheiro sobre o skate e o tapete.
3. Separe os personagens do segundo mundo no Index.
4. Corrija a câmera e a visibilidade do painel do caldeirão.
5. Ajuste a iluminação da sala do boss de magma.
6. Integre a progressão por dano e os atributos Sorte e Defesa.
7. Execute os testes finais e corrija eventuais regressões.

Conclua cada tarefa antes de avançar para a próxima, verificando se as mudanças não prejudicaram os sistemas anteriores.

Não pare apenas na apresentação de um plano. Execute as alterações diretamente no projeto, dentro das capacidades disponíveis.

## 8. Relatório final

Ao terminar, apresente:

- Arquivos criados e modificados.
- Resumo das alterações realizadas em cada tarefa.
- Fórmula e parâmetros utilizados na progressão por dano.
- Funcionamento dos atributos Sorte e Defesa.
- Testes executados e resultados observados.
- Problemas ou limitações que ainda precisam ser resolvidos.
- Instruções para testar as funcionalidades no Roblox Studio.

**Escopo obrigatório:** nesta etapa, o trabalho se limita às cinco tarefas descritas neste documento. O segundo boss permanece como uma expansão futura; não crie nem implemente seu modelo, suas animações ou seus ataques.