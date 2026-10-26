# RogueTales — Fichas dos personagens

Consolidação de design em 26/10/2026. Projeto: Godot 4.7, PC e Mobile.

Este documento reúne os 12 personagens, usando os JSONs enviados e as correções posteriores da conversa. As decisões posteriores prevalecem sobre os JSONs e sobre propostas anteriores. São especificações de design, não confirmação de implementação ou de balanceamento testado.

Regras compartilhadas estão em [RogueTales_Mecanicas.md](RogueTales_Mecanicas.md). Defesas são pontos, não porcentagens. Multiplicadores representam dano bruto, antes das defesas. Cada protagonista escolhe uma bênção por run; efeitos de bênçãos diferentes não são somados.

## Atributos base consolidados

Valores antes de passivas, bênçãos, itens e bônus temporários. DF/DM: Dano Físico/Mágico; DefF/DefM: defesas em pontos.

| Personagem | PV | DF | DM | DefF | DefM | Iniciativa | Ataques | Crítico | Multiplicador | Esquiva |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Scarlet | 200 | 24 | 0 | 0 | 0 | 50 | 1 | 10% | ×2 | 10% |
| Alice | 190 | 10 | 10 | 0 | 0 | 50 | 1 | 0% | ×2 | 0% |
| Snow | 300 | 20 | 0 | 10 | 5 | 50 | 1 | 0% | ×2 | 0% |
| Umi | 150 | 0 | 20 | 0 | 5 | 10 | 1 | 0% | ×2 | 0% |
| Silk | 350 | 0 | 15 | 5 | 15 | 50 | 1 | 0% | ×2 | 0% |
| Mulan | 200 | 30 | 0 | 0 | 0 | 50 | 1 | 20% | ×2 | 20% |
| Gretel | 180 | 0 | 25 | 0 | 0 | 10 | 1 | 0% | ×2 | 0% |
| João/Hensel | 190 | 20 | 0 | 0 | 0 | 50 | 1 | 25% | ×2 | 15% |
| Lume | 150 | 0 | 20 | 0 | 0 | 50 | 1 | 0% | ×2 | 10% |
| Aladin | 180 | 0 | 25 | 0 | 0 | 50 | 1 | 0% | ×2 | 0% |
| Peter Pan | 170 | 0 | 20 | 0 | 0 | 50 | 1 | 15% | ×3 | 25% |
| Gato de Botas | 330 | 30 | 0 | 10 | 10 | 50 | 1 | 10% | ×2 | 5% |

### Recursos

| Personagem | Custo | Mana por acerto elegível | Mana por vez própria |
|---|---:|---:|---:|
| Scarlet | 120 | 10 | 0 |
| Alice | 4 básicos; sem mana | 0 | 0 |
| Snow | 100 | 10 | 0 |
| Umi | 120 | 10 | 0 |
| Silk | 100 | 0 | 20 |
| Mulan | 100 | 10 | 0 |
| Gretel | 150 | 15 | 0 |
| João/Hensel | 80 | 10 | 0 |
| Lume | 200 | 10 | 0 |
| Aladin | Desejos limitados; sem mana | 0 | 0 |
| Peter Pan | 70 | 10 | 0 |
| Gato de Botas | 90 | 10 | 0 |

Os custos são anteriores às bênçãos. Mana por acerto não autoriza geração por ult, dano periódico ou golpe adicional explicitamente excluído na ficha.

## 1. Scarlet — Chapeuzinho Vermelho

**Atiradora Caster física; retaguarda.** Espalha pólvora e a consome em uma ult coletiva.

### Habilidades

- **Bombas Caseiras:** causa 100% do Dano Físico em um alvo. Pode critar. Não tem espalhamento natural na ficha final.
- **Espalhando Pólvora:** cada alvo acertado por um ataque recebe uma carga, até dez por alvo. Crítico não concede carga adicional naturalmente. A pólvora não explode automaticamente; desaparece no fim do combate.
- **Detonação em Massa:** custa 120 de mana, atinge todos os inimigos e consome as cargas de cada um. Dano físico por alvo = Dano Físico × (1,5 + 0,1 × cargas daquele alvo). Vai de 150% a 250%. Pode critar; não gera mana nem pólvora. Pode ocorrer durante a sequência sem consumir básicos restantes.
- Cada alvo acertado pelo básico ou seu espalhamento concede dez de mana. Sem regeneração passiva. A mana permanece entre combates.

