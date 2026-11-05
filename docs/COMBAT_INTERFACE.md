# Correção da interface em manuscrito

A interface deste repositório é nativa do **Godot 4.7**, sem HTML ou CSS. As regras solicitadas foram implementadas em controles, containers, StyleBoxes, variáveis de tema e assets. Combate, dano, absorção de escudos, recursos e salvamento não foram alterados.

## Estrutura

- Moldura lateral fixa: 48–84 pixels, flor superior e inferior sem deformação, linha dupla central independente. O conteúdo reserva a largura das duas barras e 8 pixels de folga. Nenhum traço decorativo atravessa as abas.
- Cartões: contorno duplo chanfrado, losangos centrais, retrato quadrado com cantos comuns, informação em losango, vida e recurso, equipamentos e status em itálico. No celular, a coluna usa rolagem vertical para manter o texto em tamanho legível.
- Pausa, AUTO ULT e velocidade usam a mesma moldura e altura. AUTO ULT tem indicador separado; velocidade tem avanço duplo; pausa alterna entre pausa e play.
- Vida: trilho escuro, verde sólido para aliados e vermelho para inimigos. Texto claro, negrito, monoespaçado, com contorno e sombra escuros nos dois temas. A vida máxima mostrada é a vida real, sem somar escudo.
- Escudo: trecho prateado/azulado limitado à barra, ícone vetorial e quantidade reservados ao lado do número de vida. A transição visual dura 200 ms. Não existem runas, auras ou partículas de escudo ao redor dos personagens.
- Barras inimigas pertencem ao sprite, com escala visual compensada. Comuns usam 48–140 pixels e vida sob hover/toque; chefes usam 200–320 pixels e números permanentes. Morte oculta a barra com fade. O posicionamento dos indicadores evita colisões entre barras sem modificar as regras de formação.
- Modais: raiz no viewport; largura até 920 pixels ou 92% da tela; altura até 90%. Cabeçalho e rodapé fixos, uma área central rolável. Recompensas têm três opções da mesma largura, lado a lado em telas largas e empilhadas no celular.
- A ficha usa atributos no topo, habilidades abaixo e retrato completo com `STRETCH_KEEP_ASPECT_CENTERED`. Informações de habilidades expandem dentro da linha e entram na mesma rolagem, sem cobrir a ficha.

Cores vêm de `TaleTheme`: paletas existentes preservadas, tokens `bar_*` nos dois temas, números com a mesma regra de contraste e raridades intactas. Lora e Cinzel permanecem; DejaVu Sans Mono Bold, com licença, é usada apenas nos indicadores numéricos. O ornamento floral gerado é recolorido por shader com a cor do tema.

## Regras visuais antigas removidas

| Origem | Remoção/substituição |
| --- | --- |
| `manuscript_art.gd::folio` | Linhas verticais externas, linha horizontal inferior, losango do rodapé e cantos soltos desenhados no fundo. |
| `theme_surface.gd` | Chamadas ao folio, moldura automática em qualquer coluna/painel grande, borda automática em elementos de altura ≥30 e linha de sombra no pé de painéis. |
| `theme_surface.gd::frame_png` | Recorte e estiramento da moldura PNG em nove partes, incluindo a camada extra sobre botões primários. |
| `manuscript_art.gd`, papel `chapter` | Cartão com apenas uma linha inferior; substituído pelo cartão completo com moldura dupla. |
| `interface.gd::relayout_battle` | Cartões móveis de 176 pixels, números de 7–12 pontos, deck horizontal e deslocamento horizontal dos modais pela largura lógica da batalha. |
| `health_display.gd` | Cor de vida por cinco faixas, valor máximo somando escudo no texto, e atualização instantânea do trecho de escudo. |
| `tactical_arena.gd` | Indicadores ligados à arena, com baixo z-index e fontes de 7–9 pontos; agora pertencem ao sprite. |
| `ultimate_vfx.gd` / `shield_runes.gd` | Desenho de fragmentos, losangos, motes e runas; helper antigo removido. |
| `main.gd::modal` / `expedition_ui.gd::journey_modal` | Overlay de 540 pixels dentro do conteúdo escalado; painel de 508×718 deslocado manualmente sobre a batalha. |
| `character_inspector.gd` | Popup sobreposto à parte inferior da ficha, altura fixa da lista de habilidades e retrato recortado por um painel. |

Não há seletores CSS antigos neste projeto; a tabela identifica as regras equivalentes removidas no Godot.

## Arquivos alterados

Apresentação: `scripts/main.gd`, `interface.gd`, `expedition_ui.gd`, `theme_surface.gd`, `manuscript_art.gd`, `ui_theme.gd`, `health_display.gd`, `tactical_arena.gd`, `ultimate_vfx.gd`, `character_inspector.gd`, `equipment_panel.gd`.

