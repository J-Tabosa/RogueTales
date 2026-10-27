# RogueTales — Sistema de Bônus

Especificação para implementação. Consolidada em 26/10/2026 a partir das decisões do autor.

## 1. Objetivo e escopo

Substituir as antigas **Relíquias de atributos da run** por **Bônus**, com modalidade, raridade e valores definidos neste documento.

Esta etapa implementa Bônus. Não inventar, substituir ou balancear agora o catálogo de equipamentos, troféus exclusivos, bênçãos de protagonista ou habilidades dos personagens. Bônus não ocupam espaços de equipamento e não são bênçãos de protagonista.

Os equipamentos terão uma reformulação posterior, com pelo menos 30 itens, efeitos distintos e raridades próprias. Continuam limitados a **dois espaços por personagem**. Não reutilizar automaticamente as probabilidades ou valores de Bônus para equipamentos.

## 2. Modalidades

| Modalidade | Aplicação | Chance por oferta de Bônus |
|---|---|---:|
| Único | Jogador escolhe a oferta e depois um personagem elegível para recebê-la. | 70% |
| De Grupo | Aplica o bônus a todos os integrantes compatíveis; valores individuais geralmente menores. | 30% |

“Único” significa aplicação individual, não limite de uma aquisição por run. O mesmo bônus pode aparecer novamente e acumular.

Bônus duram até o fim da run. Bônus de Grupo também beneficiam integrantes recrutados depois. Guardar o histórico/estado de grupo para aplicar cada aquisição uma única vez a cada personagem, sem duplicar ao carregar saves ou reequipar itens.

## 3. Raridades

| Raridade | Probabilidade por oferta de Bônus |
|---|---:|
| Comum | 40% |
| Incomum | 28% |
| Raro | 18% |
| Épico | 9% |
| Lendário | 4% |
| Mítico | 1% |
| **Total** | **100%** |

Raridade determina o valor exato. Não fazer outra rolagem entre mínimo e máximo dentro da mesma raridade.

Estas probabilidades são de cada oferta que já foi definida como Bônus; não são taxas de equipamento, recrutamento ou bênção. Este documento não muda a frequência de recompensas pós-combate nem a quantidade de opções da tela.

## 4. Bônus Únicos

“pp” = pontos percentuais. Defesas e Iniciativa usam pontos; PV, ataques, alvos e mana usam quantidades absolutas.

| Atributo | Comum | Incomum | Raro | Épico | Lendário | Mítico |
|---|---:|---:|---:|---:|---:|---:|
| Dano Mágico | +5% | +8% | +12% | +16% | +20% | +25% |
| Dano Físico | +5% | +8% | +12% | +16% | +20% | +25% |
| Defesa Física | +8 | +12 | +17 | +23 | +29 | +35 |
| Defesa Mágica | +8 | +12 | +17 | +23 | +29 | +35 |
| Quantidade de Ataques | — | — | +1 | +1 | +2 | +3 |
| Mana por Acerto | +5 | +7 | +10 | +13 | +16 | +20 |
| Mana por Turno | +2 | +3 | +4 | +6 | +8 | +10 |
| Vida Máxima | +20 | +30 | +45 | +60 | +80 | +100 |
| Chance Crítica | +10 pp | +15 pp | +20 pp | +30 pp | +40 pp | +50 pp |
| Dano Crítico | +5 pp | +10 pp | +20 pp | +30 pp | +40 pp | +50 pp |
| Esquiva | +5 pp | +7 pp | +10 pp | +13 pp | +16 pp | +20 pp |
| Iniciativa — magnitude escolhida | 5 | 8 | 12 | 16 | 20 | 25 |
| Aumento de Cura | +5% | +8% | +12% | +16% | +20% | +25% |
| Espalhamento — alvos adicionais | — | — | +1 | +1 | +2 | +3 |

Traço significa que aquela combinação não existe e não pode ser sorteada. Ataques e Espalhamento usam seis níveis de raridade, mas não precisam de seis valores distintos, pois suas quantidades são inteiras.

## 5. Bônus de Grupo

