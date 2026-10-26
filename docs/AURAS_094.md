# Auras translúcidas — 0.9.4

As auras agora são faixas de energia animadas: chamas, órbitas, espirais e correntes. O centro permanece aberto e cada camada tem baixa opacidade, preservando a leitura do personagem. Os desenhos são originais e produzidos pelo Godot; a imagem de referência não é usada como textura.

| Cor | Chave | Forma padrão |
|---|---|---|
| Vermelho | `red` | Chama |
| Laranja | `orange` | Chama |
| Âmbar | `amber` | Chama |
| Dourado | `gold` | Chama |
| Amarelo | `yellow` | Chama |
| Lima | `lime` | Órbita |
| Verde | `green` | Órbita |
| Menta | `mint` | Órbita |
| Turquesa | `teal` | Órbita |
| Ciano | `cyan` | Corrente |
| Azul | `blue` | Corrente |
| Índigo | `indigo` | Espiral |
| Roxo | `purple` | Espiral |
| Violeta | `violet` | Espiral |
| Rosa | `pink` | Espiral |
| Branco | `white` | Corrente |

Uso: `arena.atmosphere.aura(indice, "purple", 1.5)`.

A forma pode ser escolhida com o quarto argumento: `aura(indice, "green", 2.0, "spiral")`. Também aceita nomes de cores em português. Para estados persistentes, use `aura_color` e, opcionalmente, `aura_style`; os campos de fúria, maldição e imortalidade continuam ligados às cores existentes.

O relógio visual respeita pausa. Movimento reduzido mantém o desenho parado. A alteração é visual e mantém as condições e durações do combate.