Novos componentes: `scripts/side_rails.gd`, `modal_shell.gd`, `shield_icon.gd`. Removido: `scripts/shield_runes.gd`.

Assets: `assets/ui/themes/shared/rail_flower.png`, `rail_rule.svg`, `frame_corner.svg`, `frame_diamond.svg`, `ornament_tint.gdshader`; fonte e licença em `assets/fonts/numeric/`. Os novos recursos acompanham seus arquivos de importação/UID quando gerados pelo Godot.

Verificação: `tests/interface_repair.gd`, `manuscript_combat_ui.gd`, `ui_themes.gd`, `arena_equipment_layout.gd`, `combat_readability.gd`, `skills_equipment_102.gd`. Documentação: este arquivo e `README.md`.

## Verificação reproduzível

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/interface_repair.gd
# Com renderização nativa, salva as capturas em um diretório:
godot --path . --audio-driver Dummy --script res://tests/interface_repair.gd -- ./previews 3
```

A suíte percorre **1920×1080, 1366×768, 1280×720 e 390×844**, nos dois temas: início, batalha, ficha, informação expandida e recompensa. Em 1280×720 e 390×844 também captura aliado com/sem escudo, inimigo comum com/sem escudo e chefe. Verifica limites, tipografia numérica, recursos, propriedade das barras, segmento de escudo, retrato proporcional, largura das opções, centralização, ausência de rolagem horizontal e preservação do estado do combate.

## Resultado local

Godot 4.7 importado sem erro de script. A suíte da correção passou em 876 verificações; temas em 2.504; desejos/Silk em 655; regras atuais em 53. Também passaram as suítes de legibilidade/toque, formação com 5 aliados e 9 inimigos e troca de equipamentos. O teste histórico `battle_flow` descreve regras antigas e está excluído da validação atual, conforme `tests/README.md`.

## Lista completa de arquivos

| Arquivo | Alteração |
| --- | --- |
| `README.md` | Modificado |
| `assets/fonts/numeric/DejaVuSansMono-Bold.ttf` | Adicionado |
| `assets/fonts/numeric/DejaVuSansMono-Bold.ttf.import` | Adicionado |
| `assets/fonts/numeric/LICENSE.txt` | Adicionado |
| `assets/ui/themes/shared/frame_corner.svg` | Adicionado |
| `assets/ui/themes/shared/frame_corner.svg.import` | Adicionado |
| `assets/ui/themes/shared/frame_diamond.svg` | Adicionado |
| `assets/ui/themes/shared/frame_diamond.svg.import` | Adicionado |
| `assets/ui/themes/shared/ornament_tint.gdshader` | Adicionado |
| `assets/ui/themes/shared/ornament_tint.gdshader.uid` | Adicionado |
| `assets/ui/themes/shared/rail_flower.png` | Adicionado |
| `assets/ui/themes/shared/rail_flower.png.import` | Adicionado |
| `assets/ui/themes/shared/rail_rule.svg` | Adicionado |
| `assets/ui/themes/shared/rail_rule.svg.import` | Adicionado |
| `docs/COMBAT_INTERFACE.md` | Modificado |
| `scripts/character_inspector.gd` | Modificado |
| `scripts/equipment_panel.gd` | Modificado |
| `scripts/expedition_ui.gd` | Modificado |
| `scripts/health_display.gd` | Modificado |
| `scripts/interface.gd` | Modificado |
| `scripts/main.gd` | Modificado |
| `scripts/manuscript_art.gd` | Modificado |
| `scripts/manuscript_art.gd.uid` | Adicionado |
| `scripts/modal_shell.gd` | Adicionado |
| `scripts/modal_shell.gd.uid` | Adicionado |
| `scripts/shield_icon.gd` | Adicionado |
| `scripts/shield_icon.gd.uid` | Adicionado |
| `scripts/shield_runes.gd` | Removido |
| `scripts/side_rails.gd` | Adicionado |
| `scripts/side_rails.gd.uid` | Adicionado |
| `scripts/tactical_arena.gd` | Modificado |
| `scripts/theme_surface.gd` | Modificado |
| `scripts/ui_theme.gd` | Modificado |
| `scripts/ultimate_vfx.gd` | Modificado |
| `tests/README.md` | Modificado |
| `tests/arena_equipment_layout.gd` | Modificado |
| `tests/combat_readability.gd` | Modificado |
| `tests/interface_repair.gd` | Adicionado |
| `tests/interface_repair.gd.uid` | Adicionado |
| `tests/manuscript_combat_ui.gd` | Modificado |
| `tests/skills_equipment_102.gd` | Modificado |
| `tests/ui_themes.gd` | Modificado |
| `tools/art_sources/ui_ornaments/rail_flower_prompt.json` | Adicionado |
