# ULTs — 0.9.0

As artes usam os personagens, IDLE e ATK enviados como referência. Cada personagem tem 8 quadros de IDLE, 12 de ataque e uma sequência de ULT; os efeitos possuem 12 quadros separados. Os atlases WebP preservam transparência. As poses e os efeitos seguem o mesmo relógio de impacto, param ao pausar e acompanham a velocidade do combate. O Gato mantém seu conjunto anterior.

| Personagem | Regra da ULT |
|---|---|
| Chapeuzinho | Cesta e catapulta; bombas fazem arcos e explodem em todos os inimigos. 220% de ataque + fogo de 12%/s por 4 s. |
| Sereia | Cavalga a onda gigante até o grupo inimigo. 200% de ataque em todos. |
| Aladin | Fecha os olhos e espalha a nuvem roxa. Sem dano; cada inimigo tem 50% de chance independente de perder seu próximo turno por sono. |
| João | Dash e seis estocadas em um alvo, 70% de ataque cada. Armadura é calculada por estocada. |
| Maria | Braços cruzados e caveira negra. Sem dano; todos perdem 20% da armadura e do dano de ataques por 8 s. Os valores base não são alterados. |
| Peter Pan | Cada ULT invoca um espírito, até três acumulados. Um ataque consome um espírito, preserva PV e escudo e reflete o dano bruto do golpe. Não permite gastar mana com três espíritos ativos. |
| Mulan | Giro e cortes horizontais na frente inimiga. 320% de ataque por alvo. |
| Branca de Neve | Brilho vermelho no olho, carga e picaretada em um único alvo, com impacto e rachaduras. 800% de ataque. |
| Rapunzel | Cabelo alcança a própria Rapunzel e até dois aliados vivos mais feridos. Escudo de 30% dos PV máximos de cada protegido; a ULT não cura. |
| Alice | Sem mana. Cada ataque avança um naipe e carrega uma carta, inclusive ao errar. O quarto ataque enfileira automaticamente o cortejo, mesmo com Auto ULT desligado. 220% de ataque na linha horizontal do alvo. |
| Vendedora de Fósforos | Fogo em órbita forma um dragão que chega ao centro inimigo. 200% de ataque em todos e queimadura de 25%/s por 6 s. |

Percentuais de dano são brutos, antes de armadura e modificadores. A duração de 8 s da maldição, os multiplicadores e os escudos são valores iniciais de balanceamento. Equipamentos e bênçãos continuam funcionando; efeitos de proteção/limpeza não transformam ULTs de suporte em ataques. As bênçãos de mana da Alice foram substituídas por bônus de dano.

A linha da Alice é calculada pelas coordenadas da formação, não pela coluna de classe. Os efeitos guardam os mesmos alvos escolhidos para a mecânica. Espíritos e cartas sobrevivem ao checkpoint; espíritos antigos são migrados para a nova proteção.

## Validação

- `tests/ultimate_overhaul.gd`: onze conjuntos, alvos, seis golpes, chance e consumo de sono, maldição temporária, bloqueio completo, proteção de três aliados, Alice sem mana, ULT automática e checkpoint.
- `tests/ultimate_overhaul_visual.gd`: capturas de cada ULT com nove inimigos, atualização natural dos efeitos, resolução real do impacto e interface de celular.
- Os testes de progressão, dificuldade 3/6/9, equipamento, combate, interface e saves permanecem aplicáveis. O combate legado de capítulos mantém suas regras anteriores.

Execute com Godot 4.7: `godot --headless --path . --script tests/ultimate_overhaul.gd`.
