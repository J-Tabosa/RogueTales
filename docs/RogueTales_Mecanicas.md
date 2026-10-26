# RogueTales — Mudanças nas mecânicas

Consolidação de design em 26/10/2026. Complemento de [RogueTales_Personagens.md](RogueTales_Personagens.md).

Decisões finais da conversa prevalecem sobre propostas anteriores e campos desatualizados dos JSONs. Este documento especifica o comportamento desejado; não afirma que o código já foi atualizado.

## 1. Vocabulário e substituições

| Antes | Agora |
|---|---|
| Armadura única | Defesa Física e Defesa Mágica, em pontos. |
| Poder único | Dano Físico e Dano Mágico, atributos independentes. |
| Velocidade/intervalo de ataque | Iniciativa e Quantidade de Ataques. |
| Mana regenerada por tempo | Mana por acerto ou por turno próprio, conforme a ficha. |
| Ult como ação obrigatoriamente separada | Pode acontecer durante a sequência de básicos, sem consumir ataques restantes. |

AP é usado informalmente como Dano Mágico. Dano real é um tipo de dano, não um terceiro atributo ofensivo obrigatório.

## 2. Rodada, vez, fase e estágio

- **Rodada:** ciclo em que cada personagem vivo tem sua vez, respeitando a ordem de iniciativa e os controles aplicáveis.
- **Vez/turno próprio:** oportunidade daquele personagem de executar sua sequência. Limites que se renovam na própria vez não se renovam em cada ação inimiga.
- **Fase:** encontro identificado como 1-1, 1-2 etc.
- **Estágio/mundo:** conjunto de seis fases. Uma habilidade de uso único por estágio, usada em 1-2, não volta de 1-3 a 1-6; volta em 2-1.
- **Run:** expedição completa. Contadores de desejos e ressurreições do Gato duram a run inteira.

## 3. Iniciativa e Quantidade de Ataques

### Iniciativa

- Escala de zero a 100. Padrão 50.
- 100 age primeiro; zero, por último.
- Não concede ataques nem turnos adicionais por si só.
- Ressaca reduz em vinte pontos, respeitando zero.
- Para a Ressaca de Umi: reordenar personagens ainda não atuantes; se o alvo já agiu, a penalidade vale para sua próxima vez, sem conceder ou apagar ações já resolvidas.
- Desempate entre iniciativas iguais ainda precisa de regra geral explícita.

### Quantidade de Ataques

- Atributo inicial um, mínimo natural um. Itens, passivas e bênçãos podem aumentá-lo.
- Bolha pode reduzir a quantidade efetiva da próxima vez a zero; é exceção ao mínimo do atributo.
- Ataques são executados sequencialmente na mesma vez, com reavaliação de alvos conforme a habilidade.
- **Ataque adicional** é nova execução do básico. **Espalhamento/ricochete** é impacto em outros alvos dentro da mesma execução.
- Em Silk, repetir a ação básica significa repetir a proteção, não inventar um ataque ofensivo.
- Retaliações e golpes de sombras não são automaticamente básicos: sua geração de mana, cargas e efeitos é especificada pelo personagem.

## 4. Dano e defesas por pontos

### Tipos

| Tipo | Defesa usada |
|---|---|
| Físico | Defesa Física. |
| Mágico | Defesa Mágica. |
| Híbrido | Cada parcela enfrenta sua defesa correspondente. |
| Real/neutro | Ignora Defesa Física e Mágica. |

Fogo, veneno e sangramento identificam condições/afinidades; não criam automaticamente defesas novas. Um efeito pode escalar com Dano Mágico ou Físico e causar dano real.

### Fórmula adotada

```text
Dano após defesa = Dano bruto × 100 / (100 + Defesa correspondente)
Redução equivalente = Defesa / (100 + Defesa)
```

| Pontos de defesa | Redução equivalente |
|---:|---:|
| 0 | 0% |
| 10 | 9,09% |
| 15 | 13,04% |
| 25 | 20% |
| 50 | 33,33% |
| 100 | 50% |
| 200 | 66,67% |
| 400 | 80% |

