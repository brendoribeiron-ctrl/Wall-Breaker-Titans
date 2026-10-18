# MISSÃO COMPLETA — DESENVOLVIMENTO DO SHIDORI PARA ROBLOX
## Produção profissional de animação, VFX, SFX, combate e integração com a arquitetura existente

Você é responsável por desenvolver e integrar uma habilidade chamada **Shidori** ao meu jogo Roblox. Quero que você trabalhe com autonomia técnica e criativa, utilizando todos os recursos efetivamente disponíveis no seu ambiente para entregar a melhor implementação possível.

Não quero apenas um script funcional com partículas básicas. Quero uma habilidade visualmente elaborada, com animação própria, energia elétrica concentrada na mão esquerda, efeitos visuais bem construídos, efeitos sonoros sincronizados e integração completa com os sistemas de combate e progressão do jogo.

Você tem liberdade para pesquisar, criar modelos, produzir animações, desenvolver VFX, utilizar plugins, automatizar ferramentas, adaptar recursos existentes e testar diferentes abordagens.

**A prioridade é a qualidade final da habilidade, sem comprometer o balanceamento, a segurança ou a arquitetura do projeto.**

---

# 1. CONCEITO FUNDAMENTAL DA HABILIDADE

O Shidori é uma habilidade inspirada no Chidori de Naruto. O personagem concentra energia elétrica na própria mão esquerda, produzindo um efeito energético intenso e visualmente convincente.

**O Shidori NÃO utiliza espada.**

A espada foi mencionada anteriormente exclusivamente como referência técnica para os efeitos visuais já desenvolvidos no projeto. Não deve aparecer na execução da habilidade, não deve ser necessária para ativá-la e não deve participar da animação.

O objetivo é reaproveitar as técnicas, os componentes e os conhecimentos utilizados na produção do VFX da espada, adaptando-os para criar um efeito elétrico concentrado na mão esquerda do personagem.

Quando o jogador pressionar Z no PC ou utilizar o botão correspondente no mobile, a animação deverá começar pelo braço esquerdo. A energia surgirá e se acumulará na mão, acompanhando os movimentos do personagem.

A habilidade deve ter identidade visual própria, sem parecer uma simples adaptação de um ataque com espada.

## Resultado visual esperado

- O braço esquerdo participa ativamente da animação.
- A mão esquerda é o ponto central da concentração de energia.
- A eletricidade acompanha os movimentos do braço e permanece visualmente conectada à mão.
- O efeito apresenta profundidade, movimento, iluminação e variação de intensidade.
- A animação transmite preparação, concentração de energia, potência e recuperação.
- Os efeitos sonoros acompanham os eventos visuais.
- O encerramento da habilidade é natural e não deixa efeitos presos ao personagem.

Não escolha uma implementação superficial apenas porque é mais rápida. Pesquise e experimente técnicas diferentes até obter um resultado adequado.

---

# 2. REFERÊNCIAS VISUAIS OBRIGATÓRIAS

Analise os três vídeos enviados antes de definir a implementação visual e a animação.

### Referência 1 — Shadoricals

https://www.tiktok.com/@shadoricals/video/7528904024708435222

### Referência 2 — Syn.ils

https://www.tiktok.com/@syn.ils/video/7600875451808042261

### Referência 3 — Ofc Mochi Studio

https://www.tiktok.com/@ofc_mochi_studio/video/7562295485776612621

Não utilize esses links apenas como inspiração genérica. Analise os vídeos completos quando possível e observe os detalhes que podem orientar a produção.

Investigue:

- Qualidade e fluidez das animações.
- Antecipação, preparação e recuperação dos movimentos.
- Posicionamento do braço e da mão.
- Timing, aceleração e desaceleração.
- Construção dos efeitos energéticos.
- Utilização de partículas, rastros, meshes, iluminação e texturas.
- Intensidade e distribuição da energia.
- Sincronização entre animação, VFX e SFX.
- Composição visual, câmera e percepção de impacto.
- Técnicas que possam ser reaproveitadas para uma habilidade elétrica na mão.

