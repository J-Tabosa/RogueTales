# Apresentação e controles — 0.9.2

- Deslocamento usa uma pose estática, sem repetir o idle ou deformar os ombros.
- Idle: gesto único de aproximadamente 2 segundos, seguido por uma pausa aleatória de 7 a 11 segundos. O ritmo visual não acelera em 2×/3×.
- Seleção, ficha, equipe, passivas e ULTs usam a mesma pose de combate como fonte. Recortes de rosto e contêineres têm limites explícitos; a Vendedora usa a transparência da arte de combate.
- Tocar em um cartão abre a ficha; a seleção tem um botão largo e não tem um segundo botão de habilidades.
- A lista de habilidades na ficha da equipe aceita arraste por toque sobre textos e cartões.
- Ouro no cabeçalho, ao lado de uma moeda ilustrada.
- A música mantém seus recursos ao mover a janela do jogo no PC.
- Onda azul translúcida no impacto da ULT da Sereia e tremor de até 2 pixels em alguns impactos fortes. A opção de movimento reduzido desliga a tremida e usa apenas uma leve coloração.
- Auras vermelha, azul, roxa, verde e dourada são visuais reutilizáveis. `arena.atmosphere.aura(indice, "purple", 1.5)` apresenta uma aura temporária.
- O visual reconhece `immortal_turns`, `invulnerable_turns`, `invulnerable_left`, `enraged`, `rage_left`, `curse_left` e `aura_color`. A aura de imortalidade permanece enquanto o estado estiver ativo; o sistema visual não concede imunidade.
- Os símbolos de sangramento e maldição são artes geradas. Maldição e sono aparecem sem contadores de dano. Sangramento está preparado para dados `bleed`/`bleed_left` ou `bleeding`/`bleeding_left`; esta atualização não atribui sangramento a habilidades existentes.

Arte de moedas, sangue e caveira: ferramenta integrada de geração de imagens. Prompts em `assets/fx/ART_PROMPTS.md`. A onda e as auras são desenhadas pelo Godot.
