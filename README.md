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

Os arquivos originais estão em `assets/hero/`. A leitura é por linhas, da esquerda para a direita:

| Animação | Arquivo | Grade | Quadros | FPS |
| --- | --- | --- | --- | --- |
| Idle | idle.png | 5 × 2 | 10 | 8 |
| Caminhada | walk.png | 3 × 2 | 6 | 9 |
| Ataque | ataack.png | 5 × 2 | 10 | 10 |

`hero.gd` monta um `SpriteFrames` com `AtlasTexture`; não é necessário recortar as imagens. As folhas de idle e ataque medem 1983 × 793, por isso as regiões usam coordenadas fracionárias. A arte possui deslocamentos e variações de pose entre quadros: o laboratório permite avaliar isso visualmente. Para arte definitiva, recomenda-se exportar células com dimensões inteiras, margens e pivôs consistentes.

## Onde alterar

- `scripts/run.gd`: vida, dano, inimigos, fases e relíquias.
- `scripts/main.gd`: telas e fluxo de combate.
- `scripts/hero.gd`: grades, FPS e escala das animações.
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
