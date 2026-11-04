# Interface — temas, ornamentos e cores de gameplay

Alterne em **Configurações → switch Tema** ou em **Pausa → switch Tema**. O controle aceita clique, toque e teclado; ligado seleciona o Claro, desligado seleciona o Escuro. A escolha fica salva como `ui_theme`. A troca atualiza a tela aberta sem recriar a run.

## Cores da interface

Os valores ficam em `TaleTheme.PALETTES`, em `scripts/ui_theme.gd`. Consulte-os com `TaleTheme.c("token", alpha)`. Fundos, painéis, cartões e espaços internos têm tons distintos, gradientes com três paradas, luz superior e sombra inferior. Botões principais e estados de hover/foco também têm tratamentos próprios.

| Token | Escuro | Claro |
|---|---|---|
| `background` | `#07253f` | `#e5d0a1` |
| `background_bottom` | `#031522` | `#c7a36f` |
| `surface` | `#10394b` | `#ddbd82` |
| `surface_top` | `#1c4f61` | `#f5e7c9` |
| `surface_bottom` | `#092737` | `#c9a772` |
| `card` | `#17485a` | `#ead1a1` |
| `card_top` | `#286175` | `#faefd9` |
| `card_bottom` | `#103647` | `#d9b67e` |
| `well` | `#071f2c` | `#c5a670` |
| `well_top` | `#103444` | `#dfc490` |
| `well_bottom` | `#051a28` | `#bea06b` |
| `secondary` | `#3c95a9` | `#ddbd82` |
| `button` | `#205468` | `#d8b474` |
| `button_top` | `#316b7d` | `#f2dab0` |
| `primary` | `#225f70` | `#c29a59` |
| `primary_top` | `#307b87` | `#dec18c` |
| `hover` | `#30697d` | `#ebcf98` |
| `pressed` | `#0c3042` | `#c6a066` |
| `border` | `#3c95a9` | `#99723c` |
| `accent` | `#aceaf1` | `#684921` |
| `text` | `#ffffff` | `#3b2414` |
| `muted` | `#d2edf2` | `#5b3d23` |
| `disabled` | `#97b6c3` | `#735434` |
| `ornament` | `#aceaf1` | `#a27632` |
| `shadow` | `#031524` | `#8c693c` |
| `track` | `#041c30` | `#c3a36d` |
| `progress` | `#aceaf1` | `#684921` |
| `selection` | `#3c95a9` | `#c4a069` |

## Cores de gameplay preservadas

**Vida, mana, escudos, dano, status e raridades não acompanham a paleta decorativa.** Os tokens abaixo ficam em `TaleTheme.SEMANTIC`, com os mesmos valores nos dois temas. Barras e números de combate usam a superfície escura original para manter leitura; valores de dano nas fichas também recebem fundo escuro, preservando vermelho/azul.

| Token | Cor |
|---|---|
| `health_full` | `#67cf85` |
| `health_high` | `#c5e85a` |
| `health_half` | `#f2d36b` |
| `health_low` | `#f5a052` |
| `health_critical` | `#ff6969` |
| `mana` | `#8ab4f0` |
| `mana_text` | `#a9c9ff` |
| `shield` | `#8ddbee` |
| `physical` | `#ff6969` |
| `magical` | `#64c7ff` |
| `true_damage` | `#ead9ff` |
| `combat_surface` | `#102a24` |
| `combat_border` | `#8c7043` |
| `combat_text` | `#f5e8c3` |
| `combat_track` | `#091a19` |
| `damage_outline` | `#101321` |
| `rarity_text` | `#fff4df` |
| `rarity_disabled` | `#c5c8c2` |

| Raridade | Cor fixa |
|---|---|
| Comum | `#858b94` — cinza |
| Incomum | `#50b86a` — verde |
| Raro | `#5097ee` — azul |
| Épico | `#ac6bef` — roxo |
| Lendário | `#ef9c39` — laranja |
| Mítico | `#ee5555` — vermelho |
| Especial / troféu | `#e6cb79` — dourado |