Com Dano Físico 24: básico 24; ult 36 sem cargas, 48 com cinco e 60 com dez, antes de crítico e defesa.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Pavio Curto | Custo da ult reduzido em 30: de 120 para 90. | Padrão. |
| Explosivo Fragmentado | Básico também acerta os dois alvos mais próximos do alvo principal, com 50% do dano. Cada alvo recebe uma carga e concede dez de mana. | Atingir nove inimigos com um básico, conforme JSON. |
| Inimiga de Bestas | +50% de dano contra categoria Besta. | Vencer o Lobo Mau secreto. |
| Chapeuzinho Vermelho | Ult começa em 300%, chegando a 400% com dez cargas. Básicos aplicam duas cargas por alvo, mantendo dez de mana por acerto. | Concluir a run com Scarlet como protagonista. |

O desbloqueio de nove alvos exige uma fonte de espalhamento além desta bênção; revisar sua viabilidade ao criar os itens.

## 2. Alice

**Atiradora Híbrida de economia; retaguarda.** A posição Vanguarda e os campos de dano puramente físico no JSON são limitações/erros de preenchimento, corrigidos pela conversa.

### Habilidades

- **4 Naipes:** básico causa 100% do Dano Físico + 100% do Dano Mágico em um alvo e avança um naipe.
- **Baralho Mágico:** não usa mana. Cada básico executado concede uma carga em um contador único. A cada quatro cargas, consome quatro e ativa a ult, continuando os ataques restantes. Espalhamento não concede cargas extras. Contador e próximo naipe permanecem entre combates.
- **Ouros:** concede cinco de ouro por acerto. A função econômica é intencional.
- **Copas:** cura a própria Alice em 10% do dano causado.
- **Paus:** concede à própria Alice escudo de 5% da vida máxima.
- **Espadas:** acrescenta 50% do atributo ofensivo mais alto como dano daquele tipo. No empate, apenas um dos dois tipos recebe o bônus; o critério de desempate não foi especificado.
- **Cortejo das Cartas:** causa 120% do Dano Físico + 120% do Dano Mágico por inimigo atravessado na linha horizontal do alvo. Não alimenta seu próprio contador. Básico e ult podem critar se Alice adquirir chance crítica.

Com atributos 10/10: básico 20 híbridos; ult 24 híbridos por alvo. Sem bênção de ataque adicional, oito básicos geram duas ults.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Full House | Cada ult concede um básico adicional, que avança o naipe e o contador. | Padrão. |
| Chapeleira Maluca | Uma condição negativa é sorteada por ult e compartilhada entre os inimigos atingidos. Dura um turno, usa a potência padrão da condição e respeita chance de aplicação e imunidades individuais. | Alice causar dois ou mais efeitos negativos na mesma rodada. |
| Escapada Mágica | Uma vez por estágio, antes de um ataque fatal, troca com qualquer aliado vivo da retaguarda, que recebe o ataque. Alice ganha 100% de esquiva até sua próxima vez. Sem aliado elegível, não ativa. | Vencer a Rainha de Copas secreta. |
| País das Maravilhas | Dobra os efeitos especiais dos naipes. Cada ataque tem 10% de chance de lançar um Coringa, limitado a um por turno. O Coringa causa o dano do ataque e repete o efeito do naipe anterior; não avança naipe nem carrega a ult. | Concluir run como protagonista. |

Com Full House, oito básicos disponíveis podem resultar em dez básicos, duas ults e duas cargas restantes. Somente essa bênção está ativa nesse exemplo.

## 3. Snow — Branca de Neve

**Soldado Tank Físico; vanguarda.** Mineradora criada entre anões, especializada em romper escudos.

### Habilidades

- **Minerando:** básico de 100% do Dano Físico em um alvo.
- **Quebrando Barreiras:** básicos causam +100% de dano contra escudos. O dano adicional exclusivo contra escudo não se transforma em dano à vida ao quebrá-lo. A ult também recebe esse benefício, apesar da descrição original usar o nome antigo Rompe-Barreiras.
- **Partidora de Rochas:** 300% do Dano Físico em um alvo. Custo 100; dez de mana por acerto; zero por turno.