| Atributo | Comum | Incomum | Raro | Épico | Lendário | Mítico |
|---|---:|---:|---:|---:|---:|---:|
| Dano Mágico | +3% | +4% | +6% | +8% | +10% | +13% |
| Dano Físico | +3% | +4% | +6% | +8% | +10% | +13% |
| Defesa Física | +4 | +6 | +9 | +12 | +15 | +18 |
| Defesa Mágica | +4 | +6 | +9 | +12 | +15 | +18 |
| Quantidade de Ataques | — | — | — | — | +1 | +1 |
| Mana por Acerto | +3 | +4 | +5 | +7 | +8 | +10 |
| Mana por Turno | +1 | +2 | +2 | +3 | +4 | +5 |
| Vida Máxima | +10 | +15 | +23 | +30 | +40 | +50 |
| Chance Crítica | +5 pp | +8 pp | +10 pp | +15 pp | +20 pp | +25 pp |
| Dano Crítico | +3 pp | +5 pp | +10 pp | +15 pp | +20 pp | +25 pp |
| Esquiva | +3 pp | +4 pp | +5 pp | +7 pp | +8 pp | +10 pp |
| Iniciativa — magnitude escolhida | 3 | 4 | 6 | 8 | 10 | 13 |
| Aumento de Cura | +3% | +4% | +6% | +8% | +10% | +13% |

**Espalhamento só existe como Único.** Não oferecer a modalidade de Grupo para ele. Aumento de Escudo não foi incluído nesta lista aprovada; será tratado separadamente se solicitado.

## 6. Iniciativa positiva ou negativa

O jogador pode escolher agir depois. Ofertas de Iniciativa permitem selecionar **aumentar ou diminuir pela magnitude da raridade**, mostrando a iniciativa resultante antes de confirmar.

Exemplo: Único Mítico em personagem com 50 permite escolher **75 ou 25**. Com iniciativa dez, escolher −25 resulta em **−15**, não zero.

- Não sortear uma penalidade sem escolha: o sinal é uma decisão do jogador.
- Iniciativa continua ordenada do maior para o menor e tem valor padrão 50.
- O teto continua 100. **Não limitar o valor mínimo a zero**; iniciativa final pode ser negativa.
- Não foi definido piso negativo. Não inventar um sem revisão do autor.
- Grupo usa um único sinal escolhido para todo o grupo, não um sinal diferente por personagem.
- A prévia mostra os limites aplicados individualmente.
- Quando a direção positiva não beneficiar ninguém por causa do teto, a negativa continua sendo uma opção válida.
- Na integração, remover travas antigas de zero em operações de Iniciativa, inclusive reduções, para não contradizer a nova regra.

## 7. Espalhamento

Espalhamento representa **+1 a +3 alvos secundários por ataque básico**, somente no personagem escolhido. Não é Quantidade de Ataques e não repete a execução completa do básico.

- Disponível a partir de Raro, conforme tabela.
- Aumenta o número de alvos, não a quantidade de cargas por impacto nem o multiplicador crítico.
- Cada impacto só gera mana, cargas e efeitos quando for elegível pelas regras do personagem.
- Exemplo: Scarlet acerta alvo principal e mais dois secundários; com dez de mana por acerto, recebe trinta no total e aplica pólvora nos três, respeitando sua bênção ativa.
- Não multiplicar contador de básicos de Alice por alvos atingidos. Uma execução continua concedendo uma carga de Cortejo, independentemente dos impactos secundários.
- Não modificar especiais de Aladin ou transformar proteções de Silk em ataques ofensivos.

**Decisão restante antes de implementar este atributo:** não foi definido o coeficiente do dano secundário. Não copiar silenciosamente 100%, 50% ou outro valor. Também faltam a regra de seleção desses alvos e a interação entre espalhamento genérico e ricochetes/espalhamentos próprios de cada personagem. Implementar os demais Bônus e manter Espalhamento fora do sorteio até fechar essa regra, caso seja necessário avançar antes da decisão.

## 8. Acúmulo e interpretação dos valores

### Percentuais de Dano Físico e Mágico

Somar entre si os percentuais recebidos pelo sistema de Bônus. Não multiplicar cada aquisição pela anterior.