As referências foram fornecidas para orientar a qualidade da produção. Identifique separadamente o que cada vídeo oferece e combine os elementos que forem compatíveis com o conceito do Shidori.

Não copie mecanicamente a animação da espada ou de qualquer outra habilidade mostrada. Adapte os princípios visuais à mão esquerda do personagem.

### Se os vídeos não estiverem acessíveis

Utilize as ferramentas disponíveis para tentar acessá-los por um navegador, automação de navegador, páginas públicas relacionadas ou outras fontes legítimas.

Se não conseguir visualizar determinado vídeo, não afirme que o analisou. Registre a limitação e procure referências complementares para continuar o trabalho.

---

# 3. PESQUISA COMPLEMENTAR

Não fique limitado aos três vídeos.

Pesquise na internet outras referências técnicas e visuais de:

- Chidori e habilidades elétricas concentradas nas mãos.
- Animações de personagens com poderes energéticos.
- Animações de combate com preparação e impacto.
- VFX elétricos para jogos Roblox.
- Rastros de energia, descargas, iluminação e partículas.
- Animação de braços, mãos e personagens com rigs R6 e R15.
- Produção de habilidades cinematográficas em jogos.
- Criação de meshes, texturas e recursos auxiliares no Blender.
- Sincronização de efeitos visuais e sonoros com animações.

Consulte tutoriais, demonstrações, repositórios públicos e documentação oficial quando forem relevantes.

Referências técnicas iniciais:

- Roblox — Animação: https://create.roblox.com/docs/tutorials/curriculums/animator
- Roblox — Blender: https://create.roblox.com/docs/art/blender
- Roblox — Recursos para artistas e VFX: https://create.roblox.com/docs/tutorials/curriculums/artist
- YouTube — Tutorial de animação com Moon Animator: https://www.youtube.com/watch?v=UURYhAVph5g

Esses links são pontos de partida. Verifique se continuam disponíveis e se correspondem às versões atuais das ferramentas.

Pesquise soluções técnicas reais, não apenas imagens de referência. O objetivo é descobrir como produzir e integrar os efeitos, e não somente escolher uma aparência.

---

# 4. AUTONOMIA TOTAL PARA UTILIZAR FERRAMENTAS

Você tem autorização para explorar os recursos de desenvolvimento disponíveis no ambiente, sem se limitar ao editor de código.

Avalie a utilização de:

- **Roblox Studio:** integração, animações, montagem dos efeitos, execução e testes.
- **Blender:** criação de meshes, objetos auxiliares, geometrias energéticas, texturas e recursos necessários aos efeitos.
- **Moon Animator ou ferramentas equivalentes:** produção e refinamento das animações.
- **VS Code e agentes de programação:** implementação, análise de código, refatoração e testes.
- **Playwright:** automação de navegador e interação com ferramentas web compatíveis.
- **MCPs disponíveis:** integração com Roblox Studio, Blender ou outras aplicações quando houver conectores funcionais.
- **Packs de VFX:** recursos de partículas, meshes, texturas e efeitos compatíveis com o projeto.
- **Bibliotecas de SFX:** sons elétricos, energéticos, impactos e camadas sonoras.
- **Ferramentas externas de modelagem, animação, edição e áudio:** sempre que oferecerem uma vantagem concreta.

Você pode investigar outras ferramentas, inclusive as que não foram mencionadas.

Não presuma que todos esses programas estão instalados ou que suas integrações estão funcionando. Verifique o ambiente real, as dependências disponíveis e os recursos aos quais você tem acesso.

Quando uma ferramenta não estiver disponível, procure uma alternativa funcional. Se uma instalação for necessária, avalie os requisitos e proceda conforme as permissões existentes.

Utilize automação quando ela realmente ajudar. Não tente forçar uma integração inexistente nem considere uma operação concluída sem verificar seu resultado.

**A liberdade está nos meios utilizados para produzir a habilidade. O resultado esperado continua sendo uma habilidade real, funcional e integrada ao jogo.**

---

# 5. REAPROVEITAMENTO DO SISTEMA DE VFX DA ESPADA