Com Dano Físico 20: básico 20 e ult 60 brutos, sem o bônus contra escudo.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Um Pouco pra Mim! | Ao destruir um escudo, recebe 50% do valor que ele tinha imediatamente antes do golpe que o destruiu como escudo próprio. | Padrão. |
| Duro e Afiado | Cada dois pontos de Defesa Física concedem +1% de Dano Físico. | Atingir 100 pontos de Defesa Física em uma run. |
| Constituição de Mineradora | Imune a efeitos negativos que causem dano, como veneno e queimadura. Não é imunidade geral a controles sem dano. | Vencer a Rainha Má secreta. |
| A Branca de Neve | 50% de chance de interceptar ataque de alvo único contra aliado da retaguarda ou Assassino. Não esquiva do golpe interceptado e recebe 20% menos dano, além das defesas normais. Após duas falhas consecutivas, a próxima tentativa é garantida. Sucesso zera falhas. Uma interceptação entre suas vezes, recuperada no início da própria vez. Não funciona em área. | Concluir run como protagonista. |

## 4. Umi — A Princesa Sereia

**Maga Curandeira; retaguarda.** Água ricocheteia para curar e preparar controle coletivo. Nome final Umi, substituindo Ariel nas descrições.

### Habilidades

- **Correntes Dançantes:** 100% do Dano Mágico no alvo inicial. Cada salto testa individualmente 50% de chance de continuar, até dois saltos naturais, de 60% e 40%. Falhar encerra a corrente. Não repete alvos naquele básico.
- **Águas Curativas:** cada inimigo acertado pelo básico, inclusive por ricochete, cura o aliado vivo com menor porcentagem de vida em 15% do Dano Mágico. Reavalia o beneficiário após cada impacto. Cada acerto também gera dez de mana.
- **Impacto de Onda:** custa 120, causa 150% do Dano Mágico em todos os inimigos e tem 50% de chance individual de aplicar Bolha. Bolha remove um ataque da próxima vez do alvo, podendo chegar a zero, não acumula e respeita imunidades. A ult não gera mana nem ativa Águas Curativas.

Com Dano Mágico 20: impactos 20, 12 e 8; cura três por inimigo acertado; ult 30 por alvo. Defesa Mágica inicial cinco pontos é uma exceção intencional.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Espuma Acolhedora | 100% da cura excedente vira escudo, até 15% da vida máxima do beneficiário em escudo desta bênção. Pode escolher aliado saudável se todos estiverem com vida cheia. | Padrão. |
| Ondas Infinitas | Dois ricochetes adicionais, de 40% do Dano Mágico cada. Também testam os 50%, não repetem alvos e ativam cura/mana por acerto. | Atingir cinco inimigos no mesmo turno. |
| Voz das Profundezas | Se a rolagem de aplicação de Bolha falhar, aplica Ressaca: −20 de Iniciativa na próxima vez do alvo. Respeita imunidade a controle. | Vencer a Bruxa do Mar secreta. |
| A Princesa Sereia | Aplicar Bolha concede um básico extra à próxima vez de Umi, até três guardados. Não aumenta permanentemente o atributo e não acrescenta ataques à sequência atual. | Concluir run como protagonista. |

## 5. Silk — Rapunzel

**Tank Suporte; vanguarda.** Protege o grupo, reduz dano enquanto seus escudos existem e retalia contra agressores.

### Habilidades

- **Casulo de Seda:** concede a si e ao outro aliado vivo com menor porcentagem de vida escudo de 100% do Dano Mágico. Enquanto Silk tiver escudo criado por ela, ataques inimigos que a acertam provocam retaliação de 50% do Dano Mágico. Inclui o golpe que quebra o escudo. Não é uma ação ofensiva direta.
- **Passiva sem nome final:** aliados com escudos criados por Silk recebem 10% menos dano. Beneficia a própria Silk, não acumula e vale também no golpe que quebra a proteção.
- **Ult sem nome final:** concede a todos os aliados vivos, incluindo Silk, escudo de 200% do Dano Mágico e bônus de Defesa Mágica equivalente a 30% dos pontos de Defesa Mágica de Silk. O bônus dura enquanto o escudo da ult daquele beneficiário durar.
- Escudos próprios acumulam até 30% da vida máxima de cada beneficiário. Duração normal cinco turnos do beneficiário, por aplicação. Escudos permanecem entre combates; isso não renova sua duração.
- Custo da ult 100; ganha 20 de mana no início da própria vez e zero por acerto.

