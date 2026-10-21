# Monstros por capítulo

Oito spritesheets RGBA originais geradas com a ferramenta integrada `image_gen`, uma por capítulo. Cada sheet contém 16 quadros em grade 4 × 4: `idle`, `attack`, `boss_idle`, `boss_attack` (uma linha por animação). Os PNGs foram copiados sem retoques; `PROMPTS.json` registra os prompts finais.

1. Floresta: lobo de tinta e Devorador de Trilhas.
2. Torre: marionete e Guardiã da Janela.
3. Pomar: criatura de maçã/espinhos e espelho vivo.
4. Neve: soldado e general de jade.
5. Palácio: guarda de vidro e relógio encantado.
6. Praia: caranguejo e leviatã de coral.
7. Forja: diabrete de carvão e ferreiro de obsidiana.
8. Biblioteca: livro assombrado e Costureira.

Abra `scenes/enemies/chapter_01.tscn` até `chapter_08.tscn` para editar modelos e FPS no SpriteFrames. `regular_height` e `boss_height` controlam a altura de exibição. Os quadros usam regiões nativas AtlasTexture e margens para manter uma tela fixa de 400 × 400; não criamos cópias recortadas dos PNGs. Os separadores buscam espaços transparentes próximos à grade, evitando fragmentos da linha vizinha. `tools/build_enemy_frames.py` reconstrói os recursos a partir das sheets; requer Pillow apenas para analisar o alfa.

O relógio da arena consulta as durações editadas dos quadros, sincroniza a preparação do ataque com o golpe da simulação e respeita pausa e velocidade. O cache guarda no máximo duas cenas de capítulos; a tela de loading aquece o próximo recurso após apresentar a interface. Texturas com mipmaps e filtragem linear; uma única AnimatedSprite2D para o inimigo atual.