Antes de criar efeitos do zero, investigue o sistema de VFX desenvolvido anteriormente para a espada.

Identifique os scripts, módulos, recursos, texturas, meshes, configurações, técnicas e componentes utilizados naquela implementação.

Avalie o que pode ser reaproveitado para criar o Shidori.

Por exemplo:

- Sistemas de partículas.
- Beams e Trails.
- Attachments.
- Iluminação localizada.
- Texturas de energia.
- Meshes personalizados.
- Efeitos de distorção ou impacto, quando disponíveis.
- Sistemas de limpeza e gerenciamento de efeitos temporários.
- Técnicas de sincronização entre animação e efeitos.

Não presuma que todos esses componentes já existem. Localize os recursos reais antes de utilizá-los.

Adapte os componentes selecionados à anatomia do personagem e à natureza elétrica da habilidade.

Se a implementação anterior não puder ser reutilizada diretamente, aproveite o conhecimento técnico e desenvolva uma solução equivalente ou superior.

**Reutilize a tecnologia e a qualidade do VFX da espada, nunca a espada como parte do Shidori.**

---

# 6. ANIMAÇÃO PROFISSIONAL DO PERSONAGEM

A animação deve ser uma das prioridades máximas do desenvolvimento.

Não aceite como resultado final uma animação genérica, um movimento rígido de braço ou uma sequência produzida apenas para demonstrar que a habilidade funciona.

Inspecione o rig real do personagem e desenvolva a animação para o sistema utilizado no projeto.

Considere:

- Preparação corporal antes da manifestação da energia.
- Posicionamento convincente do braço esquerdo.
- Movimento natural dos ombros, tronco e braço.
- Orientação coerente do pulso e da mão.
- Transferência de peso quando necessária.
- Antecipação antes da execução.
- Curvas de animação e interpolação bem ajustadas.
- Aceleração e desaceleração controladas.
- Pausas deliberadas para destacar momentos importantes.
- Recuperação corporal após o encerramento.
- Transições compatíveis com o sistema de combate.

A animação deve transmitir a sensação de que o personagem está concentrando e controlando uma grande quantidade de energia na mão esquerda.

Use ferramentas adequadas para produzir e refinar a animação. Caso seja necessário, crie várias versões, compare o resultado e ajuste os keyframes até atingir uma execução convincente.

Não utilize uma animação de espada como base mecânica sem adaptação. O movimento deve ter sido concebido para o Shidori.

---

# 7. SEQUÊNCIA VISUAL DA HABILIDADE

Desenvolva uma sequência coerente, ajustando os tempos após estudar as referências e testar a animação.

### Fase A — Preparação

O personagem inicia o movimento com o braço esquerdo. A postura deve comunicar intenção e preparar visualmente a concentração de energia.

### Fase B — Acúmulo

A eletricidade começa a surgir na mão esquerda. O efeito aumenta gradualmente em intensidade, volume e movimento.

A construção da energia deve ser visível e integrada à animação, evitando que o Shidori simplesmente apareça instantaneamente sem preparação visual.

### Fase C — Manifestação

A energia elétrica atinge sua forma principal, concentrada na mão esquerda.

Explore descargas elétricas, partículas, iluminação, geometria energética, variações de intensidade e outros recursos que sejam compatíveis com as referências.

O efeito deve possuir leitura visual clara, sem se transformar em uma massa de partículas que esconda completamente a mão.

### Fase D — Estado ativo

A energia permanece associada à mão enquanto a habilidade estiver ativa.

A duração e o comportamento exatos devem respeitar a mecânica implementada. Não invente uma duração definitiva sem analisar o conceito do poder e a arquitetura atual.

### Fase E — Encerramento

A energia se dissipa progressivamente. O braço acompanha o movimento de recuperação e os efeitos terminam sem deixar objetos ou partículas permanentes.

Se a mecânica exigir que o Shidori seja usado para atingir um alvo, defina uma janela de ataque e sincronize o dano com o momento apropriado da animação.