```text
Dano do atributo após Bônus = base elegível × (1 + soma dos bônus percentuais daquele atributo)
```

Exemplo: dois Bônus de +25% em Dano Físico base 20 resultam em **30**, não 31,25. Não definir aqui uma nova ordem para todos os multiplicadores de habilidades e equipamentos; preservar suas regras e manter os Bônus identificados separadamente.

Aumento percentual sobre atributo zero permanece zero. Mostrar isso na seleção e excluir beneficiários para os quais aquele bônus seria totalmente inútil.

### Chance crítica e Dano Crítico

- +10 pp de Chance Crítica leva 15% para 25%.
- +50 pp de Dano Crítico leva ×2 a ×2,5 e Peter de ×3 a ×3,5. Não multiplicar ×2 por 1,5 para esse caso.
- Limite de Chance Crítica: 100%.
- Esquiva comum: máximo 80%. Exceções temporárias explícitas, como a habilidade da Alice, continuam independentes.
- Não criar um limite novo para multiplicador crítico sem decisão do autor.

### Defesas

Defesas são pontos absolutos. Manter a fórmula aprovada:

```text
Dano após defesa = dano bruto × 100 / (100 + defesa correspondente)
```

Exemplo: +35 de Defesa Física em quem tem dez resulta em 45 pontos; não 45% de redução.

### Mana

- Mana por Acerto aumenta o ganho de cada impacto elegível, não uma única concessão por sequência/turno.
- Mana por Turno é concedida uma vez no início da vez própria; não volta a ser regeneração por segundo.
- Não tornar golpes excluídos elegíveis: ult de João, contra-ataque de Mulan, danos periódicos e sombras de Peter preservam suas exceções.
- Alice e Aladin não usam mana e não podem receber Bônus Únicos de mana.
- Silk pode beneficiar-se de Mana por Turno; não oferecer Mana por Acerto para ela sem existir uma fonte explicitamente elegível nas suas regras.

### Vida Máxima

- Para personagem vivo: acrescentar o mesmo valor ao máximo e aos PV atuais, preservando a quantidade absoluta de vida faltante.
- Exemplo: 50/200 com +20 vira 70/220.
- Para personagem morto: atualizar o máximo, mantendo PV atual zero. O Bônus não revive.
- Recrutamento e carregamento de save não podem repetir a cura de uma aquisição já aplicada.

### Aumento de Cura

- Aumenta curas produzidas pelo beneficiário, não toda cura recebida de outros personagens.
- Percentuais desse Bônus somam entre si.
- Exemplo: cura base vinte com +25% resulta em 25; Corta-Cura de 50% reduz o resultado a 12,5.
- Não modifica valor de escudo diretamente. A cura excedente da Umi pode gerar mais escudo por consequência da cura maior, respeitando seu limite.
- Não oferecer Único para personagem sem nenhuma cura compatível.

## 9. Seleção e elegibilidade

1. Identificar uma vaga de recompensa como Bônus sem mudar as regras existentes de recrutamento e outras recompensas.
2. Sortear raridade pelas chances da seção 3.
3. Sortear modalidade: 70% Único, 30% Grupo.
4. Listar os atributos válidos para essa combinação e o estado da equipe. Excluir combinações com traço, incluindo Espalhamento de Grupo.
5. Sortear um atributo elegível. Na ausência de pesos especiais definidos, usar pesos iguais entre os atributos elegíveis.
6. Exibir atributo, modalidade, raridade, valor e prévia. Não conceder nada apenas por exibir ou clicar para abrir seleção.
7. Se Único, abrir seleção do personagem elegível. Se Iniciativa, solicitar o sinal antes da confirmação final.
8. Confirmar uma única escolha e aplicá-la atomicamente.

O item 5 é uma convenção técnica inicial para atributos sem pesos individuais definidos, não uma nova taxa global de raridade.

Se uma combinação sorteada não tiver nenhum atributo útil, não entrar em laço infinito. Usar alternativa válida com tratamento explícito; não re-sortear raridade repetidamente até sair uma melhor. Testar esse caso e documentar a alternativa empregada.

### Limites e utilidade

