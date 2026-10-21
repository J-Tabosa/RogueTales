# RogueTales

Base de idle RPG com elementos roguelike, em **Godot 4.7 / GDScript**.

## Abrir

1. Baixe ou clone este repositório.
2. Na Godot 4.7, importe `project.godot`.
3. Pressione **F6** na cena principal ou **F5** para jogar.

## Protótipo

- Tela inicial e interface vertical 540 × 960, com mouse ou toque.
- Combate automático, bombas animadas, dano crítico e vida.
- Três fases: Bosque dos Sussurros, Ruínas da Lua e Caldeira Carmesim.
- Cada fase tem dois encontros e um chefe provisório.
- Escolha uma entre três relíquias sorteadas após as fases 1 e 2.
- Relíquias duram uma expedição; ao perder ou vencer, é possível recomeçar.
- Pausa, velocidade 1×/2×, vitória, derrota e retorno ao menu.
- Recorde e vitórias salvos localmente em `user://progress.cfg`.
- Laboratório de sprites: idle, caminhada e ataque com ajuste de velocidade.

## Heroínas

Na tela inicial, escolha **Scarlet** ou **Rapunzel** antes de começar. A seleção também fica disponível no laboratório de sprites.

| Heroína | Cena editável | Ataque |
| --- | --- | --- |
| Scarlet | `scenes/heroes/scarlet.tscn` | Bomba com trajetória e explosão |
| Rapunzel | `scenes/heroes/rapunzel.tscn` | Chicote de cabelo dourado com impacto próprio |

Rapunzel tem idle com quatro quadros, piscada eventual, caminhada com oito quadros e ataque com oito quadros. A arte foi gerada a partir da referência fornecida, com vestido roxo, botas pretas e cabelo dourado longo; os PNGs ficam em `assets/rapunzel/` e as animações editáveis em `rapunzel_frames.tres`. Os recortes nativos isolam cada desenho e alinham os pés, sem modificar os PNGs.

Abra a cena da Rapunzel e ajuste o SpriteFrames, escala, offset e propriedades **Heroína** no Inspector. `Impact Ratio` determina em que fração do ataque o golpe acerta; o intervalo respeita a duração da animação. O mesmo sistema de idle com pausas, piscadas e balanço é compartilhado pelas duas heroínas. O ataque de cabelo causa dano uma única vez por animação, sem criar uma bomba.

## Sprites fornecidas

Abra **`scenes/heroes/scarlet.tscn`** para editar a heroína. Ela já é a cena usada nas batalhas, no menu e no laboratório.

1. Selecione o nó **Scarlet** (`AnimatedSprite2D`).
2. No Inspector, clique no recurso **Sprite Frames** para abrir o painel inferior.
3. Escolha `idle`, `walk` ou `attack`. Ajuste **FPS**, ordem dos quadros, duração de cada quadro ou substitua as texturas.
4. Ajuste **Transform > Scale** para mudar o tamanho e **Offset** para mudar o pivô. O ponto de origem fica nos pés.
5. Salve a cena e o recurso. Use **F6** para conferir Scarlet sozinha e **F5** para testar no jogo.

| Animação | Quadros | FPS inicial | Loop |
| --- | --- | --- | --- |
| Idle / balanço eventual | 4 | 2 | Não |
| Piscada (`idle_blink`) | 4 | 12 | Não |
| Caminhada | 16 | 12 | Sim |
| Ataque | 10 | 10 | Não |

As animações ficam salvas em `assets/hero/animations/scarlet_frames.tres`. O script **não** recria os frames, muda os FPS ou substitui a escala configurada na cena ao iniciar.

A caminhada usa **`assets/hero/walk_16.png`**, a nova folha de 2048 × 2048 com 16 quadros em 4 × 4. Cada célula mede 512 × 512 e é lida da esquerda para a direita, de cima para baixo. Todos os quadros mantêm o mesmo pivô; o movimento natural dos pés não desloca o corpo inteiro.