Não adicione ataques, investidas ou propriedades adicionais que alterem a proposta da habilidade sem justificativa técnica e compatibilidade com o combate existente.

---

# 8. VFX — EFEITOS VISUAIS ELABORADOS

Não concentre toda a implementação em um único ParticleEmitter ou em uma explosão genérica.

Projete o efeito em camadas, utilizando os recursos adequados para cada função.

Considere:

- Partículas elétricas de diferentes tamanhos e velocidades.
- Descargas que percorrem a região da mão.
- Beams ou elementos geométricos para representar energia.
- Variações de transparência, tamanho e intensidade.
- Iluminação localizada e pulsante.
- Texturas e meshes personalizados.
- Efeitos de dissipação.
- Pequenos elementos residuais que reforcem a sensação de energia ativa.

Esses recursos são possibilidades, não uma lista obrigatória de objetos a serem adicionados indiscriminadamente.

O VFX deve ser construído de maneira intencional. Cada camada precisa contribuir para a leitura da habilidade.

A eletricidade deve acompanhar o braço esquerdo sem se desprender visualmente da mão durante os movimentos.

Utilize attachments e coordenadas locais do rig sempre que apropriado. Evite posicionamentos globais fixos que façam o efeito flutuar no espaço.

Se o projeto possuir um sistema de auras, respeite sua organização. Caso o personagem esteja usando outra aura, investigue como permitir a coexistência dos efeitos sem sobrescrever indevidamente o visual existente.

Não determine uma cor definitiva antes de analisar as referências e a identidade visual do jogo.

---

# 9. SFX — PRODUÇÃO E SINCRONIZAÇÃO SONORA

A qualidade sonora faz parte da execução da habilidade.

Produza ou selecione efeitos sonoros específicos para os diferentes momentos do Shidori.

Considere:

- Som de preparação.
- Acúmulo de energia elétrica.
- Descargas e estalos elétricos.
- Camadas sonoras que transmitam potência.
- Som de movimento do braço, se apropriado.
- Impacto principal, caso exista um ataque.
- Dissipação e encerramento da energia.

Não utilize um único áudio genérico para representar toda a sequência.

Os sons devem acompanhar os eventos da animação. Utilize marcadores de animação ou mecanismos equivalentes para sincronizar os momentos importantes.

Caso exista dano por contato, o impacto sonoro deve corresponder ao evento real de acerto, em vez de tocar indiscriminadamente em todas as ativações.

Ajuste volume, duração, atenuação e sobreposição. Evite distorções excessivas, áudio repetitivo ou sons que tornem a habilidade desconfortável.

Utilize recursos de áudio autorizados e compatíveis com os requisitos de publicação do Roblox.

---

# 10. MECÂNICA, INPUTS E BALANCEAMENTO

Preserve rigorosamente os seguintes parâmetros:

| Parâmetro | Valor |
|---|---|
| Nome da habilidade | Shidori |
| Tecla no PC | Z |
| Controle mobile | Botão customizável integrado ao sistema existente |
| Estamina máxima inicial | 100 unidades |
| Custo por ativação | 50 unidades |
| Cooldown | 7 segundos |
| Multiplicador de dano | 1,6× o dano-base de um golpe M1 equivalente |
| Local da manifestação | Mão esquerda |
| Integração | Árvore de skills existente |

Não altere esses parâmetros arbitrariamente durante a produção visual.

O Shidori deve utilizar a infraestrutura de habilidades, inputs, estamina, cooldowns e interface já existente.

O botão mobile deve seguir o sistema de personalização de controles do jogo. Se esse sistema permitir mover ou reconfigurar botões, preserve essa funcionalidade. Se não existir, implemente a integração mínima necessária sem criar um sistema paralelo incompatível.

Não permita que o jogador ative a habilidade sem estamina suficiente ou durante o cooldown.

A lógica de ativação deve funcionar corretamente em PC e mobile.

---

# 11. ESCALONAMENTO DE DANO BASEADO EM POWER

O sistema de combate existente calcula o dano M1 a partir do atributo Power do jogador. O Shidori deve acompanhar essa mesma progressão.