Com Dano Mágico 15 e Defesa Mágica 15: escudo básico 15, retaliação 7,5, escudo da ult 30 e +4,5 pontos de Defesa Mágica. Nomes sugeridos, ainda não confirmados: Fios Entrelaçados para a passiva e Torre de Cabelos para a ult.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Trança Dupla | Básico protege mais um aliado, além de Silk e do primeiro beneficiário. | Padrão na proposta; falta registrar explicitamente na ficha. |
| Fios Resistentes | Quebra de escudo criado por Silk por dano inimigo concede dez de mana a ela. Cada aliado pode ativar uma vez entre duas vezes de Silk. | Manter 200 pontos de escudo simultâneos em um único personagem. |
| Esperando Para Sempre | Seus escudos não expiram após cinco turnos; permanecem até quebrar, inclusive entre combates. | Vencer a Falsa Mãe secreta. |
| Rapunzel | Ult limpa todos os efeitos negativos do grupo e concede escudo de 300% do Dano Mágico, preservando o bônus defensivo da ult. | Concluir run como protagonista. |

Com o limite de 30%, o desbloqueio de Fios Resistentes requer pelo menos 667 PV máximos no beneficiário, caso sejam considerados apenas os escudos sujeitos a esse limite.

## 6. Mulan

**Assassina Física; meio.** Combos, críticos e contra-ataques.

### Habilidades

- **Três Ataques:** 100% do Dano Físico em um alvo; cada terceiro básico executado causa 150%. Contador permanece entre turnos e combates. Contra-ataques e ults não avançam o contador.
- **Contra-Ataque:** ao esquivar de ataque direto, responde com 60% do Dano Físico. Pode critar; não gera mana. Uma ativação entre suas próprias vezes, renovada no início da vez dela.
- **Dragão de Jade:** 250% do Dano Físico em toda a coluna escolhida. Pode alcançar as três colunas como Assassina; prioridade detalhada será criada depois. Para execução visual, prioriza o alvo central da coluna, sem precisar expor isso na descrição ao jogador.
- Custo 100; dez de mana por acerto de básico e zero por turno.

Com Dano Físico 30: básico 30, aprimorado 45, contra-ataque 18 e ult 75 por alvo.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Dois Ataques | Básico aprimorado a cada dois básicos. | Padrão. |
| Fogos de Artifício | Ult acerta também a coluna imediatamente atrás da original, com os mesmos 250%. Vanguarda + meio, ou meio + retaguarda; não propaga para uma terceira coluna. | A própria Mulan eliminar duas colunas completas, com três inimigos cada, no mesmo turno. |
| Sem Correntes | Até três contra-ataques entre suas vezes. | Vencer o General do Leste secreto. |
| A Guerreira do Leste | Cada crítico de básico acrescenta cinco pontos percentuais ao dano dos próximos básicos, até +20. Expira no início da próxima vez, sem renovar duração. Soma com o aprimorado: comum até 120%, aprimorado até 170%. O golpe que gera a carga usa o bônus anterior. | Concluir run como protagonista. |

## 7. Maria — Gretel

**Assassina Mágica; meio.** Veneno de dano real e maldição coletiva. Não usar a antiga proposta de estocadas e consumo de veneno.

### Habilidades

- **Veneno Líquido:** 100% do Dano Mágico em um alvo, podendo critar se adquirir chance. Aplica uma dose de veneno.
- **Acumulando Toxinas:** até três doses por alvo. Cada dose causa 10% do Dano Mágico como dano real no início da vez do alvo, durante dois turnos. Reaplicar renova a duração. Veneno não critica nem gera mana pelo dano periódico.
- **Maldição de Bruxa:** sem dano direto; tenta aplicar Maldição em todos os inimigos, com 75% de chance individual. Reduz Dano Físico, Dano Mágico e pontos das duas defesas em 20%, durante dois turnos de cada alvo. No início da própria vez, cada alvo tem 25% de chance de escapar antecipadamente.
- Custo 150; quinze de mana por acerto de básico e zero por turno.