- Não oferecer Único sem beneficiário elegível.
- Excluir personagem que não ganha nenhum valor efetivo por já estar no limite.
- Permitir ganho parcial no limite e mostrar a quantidade efetiva. Exemplo: 75% de esquiva com +20 pp termina em 80%, ganho efetivo cinco pp.
- Grupo só aparece se ao menos um integrante atual tiver benefício útil. Integrantes incompatíveis são ignorados naquele atributo; futuros recrutados compatíveis continuam recebendo o histórico.
- Não remover Grupo apenas porque alguns personagens não usam mana ou possuem zero no atributo de dano correspondente.
- Não oferecer apenas ganhos cosméticos que não alteram o combate: considerar as fontes realmente compatíveis, não só a existência de um campo numérico.
- Personagens mortos podem receber Bônus compatíveis, sem reviver ou ativar ações. Mostrar esse estado claramente.

## 10. Interface e informação ao jogador

- Renomear Relíquias para Bônus nas telas ligadas a essas recompensas, descrições, registros e dicas.
- Evitar substituição cega de termos em bênçãos, nomes de equipamentos ou textos narrativos.
- Cartão deve informar modalidade, raridade, atributo e valor, sem esconder o alvo da aplicação.
- Único: abrir escolha de personagem e mostrar antes/depois.
- Grupo: mostrar ganhos da equipe e eventuais incompatibilidades/limites.
- Iniciativa: botões ou seleção explícita “Agir antes (+N)” e “Agir depois (−N)”. Mostrar os números finais, inclusive negativos.
- Permitir voltar da escolha de alvo/sinal sem consumir a recompensa.
- Informar duração até fim da run e persistência para novos recrutados nos Bônus de Grupo.
- Usar nomenclatura “Mana por Acerto”, não “Mana por Ataque”, para deixar a regra de múltiplos alvos clara.

## 11. Saves e migração

- Registrar atributo, modalidade, raridade, magnitude, sinal quando aplicável e personagem receptor quando Único.
- Manter acumuladores separados dos atributos base para evitar duplicação ao carregar, trocar equipamento ou recalcular passivas.
- Registrar quais Bônus de Grupo já foram aplicados a cada integrante.
- Preservar Bônus de Grupo para novos recrutados e atravessar fases/estágios normalmente.
- Não apagar saves antigos silenciosamente. Tratar as antigas relíquias com migração explícita, ou avisar incompatibilidade caso a conversão não seja segura.
- O mapeamento exato das antigas relíquias, inclusive cura fixa e efeitos mistos, ainda não foi escolhido. Não converter uma antiga recompensa em ganho mais forte arbitrariamente.
- Não alterar JSONs base dos personagens para incorporar permanentemente ganhos de uma run.

## 12. Validação necessária

- Probabilidades de raridade somam 100%; modalidades somam 100%.
- Sorteio não produz combinações indisponíveis ou Espalhamento de Grupo.
- Bônus Único só afeta o alvo confirmado; cancelar não aplica efeito.
- Grupo aplica uma vez aos integrantes atuais e uma vez ao recrutado futuro.
- Dois percentuais iguais somam; não compõem multiplicativamente.
- Defesas usam pontos; crítico usa pp e multiplicador correto; esquiva respeita 80%.
- Iniciativa negativa aparece na prévia, é salva e ordena corretamente personagens.
- Vida não revive e cura apenas uma vez; save/load não repete ganho de PV.
- Mana respeita impactos elegíveis e personagens sem recurso.
- Ataques adicionais executam o básico completo e permitem as ults intercaladas previstas nas fichas.
- Não introduzir recursão de gatilhos em sombras, retaliações ou espalhamentos.

## 13. Próxima etapa — equipamentos

O autor criará a próxima lista. Direção acordada: **pelo menos trinta equipamentos**, apenas **dois espaços por personagem**, efeitos interessantes ou poder individual que justifique o espaço ocupado em comparação com os Bônus.

Raridades e taxas dos equipamentos ainda serão divididas separadamente. Não preencher esta especificação com trinta efeitos inventados ou aplicar automaticamente os troféus antigos como catálogo final.
