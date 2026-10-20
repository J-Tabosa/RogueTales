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

## Sprites fornecidas

Abra **`scenes/heroes/scarlet.tscn`** para editar a heroína. Ela já é a cena usada nas batalhas, no menu e no laboratório.

1. Selecione o nó **Scarlet** (`AnimatedSprite2D`).
2. No Inspector, clique no recurso **Sprite Frames** para abrir o painel inferior.
3. Escolha `idle`, `walk` ou `attack`. Ajuste **FPS**, ordem dos quadros, duração de cada quadro ou substitua as texturas.
4. Ajuste **Transform > Scale** para mudar o tamanho e **Offset** para mudar o pivô. O ponto de origem fica nos pés.
5. Salve a cena e o recurso. Use **F6** para conferir Scarlet sozinha e **F5** para testar no jogo.

| Animação | Quadros | FPS inicial | Loop |
| --- | --- | --- | --- |
| Idle | 10 | 4 | Sim |
| Caminhada | 6 | 8 | Sim |
| Ataque | 10 | 10 | Não |

As animações ficam salvas em `assets/hero/animations/scarlet_frames.tres`. O script **não** recria os frames, muda os FPS ou substitui a escala configurada na cena ao iniciar.

As folhas originais estão em `assets/hero/`. Elas não têm células uniformes: alguns desenhos ultrapassam a divisão em colunas. Os quadros usam `MeshTexture` nativo da Godot para mostrar apenas o contorno de cada desenho, preservando os PNGs e evitando pedaços dos sprites vizinhos. Todos usam uma área de 720 × 600, com os pés alinhados em (360, 580); a caminhada foi normalizada para o mesmo tamanho visual. A arte ainda pode ter pequenas variações de pose entre quadros.

Para trocar o modelo, substitua os quadros no painel SpriteFrames. Para adicionar outro herói, duplique a cena, torne o recurso SpriteFrames único e aponte `Hero` em `arena.gd` para a nova cena. O intervalo de ataques respeita a duração da animação, inclusive após ajustes de FPS.

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

As sprites foram fornecidas pelo autor do projeto; nenhuma licença adicional sobre essas imagens é presumida.