**Não crie uma fórmula de dano independente.**

Antes de implementar, localize a função real de cálculo do M1 e identifique como Power, buffs, críticos, defesa e outros modificadores participam do resultado.

A regra conceitual é:

`DanoShidori = DanoBaseM1(Power) × 1.6`

Exemplo ilustrativo: se um jogador com 50.000 de Power causar 250 de dano em um golpe M1 equivalente, o Shidori deverá causar 400 de dano nas mesmas condições, antes dos modificadores posteriores previstos pela arquitetura do combate.

Esse exemplo não significa que o dano do M1 seja necessariamente 250 no código atual. Verifique a implementação real.

Se a fórmula `Power × 0,005` ainda for efetivamente utilizada pelo M1, o cálculo equivalente será `Power × 0,008`. Não utilize esses coeficientes sem confirmar que correspondem ao sistema atual.

O multiplicador de 1,6 deve ser aplicado uma única vez, evitando duplicação de bônus.

Respeite a ordem de cálculo adotada pelo sistema existente. Não aplique críticos, buffs ou modificadores defensivos novamente caso já tenham sido contabilizados.

O servidor deve calcular e validar o dano. O cliente não pode determinar arbitrariamente o resultado do combate.

---

# 12. ESTAMINA

Utilize o sistema de estamina já existente.

Requisitos:

- Capacidade máxima inicial de 100 unidades.
- Consumo de 50 unidades por ativação válida.
- Atualização da barra em tempo real.
- Recusa de ativação com menos de 50 unidades.
- Regeneração conforme as regras atuais do jogo.
- Integração com os componentes existentes de HUD e progressão.
- Prevenção de consumo duplicado.
- Sincronização correta entre cliente e servidor.

Se não houver regeneração implementada, desenvolva uma configuração apropriada e documente o valor escolhido, sem alterar desnecessariamente o balanceamento de outros recursos.

O servidor deve validar a disponibilidade de estamina e consumir o custo uma única vez por ativação confirmada.

Proteja a operação contra solicitações simultâneas que possam permitir gastar o mesmo saldo duas vezes.

---

# 13. ARQUITETURA TÉCNICA E MÁQUINA DE ESTADOS

Antes de criar novos scripts, analise a arquitetura do jogo e reutilize os componentes existentes.

Se não houver uma estrutura adequada, implemente uma separação clara entre configuração, entrada, lógica de servidor, animação, VFX, SFX e interface.

Centralize os parâmetros do Shidori em uma configuração apropriada, evitando valores duplicados em diversos arquivos.

Considere uma máquina de estados com os seguintes estados, adaptados ao comportamento real:

- `Ready`: habilidade disponível.
- `Activating`: ativação validada e início da animação.
- `Active`: efeito elétrico ativo.
- `Recovering`: encerramento e recuperação do personagem.
- `Cooldown`: habilidade indisponível até o término do intervalo.

Defina transições explícitas e impeça ativações em estados incompatíveis.

A duração das fases de preparação, atividade e recuperação deve ser configurável. Não presuma que o cooldown corresponde à duração visual do efeito.

O cooldown deve ser validado no servidor, com início e término definidos de maneira consistente com o sistema atual.

Trate corretamente morte, respawn, interrupções, estados de atordoamento e tentativas de ativação durante outras habilidades.

Não refatore sistemas não relacionados sem uma justificativa técnica clara.

---

# 14. REQUISITOS DE ANIMAÇÃO E ASSETS

Inspecione o rig real do personagem e confirme se o projeto utiliza R6, R15 ou outra estrutura compatível.

Verifique:

- Compatibilidade das animações.
- Orientação e posicionamento da mão esquerda.
- Prioridade das animações.
- Transições com idle, movimento e combate.
- Interrupção e recuperação.
- Sincronização dos eventos visuais e sonoros.
- Disponibilidade e permissões dos assets utilizados.

Armazene os recursos de acordo com a estrutura do projeto.

Não invente IDs de animação, áudio ou modelos publicados. Se for necessário publicar recursos, utilize o fluxo autorizado disponível e confirme sua acessibilidade antes de considerá-los prontos.