Com Dano Mágico 25: básico 25 e veneno 2,5 por dose por turno, até 7,5 com três doses.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Acumulando Ainda Mais Toxinas! | Limite de veneno passa a cinco doses. | Padrão. |
| Assassinos de Bruxas | +50% de dano contra Bruxa ou Feiticeiro. Matar inimigo de qualquer categoria concede cinco de mana, inclusive morte por seu veneno. | Vencer chefe Bruxa com João na equipe. |
| Uma Maldição Mais Forte | Acrescenta Corta-Cura e Quebra-Escudos pela duração da Maldição. | Vencer a Bruxa dos Doces secreta. |
| A Nova Bruxa | Quando a própria Maria mata um inimigo envenenado, inclusive pelo veneno, transfere suas doses ao próximo alvo válido segundo sua prioridade, até três doses. Sem dano imediato; sem outro inimigo, as doses desaparecem. | Concluir run como protagonista. |

As bênçãos são alternativas: o limite cinco da primeira não se soma à quarta.

## 8. João — Hensel

**Assassino Físico; meio.** Marca uma presa e executa uma sequência de estocadas com a bengala de doce.

### Habilidades

- **Perfuração de Açúcar:** 100% do Dano Físico em um alvo, podendo critar.
- **Marca do Duelista:** primeiro básico acertado marca o inimigo. Básicos seguintes contra essa presa causam 120%. Marca permanece até a presa morrer ou João trocar de alvo. Apenas básicos aplicam.
- **Seis Saudações:** seis estocadas de 50% do Dano Físico, ou 70% por estocada contra presa marcada. Cada impacto pode critar ou ser esquivado individualmente. Não gera mana por acerto. Se o alvo morrer, os golpes restantes terminam, sem transferência.
- Custo 80; dez de mana por acerto de básico e zero por turno.

Com Dano Físico 20: básico 20/24; ult total 60/84 sem críticos. Com três estocadas extras e alvo marcado, até 126 antes de críticos e defesa.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Doce Ponto Fraco | Ignora 50% dos pontos de Defesa Física do alvo. | Padrão. |
| Assassinos de Bruxas | +50% de dano contra Bruxa ou Feiticeiro. Eliminar qualquer inimigo concede cinco de mana, inclusive por ult ou Sangramento. | Vencer chefe Bruxa com Maria na equipe. |
| Marcado para Morrer | Acertar seis estocadas no mesmo inimigo na mesma ult aplica Sangramento: 10% do Dano Físico como dano real no início da vez dele e Corta-Cura de 50%. Não acumula, critica ou gera mana pelo dano. Dura até a morte, mas pode ser limpo. | Vencer a Bruxa dos Doces secreta. |
| O Caçador da Casa dos Doces | Cada crítico da ult acrescenta uma estocada à execução, até três extras. Extras podem critar, mas não geram outras extras. | Concluir run como protagonista. |

## 9. Lume — Vendedora de Fósforos

**Maga de Dano Contínuo; retaguarda.** Aumenta a potência de uma queimadura, em vez de acumular doses separadas.

### Habilidades

- **Lançar Faíscas:** 50% do Dano Mágico em um alvo, aplicando Queimadura de 100% do Dano Mágico como dano real de fogo no início da vez do inimigo, por dois turnos.
- **Incêndio Amador:** impacto direto de básico ou ult contra alvo já incendiado acrescenta dez pontos percentuais do Dano Mágico à potência do fogo, até 150%, e renova a duração. Dano periódico e explosões não fortalecem a queimadura.
- **Fogo de Dragão:** 250% do Dano Mágico em todos os inimigos e aplica a mesma queimadura inicial nos não incendiados; fortalece os já incendiados pela passiva. A ult não gera mana.
- Queimadura não critica nem gera mana pelo dano. Imunidade a fogo impede sua aplicação.
- Custo 200; dez de mana por acerto de básico e zero por turno.