O idle usa **quatro quadros**, a 2 FPS, e não fica repetindo em loop. O comportamento em `hero.gd` alterna entre:

- **Parada:** segura o primeiro quadro imóvel por 4 a 8 segundos, sem respiração ou balanço contínuo.
- **Piscando:** executa `idle_blink` uma vez, usando os desenhos de olhos abertos, semicerrados e fechados da folha original; dura cerca de 0,33 s.
- **Balançando:** executa os quatro quadros de idle uma vez, com um pequeno movimento de capa e tronco; dura 2 s nos FPS iniciais.

Após cada gesto, volta à pose parada e sorteia uma nova espera. A chance inicial é de 70% para piscada e 30% para balanço. Andar ou atacar interrompe o gesto imediatamente. No Inspector da Scarlet, ajuste **Idle — pausas e variações**: intervalos mínimo/máximo, probabilidade de piscar, intensidade do balanço e ativação das variações. Os FPS e a duração de cada quadro continuam editáveis no SpriteFrames.

A caminhada tem movimento discreto dos ombros e do tronco, sincronizado com `frame + frame_progress` dos 16 quadros. O shader usa uma malha subdividida para movimentar a parte superior sem deformar as pernas. Em **Walk — movimento dos ombros**, ajuste `Walk Shoulders Enabled`, `Shoulder Swing` e `Shoulder Roll`. Pausa e velocidade 1×/2× respeitam tanto os gestos de idle quanto o movimento da caminhada.

As folhas originais estão em `assets/hero/`. Elas não têm células uniformes: alguns desenhos ultrapassam a divisão em colunas. Os quadros usam `MeshTexture` nativo da Godot para mostrar apenas o contorno de cada desenho, preservando os PNGs e evitando pedaços dos sprites vizinhos. Todos usam uma área de 720 × 600, com os pés alinhados em (360, 580); a caminhada foi normalizada para o mesmo tamanho visual, com um pivô fixo em todas as células. A arte ainda pode ter pequenas variações de pose entre quadros.

Para trocar o modelo, substitua os quadros no painel SpriteFrames. Para adicionar outro herói, duplique uma cena, torne o recurso SpriteFrames único e adicione a cena a `HERO_SCENES` em `main.gd`. O intervalo de ataques respeita a duração da animação, inclusive após ajustes de FPS.

## Onde alterar

- `scripts/run.gd`: vida, dano, inimigos, fases e relíquias.
- `scripts/main.gd`: telas e fluxo de combate.
- `scenes/heroes/scarlet.tscn`: modelo, escala e origem da heroína.
- `assets/hero/animations/scarlet_frames.tres`: quadros e FPS editáveis.
- `scripts/hero.gd`: reprodução e retorno do ataque para idle.
- `scripts/arena.gd`: cenários e inimigos provisórios desenhados por código, trajetória da bomba e efeitos.
- `scenes/main.tscn`: ponto de entrada.

O ataque causa dano no impacto da bomba. A caminhada aparece entre encontros. Idle aparece no menu e nos intervalos dos ataques. Para trocar inimigos por sprites, substitua `draw_enemy()` em `arena.gd` por um `AnimatedSprite2D`.

## Verificação

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/smoke.gd
```

O teste cobre contagem de quadros, pausa, velocidade, três fases, escolhas de relíquias, vitória, derrota e retorno ao menu.

Esta é uma base pequena para testar gameplay e animações. Não inclui progresso offline, loja, equipamento, áudio ou APK exportado. Android requer os templates de exportação e configuração do SDK na Godot.

As sprites da Scarlet foram fornecidas pelo autor do projeto. As sprites da Rapunzel foram geradas com ImageGen a partir da referência fornecida; os detalhes de geração estão em `assets/rapunzel/ART_NOTES.md`. Nenhuma licença adicional sobre referências ou marcas é presumida.
