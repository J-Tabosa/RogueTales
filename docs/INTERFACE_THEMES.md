# Interface — temas Escuro e Claro

A mudança é visual e mantém a navegação, a formação, os tempos e as regras do jogo. Alterne em **Configurações → Tema** ou em **Pausa → Tema**. A escolha é aplicada à tela aberta, sem reconstruir a run, e salva como `ui_theme` no mesmo save. Saves anteriores usam o tema Escuro.

## Tokens de cor

A única fonte de valores é `TaleTheme.PALETTES`, em `scripts/ui_theme.gd`. Use `TaleTheme.c("token", alpha)` nos componentes. `GOLD`, `MUTED` e `INK` são acessores de compatibilidade que consultam os tokens atuais, sem guardar uma cópia da paleta.

| Token | Escuro | Claro | Uso |
|---|---|---|---|
| `background` | `#07253f` | `#e5d0a1` | Fundo principal e véus |
| `surface` | `#0b304b` | `#ddbd82` | Painel base |
| `surface_top` | `#123e58` | `#e8cea0` | Início do gradiente dos painéis |
| `secondary` | `#3c95a9` | `#ddbd82` | Controles secundários e escudos |
| `button` | `#17465f` | `#ddbd82` | Botão em repouso |
| `hover` | `#205971` | `#ead3a9` | Botão sob mouse |
| `pressed` | `#092e49` | `#ceb078` | Botão pressionado |
| `border` | `#3c95a9` | `#99723c` | Borda externa e divisórias |
| `accent` | `#aceaf1` | `#684921` | Ícones e bordas de seleção/foco |
| `text` | `#ffffff` | `#3b2414` | Texto principal |
| `muted` | `#d2edf2` | `#5b3d23` | Texto auxiliar |
| `disabled` | `#97b6c3` | `#735434` | Texto de controle desativado |
| `ornament` | `#aceaf1` | `#a27632` | Filigranas, rosáceas e molduras |
| `shadow` | `#031524` | `#8c693c` | Sombra e profundidade |
| `track` | `#041c30` | `#c3a36d` | Trilho de barras e sliders |
| `progress` | `#aceaf1` | `#684921` | Preenchimento de progresso |
| `selection` | `#3c95a9` | `#c4a069` | Seleção de texto |
| `physical` | `#ffffff` | `#3b2414` | Valor de dano físico, com rótulo explícito |
| `magical` | `#aceaf1` | `#684921` | Valor de dano mágico, com rótulo explícito |
| `health_full` | `#aceaf1` | `#684921` | Vida acima de 80% |
| `health_high` | `#8fd9e4` | `#78572c` | Vida acima de 60% |
| `health_half` | `#71c4d3` | `#886536` | Vida acima de 40% |
| `health_low` | `#55adbf` | `#987440` | Vida acima de 20% |
| `health_critical` | `#3c95a9` | `#a7834d` | Vida em 20% ou menos |

Os preenchimentos de botões escuros são derivados mais escuros do azul médio para garantir contraste de texto pequeno. Todos os estados ativos de texto são testados com contraste mínimo de **4,5:1**. O dourado ornamental do tema Claro foi escurecido para se distinguir do papel. Raridades usam `TaleTheme.rarity()` com variações tonais; seus nomes e metadados continuam explícitos. Os cinco níveis de vida também seguem a paleta escolhida. Artes de personagens, itens, cenários e efeitos de combate preservam suas cores originais.

## Tipografia e acabamento

- Títulos: **Cinzel**. Texto corrido, números e botões: **Lora**. Ambas incluem os acentos portugueses e licença SIL OFL em `assets/fonts/renaissance/`.
- Painéis e botões têm gradiente discreto, borda dupla e brilho de relevo. Hover, foco de teclado e seleção têm borda destacada.
- Fundos e painéis amplos recebem textura e rosácea com baixa opacidade. Filigranas maiores ficam fora das áreas de texto; painéis de conteúdo automático usam apenas a moldura fina.
- Decorações ignoram mouse/toque, não participam dos containers e não alteram as dimensões das telas. Os botões `i` mantêm formato quadrado e margem de 5.

## Assets transparentes para substituir

Pasta: **`assets/ui/themes/shared/`**. Já existem SVGs provisórios transparentes utilizáveis. Para usar suas artes, substitua o SVG correspondente ou adicione um PNG **com o mesmo nome base**; PNG tem prioridade. A importação e o cache são feitos uma vez por execução.

Produza as peças em **branco monocromático sobre transparência**, sem fundo, texto ou cor fixa. O jogo as colore pelo token `ornament` de cada tema. Isso permite reutilizar cada peça nos dois temas.

| Nome esperado | Tamanho sugerido | Uso e margens |
|---|---|---|
| `panel_frame.png` / `.svg` | 384 × 384 px | Moldura de painéis e janelas. Centro transparente. 9-slice: **72 px por lado** (18,75%); cantos ficam com 18 px lógicos. A peça SVG provisória usa 96 × 96 e margens 18. |
| `button_frame.png` / `.svg` | 384 × 384 px | Contorno de botões e cartões clicáveis. Mesmo 9-slice, centro transparente; ornamentos contidos na faixa externa. |
| `corner_filigrane.png` / `.svg` | 256 × 256 px | Canto superior esquerdo. Os outros três são espelhados automaticamente. Sem margem transparente externa. Exibido em até 27 px lógicos. |
| `section_divider.png` / `.svg` | 1280 × 64 px | Divisor horizontal com rosácea/flor no centro, sob os títulos. Exibição proporcional, centro óptico no meio da imagem. |
| `mandala_watermark.png` / `.svg` | 1024 × 1024 px | Rosácea circular nos fundos e painéis grandes. Traços leves, sem letras. Opacidade final de 3,5–4,5%. |
| `surface_texture.png` / `.svg` | 256 × 256 px | Textura discreta de papel/gravura, repetível sem emenda nos quatro lados. Opacidade de 3,5%. |

Não pinte o fundo dos arquivos de moldura: o gradiente é feito pelo componente para escalar sem distorção. Os trechos de borda devem permitir repetição/estiramento sem elementos narrativos. Mantenha filigranas dentro da faixa de canto para não invadir textos.

## Implementação e verificação

- `scripts/ui_theme.gd`: tokens, Theme nativo Godot, estados e aplicação aos controles criados dinamicamente; atualização por eventos, sem percorrer a árvore a cada frame.
- `scripts/theme_surface.gd`: gradientes, marca d'água, textura e renderização das peças com 9-slice normalizado pela resolução da imagem.
- `scripts/ui_skin.gd`: integração dos componentes existentes e divisores.
- Camadas de shaders do cenário/combate são excluídas da aplicação do tema. As fichas, equipamentos, conquistas, diário, menus, carregamento e pausa usam a mesma camada visual.
- `tests/ui_themes.gd`: persistência/migração, contraste, troca na ficha aberta sem alterar estado/vida/arte/escala, telas novas após a troca, pausa, PC e celular. Gera capturas reais quando há display disponível.

```sh
godot --headless --path . --script tests/ui_themes.gd
# Capturas reais, com um display disponível:
godot --path . --script tests/ui_themes.gd -- /tmp/rogue-tales-themes
```

Os testes anteriores de equipamentos e bônus foram atualizados apenas nas expectativas de fonte, estilo de borda e paleta, que mudaram neste redesign.