Defesa nunca alcança 100% de redução com um valor finito. O piso proposto e aceito junto à fórmula é um de dano para golpes positivos válidos, após reduções e antes dos escudos. Imunidade, esquiva e escudo podem impedir perda de vida. Não transformar ação sem dano, como maldição ou proteção, em golpe de um.

No híbrido, calcular as parcelas separadamente e somar antes do arredondamento; não duplicar o piso mínimo só por existir uma segunda parcela. A política geral exata de arredondamento e o comportamento de defesas negativas ainda precisam ser fixados.

### Aplicação retroativa

- Valores numéricos antigos são preservados, mas passam a representar pontos. Exemplo: defesa dez deixa de significar 10% de redução e passa a cerca de 9,09%.
- Padrão das defesas iniciais: zero fora da vanguarda, salvo exceção explícita da ficha, como Umi com cinco de Defesa Mágica.
- **Duro e Afiado:** cada dois pontos de Defesa Física concedem +1% de Dano Físico. Desbloqueio em cem pontos, não cinquenta.
- Ult de Silk compartilha 30% dos pontos de sua Defesa Mágica. Com quinze, concede +4,5 pontos; não +30 pontos ou +30 pontos percentuais de redução.
- João ignora 50% dos pontos de Defesa Física com Doce Ponto Fraco. Contra cem, usa cinquenta no cálculo.
- Maldição reduz os pontos de defesa em 20%, não subtrai vinte pontos nem vinte pontos percentuais de redução.

Reduções específicas, como os 20% da interceptação da Snow, são aplicadas além das defesas. A interação de reduções gerais com dano real ainda precisa de convenção global; ignorar defesas não significa ignorar todo efeito do jogo.

## 5. Crítico e esquiva

- Chance crítica e multiplicador são atributos diferentes. Padrão dos multiplicadores das fichas é ×2; Peter usa ×3.
- Uma ficha com zero de chance pode adquirir crítico por itens se a habilidade permitir.
- Híbrido mantém suas parcelas físicas/mágicas; definir uma política uniforme de rolagem para ataques híbridos na implementação.
- Multigolpes de João e golpes de sombras de Peter fazem verificações individuais conforme suas fichas.
- Dano periódico de veneno, queimadura e sangramento não critica nem gera mana pelo dano.
- Chance comum de esquiva limitada a 80%, incluindo atributos, itens e bônus comuns.
- Exceções temporárias explícitas podem atingir 100%, como Escapada Mágica de Alice.
- Não criar ataques de acerto garantido para neutralizar a construção de Peter.
- Dano real não significa acerto garantido: ataque direto real ainda pode permitir esquiva. Dano periódico não é esquivado.
- Chance de aplicar condição, chance de escapar de condição e chance de esquivar do ataque são verificações diferentes; não adicionar rolagens extras sem a ficha pedir.

## 6. Mana, contadores e ults

- Não há regeneração por tempo real.
- Mana por turno é concedida uma vez no início da própria vez, quando a ficha possuir esse ganho.
- Mana por acerto conta por alvo/impacto elegível, inclusive espalhamento, conforme a ficha. Exemplo: dez por acerto × três alvos = trinta de mana por básico; três básicos iguais = noventa.
- Acertos adicionais explicitamente excluídos não geram mana: sombras, contra-ataque de Mulan e estocadas da ult de João, por exemplo.
- Dano periódico não gera mana por impacto; uma bênção de mana por eliminação ainda pode ativar quando esse dano mata.
- Mana é preservada entre combates durante a run. Ao conjurar, descontar o custo e preservar excedente, sem truncar o recurso de modo a perder impactos da sequência.
- Não reintroduzir ganho natural por dano recebido do sistema antigo sem decisão explícita.
- Quando carrega o recurso durante sua sequência, o personagem pode ultar e continuar os básicos restantes. Pode repetir isso várias vezes na mesma vez.
- Alice usa quatro cargas por ult, sem mana. Oito básicos geram duas ults; contador restante permanece entre turnos e combates. Full House pode acrescentar básicos que também alimentam o contador.
- Aladin não tem ult convencional: desejos manuais, sem mana, com usos limitados pela run, inclusive fora de combate e mesmo morto.
- Política geral de automação/manual para ults comuns não foi redesenhada integralmente nesta conversa; preservar a escolha do jogador. Desejos do Aladin nunca entram em auto-ult.