Inventário, slots equipados, recompensas, mercador e bônus exibem bordas e fundos coloridos pela raridade. A seleção reforça a borda sem substituir sua cor. A camada de tema preserva as cores de BBCode de dano e o tom próprio dos números de combate.

## Tipografia

**Nunito Semibold** para textos e números; **Nunito Extrabold** para botões, nomes e destaques; **Cinzel** para títulos maiores. São fontes já incluídas no projeto com suas licenças OFL. Os tamanhos, rolagem, funções e hierarquia permanecem; o sistema de ajuste de texto mede a fonte efetiva.

## PNGs integrados

As 12 imagens originais estão em **`assets/ui/themes/dark/`** e **`assets/ui/themes/light/`**, seis por tema. As artes coloridas são desenhadas com modulação branca, preservando a paleta e o relevo originais. Os SVGs de `shared/` continuam como fallback. Mipmaps e filtragem linear mantêm os desenhos pequenos nítidos e estáveis.

| Nome em cada pasta | Resolução | Onde é usado |
|---|---|---|
| `corner_filigrane.png` | 1254 × 1254 | Cantos externos do fundo no PC; uma região do canto é reutilizada e espelhada. |
| `horizontal_border.png` | 2172 × 724 | Faixa horizontal repetida no acabamento inferior do fundo. |
| `section_divider.png` | 2172 × 724 | Divisor com roseta sob títulos. O atlas retira as margens transparentes. |
| `mandala_watermark.png` | 1254 × 1254 | Rosácea discreta em fundos e painéis grandes. |
| `surface_texture.png` | 1254 × 1254 | Textura repetida em escala reduzida, com baixa opacidade. |
| `panel_frame.png` | 1536 × 1024 | Moldura completa com centro transparente; painéis e botões principais. |

A moldura usa 9-slice com reservas de **350 px horizontais e 330 px verticais** na imagem original, mantendo os arabescos fora dos trechos esticáveis. Os cantos de destino ficam entre 14 e 28 px lógicos conforme o tamanho do controle. Painéis pequenos e espaços de combate usam acabamento contido para não invadir números. Nenhum PNG foi redimensionado, recolorido ou recomprimido no arquivo de origem; recortes são feitos por `AtlasTexture`.

## Convenções para novos componentes

- `theme_rarity` ou `bonus_rarity`: índice da raridade, independente do tema.
- `theme_bar_role`: token semântico do preenchimento, como `mana`.
- `health_bar`: preenchimento atualizado por `HealthDisplay` e suas cinco faixas.
- `theme_semantic_color`: cor autoral de um rótulo; não é substituída pelo tema.
- `theme_text_role` / `theme_icon_role`: token explícito de texto ou ícone, por exemplo `physical` e `magical`.
- `combat_readout`: superfície escura legível em ambos os temas.
- `theme_surface_role`: `surface`, `card` ou `well` para a profundidade do painel.

`ui_theme.gd` centraliza a aplicação; `theme_surface.gd` desenha os PNGs, gradientes e 9-slice. Atualizações ocorrem por eventos de criação/troca de tema, sem varrer a árvore a cada frame. Texturas do tema anterior são liberadas do cache ao alternar. Cenários, personagens e shaders do combate preservam suas cores e escalas.

## Verificação

`tests/ui_themes.gd` verifica cores originais das cinco faixas de vida e das sete raridades, barras reais, números de dano, BBCode físico/mágico, inventário, switch por mouse/toque/teclado, persistência e troca em uma ficha aberta, além de contraste e telas PC/mobile. Gera capturas reais quando há display.

```sh
godot --headless --path . --script tests/ui_themes.gd
godot --path . --script tests/ui_themes.gd -- /tmp/rogue-tales-themes
```