Caso não seja possível publicar ou importar algum recurso automaticamente, prepare o material necessário e documente exatamente o que exige intervenção manual.

Não substitua assets necessários por placeholders silenciosos sem informar a limitação.

---

# 15. SEGURANÇA E MULTIPLAYER

O servidor deve controlar a validação da ativação, o consumo de estamina, o cooldown e o dano.

O cliente deve cuidar da entrada do jogador e da apresentação visual e sonora, conforme a arquitetura de replicação existente.

Valide os argumentos recebidos pelos RemoteEvents ou RemoteFunctions. Implemente proteção contra spam, solicitações duplicadas e ativações inválidas.

Se o Shidori possuir uma janela de ataque, valide os alvos e as condições reais de acerto no servidor.

Evite que o cliente determine livremente o dano, escolha alvos fora do alcance ou ignore os estados da habilidade.

Garanta que os demais jogadores visualizem a habilidade corretamente, sem duplicação de animações ou efeitos.

Evite transmitir continuamente grandes quantidades de dados de partículas quando eventos compactos forem suficientes.

---

# 16. PERFORMANCE E LIMPEZA DOS EFEITOS

O Shidori deve apresentar qualidade visual elevada sem causar degradação desnecessária do desempenho.

Implemente gerenciamento adequado para:

- Partículas temporárias.
- Beams e Trails.
- Iluminação localizada.
- Sons.
- Conexões de eventos.
- Objetos auxiliares.
- Attachments e instâncias temporárias.

Utilize mecanismos de limpeza apropriados, como `Debris` ou gerenciamento explícito de ciclo de vida, conforme a arquitetura existente.

Não destrua componentes permanentes do personagem por engano. Diferencie recursos temporários de objetos reutilizáveis.

Garanta que os efeitos sejam encerrados após a execução, a interrupção, a morte ou o respawn.

Evite loops desnecessários, criação excessiva de instâncias e conexões que permaneçam ativas depois que a habilidade terminar.

Teste a habilidade em condições reais e observe o comportamento no PC e em dispositivos móveis.

---

# 17. INTEGRAÇÃO COM A ÁRVORE DE SKILLS E HUD

Adicione o Shidori à árvore de skills existente.

Mantenha o padrão visual e a estrutura de progressão já utilizados no jogo.

A habilidade deve apresentar:

- Nome e ícone.
- Descrição de seus efeitos.
- Custo de 50 de estamina.
- Cooldown de 7 segundos.
- Indicação do multiplicador de dano de 1,6×.
- Estados de desbloqueio e disponibilidade, conforme a arquitetura atual.

A barra de estamina deve utilizar o sistema de HUD existente, quando disponível, e refletir corretamente os valores confirmados pelo servidor.

Não reconstrua a árvore de skills nem substitua a HUD inteira para adicionar uma única habilidade.

---

# 18. FLUXO DE TRABALHO OBRIGATÓRIO

Trabalhe de forma iterativa, validando os resultados durante o desenvolvimento.

### Etapa A — Auditoria

Inspecione os scripts, módulos, sistemas de combate, Power, estamina, inputs, animações, VFX, SFX e árvore de skills.

### Etapa B — Pesquisa

Analise os três TikToks, pesquise referências complementares e registre os elementos visuais que orientarão a produção.

### Etapa C — Planejamento

Defina a sequência da habilidade, os eventos de animação, a estratégia de VFX e SFX, a máquina de estados e a integração técnica.

### Etapa D — Produção

Crie ou adapte as animações, os efeitos visuais, os sons e os recursos auxiliares necessários.

Utilize as ferramentas disponíveis em vez de se limitar a escrever scripts.

### Etapa E — Integração

Integre a habilidade aos sistemas reais de combate, Power, estamina, cooldown, inputs, HUD e árvore de skills.

### Etapa F — Testes

Execute a habilidade no Roblox Studio e, quando possível, teste em multiplayer e em dispositivos com características diferentes.

### Etapa G — Refinamento