## 7. Escudos

- Escudos absorvem dano antes de atingir os PV, inclusive dano real, salvo exceção explícita futura.
- Duração máxima normal cinco turnos do beneficiário. Aplicações de Silk têm duração separada.
- Permanência entre combates não renova duração: Silk preserva seus escudos e os turnos restantes.
- **Esperando Para Sempre** é exceção explícita: escudos de Silk não expiram, mas quebram por dano.
- Limite dos escudos criados por Silk: 30% da vida máxima do beneficiário. Limite de Espuma Acolhedora: 15% em escudo daquela bênção.
- Não impor esses limites a todas as outras fontes: regra geral de acúmulo e prioridade de consumo entre fontes distintas ainda precisa de especificação.
- Benefício defensivo da ult de Silk existe enquanto a parcela de escudo daquela ult existir, não enquanto qualquer escudo estiver presente.
- Retaliação de Silk exige escudo criado por ela e vale no golpe que o quebra.
- Snow causa dano extra a escudos, sem converter o bônus exclusivo em dano à vida.

## 8. Efeitos negativos

| Efeito | Regra consolidada |
|---|---|
| Sono | Chance de perder a vez. A chance padrão e duração globais ainda não foram fechadas. |
| Bolha | Na Umi, 50% de chance de aplicação por alvo; quando aplica, remove um ataque da próxima vez, podendo chegar a zero. Não acumula; respeita imunidades. Não adicionar automaticamente outra rolagem de ativação. |
| Corta-Cura | Reduz cura em 50%. |
| Quebra-Escudos | Reduz valor de novos escudos recebidos em 50%, conforme interpretação usada nas fichas; falta confirmar regra global para escudos já existentes. |
| Ressaca | −20 de Iniciativa. Na Umi vale para a próxima vez, sem acumular. |
| Queimadura | Dano periódico de fogo. Lume causa dano real escalando com Dano Mágico, no início da vez do alvo; dura dois turnos e reaplicação renova, salvo fogo permanente. |
| Veneno | Gretel: dano real de 10% do Dano Mágico por dose, no início da vez do alvo, dois turnos, reaplicação renova. Limite três ou cinco com sua bênção. |
| Maldição | Gretel: −20% nos dois danos e nos pontos das duas defesas, por dois turnos do alvo. Aplicação 75% por inimigo; escape antecipado 25% no início de sua vez. |
| Sangramento | João: 10% do Dano Físico como dano real no início da vez do alvo e Corta-Cura 50%. Não acumula; dura até morrer ou ser limpo. |

### Regras específicas e imunidades

- Chapeleira Maluca sorteia uma condição por ult para os alvos atingidos, com duração um turno, usando a potência padrão daquela condição e respeitando as verificações individuais e imunidades. Fogo usa a referência da Lume. A regra padrão global de Sono e a fórmula exata do veneno fora de Gretel ainda precisam ser registradas.
- Imunidade a fogo impede aplicar queimadura mesmo se Lume tiver fogo permanente. A bênção impede remover/expirar fogo aplicado, não ultrapassa imunidades.
- Constituição de Mineradora protege Snow de condições negativas que causem dano, não de todos os controles.
- Aladin com Proteção ao Portador da Lâmpada é imune a todos os efeitos negativos enquanto restar um desejo.
- Limpeza e expiração não são mortes ou quebra de escudo por dano e não devem conceder esses gatilhos automaticamente.
- Compatibilidade de condições iguais de fontes diferentes, não acúmulo global e ordem entre múltiplos danos no início da vez ainda precisam de decisão uniforme; não presumir que a regra de uma ficha vale para todas.

## 9. Alvos, formações e prioridade

- Formação: vanguarda, meio e retaguarda; cada coluna comporta até três personagens.
- Coluna é o grupo vertical de uma dessas posições. Linha horizontal atravessa posições, como o Cortejo da Alice.
- Assassinos podem alcançar as três colunas. Vanguardas focam a vanguarda; comportamento completo quando ela estiver vazia será definido pelo sistema de prioridade.
- Sistema configurável de prioridade é planejado, ainda não implementado por esta documentação. Transferências como A Nova Bruxa de Gretel usam o próximo alvo válido da prioridade dela.
- Mulan com Fogos de Artifício atinge a coluna escolhida e a imediatamente atrás, sem terceira propagação.
- João não redireciona as estocadas restantes da ult quando sua presa morre.
- Lume com o básico extra e Gato com o golpe adicional de sua bênção repetem o primeiro alvo quando não existir segundo alvo válido.
- Ricochetes de Umi não repetem alvos na mesma execução.
- A escolha detalhada de alvos secundários, desempates e geometria precisa ser uniforme na implementação.

