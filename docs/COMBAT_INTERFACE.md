# Interface de combate em manuscrito

O combate usa Lora nos textos e números, Cinzel nos nomes e cabeçalhos, molduras de retrato iguais para toda a equipe e contornos chanfrados desenhados na resolução da tela. Não existem emblemas, acessórios ou desenhos exclusivos por personagem nas molduras.

As paletas de `TaleTheme.PALETTES` permanecem intactas. Os cinco intervalos de cor de vida, mana azul, escudos e raridades continuam semânticos nos dois temas. Os valores ficam dentro das barras, tanto na arena quanto no gestor de equipe. Alice mantém cartas; Aladin mantém desejos. A capacidade de vida/escudo segue `HealthDisplay`, sem alterar atributos ou cálculos.

O ouro fica no canto inferior esquerdo da arena. O aviso horizontal de ação/vez fica oculto; o histórico interno e os eventos de combate continuam disponíveis para a lógica e os avisos de habilidades.

## Escudos vivos

`shield_runes.gd` desenha fragmentos transparentes com runas, deslocamento vertical e pequenas marcas flutuantes. A animação segue o relógio da arena e acompanha a posição real de cada personagem. Só aparece em unidades vivas com escudo; quando o escudo acaba, desaparece no próximo desenho.

A pausa congela o relógio e a preferência de movimento reduzido estabiliza a geometria. Qualidade baixa diminui a quantidade de fragmentos. Não há nós, tweens ou texturas criados a cada quadro. As antigas bolhas ovais e os fios dourados persistentes nos pés foram removidos.

## Validação

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/manuscript_combat_ui.gd
godot --headless --path . --script res://tests/ui_themes.gd
godot --headless --path . --script res://tests/arena_equipment_layout.gd
```

`.github/workflows/combat-interface.yml` executa essas verificações e regressões de legibilidade, equipamentos e Silk no Godot 4.7. O teste visual adicional usa renderização nativa via Xvfb/Mesa e salva capturas em 1920×1080, 1280×720 e 360×640, nos dois temas, junto aos logs dos testes como artefato do GitHub Actions.

As verificações cobrem limites das barras e dos cards, rolagem com cinco personagens, recursos especiais, preservação das cores, fonte, pausa e movimento das runas, troca de tema e estado do combate. Uma captura de teste não substitui a revisão artística no editor.