Com Dano Mágico 20: básico dez; ult 50 por alvo; fogo inicial 20 por turno, até 30 normalmente ou 40 com a bênção de potência maior.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Mais de uma Faísca | +1 ataque, direcionado a outro inimigo. Sem outro alvo, repete o primeiro. Causa 50% do Dano Mágico e aplica/fortalece fogo, gerando mana normalmente. | Padrão. |
| Queime até Virar Cinzas | Seu fogo não expira nem pode ser limpo depois de aplicado. Imunidade ainda impede aplicar. Limite da potência passa a 200% do Dano Mágico. | Vencer combate com ao menos três inimigos, todos mortos pela queimadura no início das próprias vezes. |
| A Chama da Vida | No início da vez de Lume, havendo inimigo queimando, cura 50% da potência por turno da queimadura mais forte entre eles. Sujeita a Corta-Cura. | Vencer o Elemental do Frio secreto. |
| A Vendedora de Fósforos | Morte de inimigo incendiado provoca explosão de 50% do Dano Mágico contra os demais. Mortos pela explosão só continuam a cadeia se já estavam incendiados. Cada inimigo explode uma vez. Explosão mágica, sem crítico, sem aplicar fogo. Apenas mortes pelas explosões concedem dez de mana por abate. | Concluir run como protagonista. |

## 10. Aladin

**Mago de Recursos; retaguarda.** Sem ult convencional ou mana; três desejos manuais limitados pela run.

### Habilidades

- **Energia Genial:** rajada de 100% do Dano Mágico em um alvo. Pode critar ao adquirir chance.
- **Poder Engarrafado:** +10% de Dano Mágico por desejo disponível: +30%, +20%, +10%, zero. Conta desejos restantes, não desejos já gastos.
- **3 Desejos — especial:** manual, sem mana, pode ser usado mesmo morto e fora de combate, inclusive no mercador. Um uso de cada opção por run, salvo a bênção de quarto desejo.
  - **Riqueza:** provisoriamente concede 200 de ouro × estágio atual, começando em um. Revisar quando itens e mercadores forem definidos.
  - **Vida:** revive todos os aliados mortos com 100% da vida máxima.
  - **Morte:** elimina inimigos normais e chefes secundários. Chefes de estágio e secretos recebem 1000% do Dano Mágico como dano mágico, sujeito à defesa. Não critica. Calcula o atributo antes de consumir o desejo e reduzir a passiva.

Com Dano Mágico base 25: atributo 32,5/30/27,5/25 conforme desejos restantes. Desejo de Morte usado primeiro causa 325 brutos sem bênção de passiva ampliada.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Lâmpada Preciosa | Passiva concede +20% de Dano Mágico por desejo restante, começando em +60%. | Padrão. |
| Proteção ao Portador da Lâmpada | Imune a todos os efeitos negativos enquanto restar algum desejo. | Concluir run com Aladin na equipe sem gastar todos os desejos. |
| Essa É Por Conta da Casa | Quarta carga livre para repetir uma das três opções, além do uso de cada desejo original. Conta na passiva: +40%, +30%, +20%, +10%, zero. | Vencer O Rei do Deserto secreto. |
| Gênio Liberto | Após gastar os três desejos, +2 ataques por turno e rajadas passam a dano real, escalando com Dano Mágico. | Concluir run como protagonista. |

Com Gênio Liberto, sem outros bônus: três básicos de 25 reais. Não combinar com o quarto desejo, pois são bênçãos alternativas.

## 11. Peter Pan

**Assassino Mágico; meio.** Esquivas criam sombras ofensivas; ser acertado destrói suas sombras sem reduzir o dano recebido.

### Habilidades

- **Básico — Lâmina Sem Sombra (nome proposto):** 100% do Dano Mágico no alvo. Cada sombra acompanha com um golpe separado de 15% do Dano Mágico. Atacar não consome sombras. Cada golpe calcula seu próprio crítico ×3. Golpes das sombras não geram mana ou novas cópias de ataques.
- **Passiva de sombras:** cada esquiva de ataque direto concede uma sombra, até três. Cada impacto direto acertado remove uma sombra, se houver; Peter recebe o dano normalmente. Sombras não bloqueiam, não concedem redução e não são escudos. Dano periódico não gera ou remove sombras.
- **Ult em si mesmo — A Hora das Sombras (nome proposto):** completa suas sombras até três e acrescenta quinze pontos percentuais ao coeficiente mágico de seus golpes, até o início da próxima vez. Sombras comuns passam de 15% a 30%. Custo 70; dez de mana por acerto do básico, zero por turno.
- Esquiva inicial 25%, teto comum 80%; chance crítica 15%, multiplicador ×3. Não criar ataques de acerto garantido para contornar a esquiva.
- Sombras permanecem entre combates.