## 10. Interceptação, sombras e sobrevivência

### Snow

Intercepta ataque de alvo único contra retaguarda ou Assassino com 50% de chance. Após duas falhas consecutivas, garante a próxima tentativa. Uma ativação bem-sucedida zera falhas e esgota o uso até o início da próxima vez dela. Não esquiva do golpe interceptado; recebe 20% menos dano. Não intercepta área.

### Alice

Escapada Mágica troca com qualquer aliado vivo da retaguarda, incluindo magos. O aliado recebe o golpe; sem aliado elegível, não ativa. Alice recebe 100% de esquiva até sua próxima vez. Uso por estágio, conforme a ficha.

### Peter

Esquiva cria sombra; acerto inimigo remove uma, sem bloquear ou reduzir dano. Máximo três. Ataques das sombras não as consomem. Dano periódico não cria nem remove sombras. Ult completa até três e fortalece até o início da próxima vez.

### Gato

- Ainda Tenho Garras: uma vez por estágio, fica com um PV ao sofrer dano fatal e não pode morrer até o início da próxima vez. Controle ainda funciona.
- O Gato de Botas: até nove retornos por run, chances de 100% a 20% em passos de dez, restaurando 20% da vida máxima. Preserva mana e limpa condições negativas. Contagem não reinicia com ressurreições externas.
- As duas bênçãos não operam juntas, pois só se escolhe uma por run.

### Aladin

Um de cada desejo por run. Vida revive todos os mortos com vida cheia. Morte elimina normais/secundários e causa 1000% do Dano Mágico em chefes de estágio/secretos, sem crítico; substitui a proposta anterior de metade da vida máxima. Calcula poder antes de gastar o desejo. Riqueza provisória: 200 × estágio, indexado a partir de um.

## 11. O que foi descartado ou substituído

- Armadura como subtração fixa, velocidade por intervalo e mana por segundo.
- Pólvora de Scarlet explodir sozinha na terceira carga; crítico conceder carga extra naturalmente; ult mágica da proposta intermediária.
- Alice como vanguarda, atiradora puramente física ou usuária de mana.
- Snow baseada em veneno/drenagem; sua identidade final é mineração e quebra de escudos.
- Peter com escudos, espíritos que anulam ataques ou redução de dano ao perder sombra.
- Aladin com Sono ou ciclo de três desejos nos básicos. Seu especial manual substitui a ult antiga.
- Maria como atacante de estocada que consome veneno na ult.
- Gato baseado em Ímpeto. O bônus final depende da porcentagem de vida faltante.

## 12. Pendências transversais antes de implementar

1. Desempate de iniciativa e política de arredondamento/frações de PV e mana.
2. Ordem de danos periódicos, recuperação, limpeza e expiração no início da vez.
3. Regras globais de Sono; duração e magnitude padrão de condições sem ficha específica.
4. Acúmulo/renovação de escudos e condições entre fontes diferentes; consumo das parcelas de escudo.
5. Confirmar se Quebra-Escudos só reduz novas aplicações, como foi interpretado.
6. Finalizar prioridades de alvo e tratamento de colunas vazias.
7. Definir se dano real ignora ou não reduções gerais além das defesas; escudos continuam podendo absorver.
8. Portar as descrições finais para exportador/UI e corrigir campos antigos, sem tratar `ultCoeff = 0` como ausência de especial ou defesa antiga como porcentagem.
9. Validar itens, economia e condições de desbloqueio ainda dependentes desses sistemas; em especial nove alvos de Scarlet, escudo 200 em um personagem de Silk e Riqueza de Aladin.

Nada nesta lista autoriza substituir decisões dos personagens por novos valores sem revisão. Os pontos restantes foram separados para não apresentar hipóteses como regras confirmadas.