Revise a animação, a posição da energia, a intensidade dos efeitos, a sincronização dos sons, a limpeza dos recursos e o desempenho.

Não finalize o trabalho apenas porque os scripts compilam.

---

# 19. TESTES OBRIGATÓRIOS

Valide os seguintes cenários:

1. Ativação pela tecla Z no PC.
2. Ativação pelo botão mobile.
3. Personalização do controle mobile, conforme o sistema disponível.
4. Consumo exato de 50 unidades de estamina.
5. Recusa de ativação com menos de 50 unidades.
6. Recusa de reativação durante o cooldown de 7 segundos.
7. Dano escalonado pela fórmula real de Power.
8. Ausência de multiplicadores de dano duplicados.
9. Posicionamento correto da energia na mão esquerda durante toda a animação.
10. Ausência de dependência de espada equipada.
11. Sincronização dos SFX com os eventos corretos.
12. Encerramento dos efeitos após conclusão, morte ou interrupção.
13. Replicação visual adequada para outros jogadores.
14. Proteção contra chamadas remotas duplicadas ou inválidas.
15. Compatibilidade com as habilidades e os sistemas existentes.
16. Desempenho aceitável em PC e dispositivos móveis.

Diferencie testes efetivamente executados de verificações pendentes. Não declare que uma funcionalidade foi validada apenas porque o código parece correto.

---

# 20. CRITÉRIOS DE QUALIDADE FINAL

Antes de concluir, avalie o resultado com rigor:

- A animação apresenta antecipação, fluidez, impacto e recuperação convincentes?
- O braço esquerdo é o protagonista da execução?
- A energia parece realmente concentrada na mão?
- O VFX aproveita adequadamente as técnicas e os recursos do sistema anterior da espada?
- A eletricidade acompanha a mão sem se desprender do personagem?
- Os efeitos apresentam profundidade e leitura visual?
- Os sons estão sincronizados?
- A habilidade funciona corretamente em PC e mobile?
- O dano acompanha o Power real do jogador?
- Estamina, cooldown e segurança estão corretos?
- Os efeitos são removidos adequadamente?
- O resultado foi testado no ambiente real do jogo?

Se algum aspecto importante estiver abaixo do padrão desejado, continue refinando antes de finalizar.

---

# 21. RELATÓRIO FINAL

Ao terminar, apresente um relatório objetivo contendo:

1. Quais vídeos foram efetivamente analisados.
2. Quais referências complementares foram utilizadas.
3. Quais ferramentas foram utilizadas e quais não estavam disponíveis.
4. Quais animações, meshes, VFX, SFX e outros assets foram criados ou adaptados.
5. Quais arquivos foram modificados e quais foram adicionados.
6. Como o Shidori foi integrado ao sistema real de Power e M1.
7. Como foram implementados os inputs, a estamina, o cooldown e a árvore de skills.
8. Quais testes foram executados e seus resultados.
9. Quais limitações permanecem e quais ações ainda dependem de intervenção manual.

Não declare que criou, importou, publicou, executou ou testou um recurso se isso não aconteceu efetivamente.

Se alguma ferramenta ou integração estiver indisponível, procure alternativas e prossiga com o máximo possível.

---

# OBJETIVO FINAL

Entregue um Shidori funcional, visualmente elaborado e tecnicamente integrado ao projeto Roblox.

A habilidade deve ser concentrada na mão esquerda, inspirada no Chidori de Naruto, com animação própria, eletricidade convincente, VFX detalhados, SFX sincronizados e utilização dos melhores recursos disponíveis no ambiente.

A espada serve exclusivamente como referência para o reaproveitamento das técnicas de VFX. Ela não faz parte da habilidade.

Você tem liberdade para escolher as ferramentas, experimentar técnicas, produzir recursos próprios e refinar o resultado quantas vezes forem necessárias.

**Não entregue apenas o mínimo necessário para a habilidade funcionar. Busque a melhor qualidade que o ambiente, os recursos e a arquitetura real do projeto permitirem, sem comprometer o desempenho, o balanceamento ou a integridade dos sistemas existentes.**