Com Dano Mágico 20: básico 20, cada sombra três (nove no crítico). Três sombras acrescentam nove sem críticos; sob ult, cada uma causa seis.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| O Menino e Sua Sombra | Começa cada combate com uma sombra. | Padrão. |
| Terra do Nunca | Perder sombra por acerto inimigo também remove um efeito negativo, após o impacto. | Perder três sombras por dano inimigo no mesmo combate e sobreviver. |
| Devolva Minha Sombra | Ao atacar inimigo que removeu uma sombra dele naquela rodada, 50% de chance de recuperar uma sombra, até o limite três. | Vencer o Capitão Gancho secreto. |
| Peter Pan | Cada sombra causa 25% do Dano Mágico como dano mágico + 15% como dano real. Sob ult: 40% mágico + 15% real. | Concluir run como protagonista. |

Sem ult, três sombras com a última bênção acrescentam 120% no total: 75% mágico + 45% real, não 90%. Ainda falta decidir se começar com uma sombra estabelece um mínimo ou concede uma adicional às preservadas; e se golpes das sombras podem ativar Devolva Minha Sombra ou apenas o básico de Peter.

## 12. Gato de Botas

**Soldado Físico; vanguarda.** Vida alta, espada gigante e dano baseado na porcentagem de vida perdida.

### Habilidades

- **Passiva — Fúria do Pequeno Gigante (nome proposto):** +1% de Dano Físico por 1% de vida máxima faltando. Recalcula com a vida atual; curar reduz o bônus. Não usa quantidade absoluta de PV perdidos.
- **Básico — Corte Brutal (nome proposto):** 100% do Dano Físico em um alvo; pode critar.
- **Ult — Matador de Gigantes (nome proposto):** 250% do Dano Físico em toda a coluna escolhida, usando o atributo aumentado pela passiva. Pode critar. Custo 90; dez de mana por acerto do básico e zero por turno; ult não gera mana.

Com Dano Físico base 30: 30 a vida cheia, 45 a 50% da vida e 52,5 a 25%. Nessa última situação, ult 131,25 por alvo antes de crítico e defesas.

### Bênçãos

| Bênção | Efeito | Desbloqueio |
|---|---|---|
| Lâmina Desesperada | Com 25% de vida ou menos, básicos acertam um segundo inimigo com 50% do dano do golpe principal. Sem segundo alvo, o golpe adicional atinge o primeiro. | Padrão. |
| Ainda Tenho Garras | Uma vez por estágio inteiro, dano fatal o deixa com um PV; sua vida não cai abaixo disso até o início da próxima vez. Não é imunidade a controle. Uso compartilhado entre as seis fases do estágio. | Chegar a 5% da vida máxima ou menos e vencer o combate com o Gato vivo. |
| Pequeno, Mas Não Menor | +25% de dano contra todos os chefes, incluindo secundários, de estágio e secretos. | Vencer o Lobo Caçador de Recompensas. |
| O Gato de Botas | Até nove retornos na run, com 20% da vida máxima. Chances sucessivas: 100%, 90%, 80%, 70%, 60%, 50%, 40%, 30%, 20%. Falha resulta em morte normal. Reviver preserva mana e limpa condições negativas. Ressurreição externa não reinicia as chances. | Concluir run como protagonista. |

## Pendências de acabamento, não novas mudanças de design

- Alguns nomes de habilidades de Silk, Peter e Gato ainda são sugestões, identificadas acima.
- Resolver as ambiguidades explicitamente anotadas, sem preencher silenciosamente com mecânicas novas.
- Durações de condições, ordem de resolução e fontes de dano devem seguir o documento de mecânicas.
- Os campos `armor`, `basicDefined`, `ultDefined`, tipo de ult ou alvos incorretos dos exportadores não substituem as descrições finais.
- Nenhuma ficha deste documento representa validação prática de equilíbrio. Riqueza do Aladin é provisória até a criação dos itens.
