# RogueTales: O Último Fio

Idle RPG tático em **Godot 4.7 / GDScript**, com **12 capítulos**, cinco heroínas, recrutamento por requisitos e formação de até três aliadas em duas linhas. A interface é minimalista: campo de batalha amplo, vida/carga junto às unidades e retratos para ativar as ULTs. No PC, os controles ficam na lateral; no celular, na base.

## Jogar

Importe `project.godot` na Godot 4.7 e pressione **F5**. Partidas novas começam só com Scarlet, a Chapeuzinho Vermelho. No mapa, abra um capítulo e entre na batalha automática. Cada run contém dois encontros e um chefe. Entre encontros, escolha uma relíquia ou uma princesa temporária.

A tela **Heróis** reúne níveis, atributos, habilidades e a descrição de classe/ULT. Em **Formação**, adicione até três heroínas e escolha vanguarda ou retaguarda; sempre é necessário manter ao menos uma integrante na frente. Clicar em **Frente → Fundo** move uma heroína para trás quando outra já protege a frente. O posicionamento fica bloqueado durante uma run.

## Classes e alvos

| Classe | Regra |
| --- | --- |
| Vanguarda | Ataca a linha de frente. Alcança a retaguarda quando não resta ninguém vivo na frente. |
| Atiradora | Prioriza a retaguarda e usa a frente quando o fundo cai. |
| Maga | Alcança as duas linhas; prioriza o alvo proporcionalmente mais ferido. Magia ignora 65% da armadura. |
| Assassina | Busca a retaguarda mais ferida e tem 35% de esquiva. |
| Artilheira | Alcança ambas as linhas e prioriza a menor armadura. |

As regras também valem para os inimigos, que agora lutam em esquadrões de até três unidades, com classe, linha, vida, armadura, esquiva e relógio de ataque próprios. A morte de um alvo permite escolher outro elegível, incluindo durante a preparação do golpe. Cada acerto pertence a uma única animação. Mulan e Rapunzel avançam ao alvo; as maçãs de Branca de Neve viajam em linha reta.

## Heroínas e ULTs

| Heroína | Classe | ULT |
| --- | --- | --- |
| Scarlet | Artilheira | **Final explosivo**: 200% de dano a todos e queimadura. |
| Rapunzel | Assassina / suporte | **Coroa de fios**: cura 35% dos PV máximos e concede 20% de escudo às aliadas vivas. |
| Branca de Neve | Atiradora | **Maçã da sentença**: 400% de dano na retaguarda e veneno fortalecido. |
| Mulan | Vanguarda | **Dragão de jade**: 320% de dano à frente e escudo de 35% para si. |
| Ariel | Maga | **Sinfonia abissal**: 160% em todos, cura coletiva de 20% e lentidão por cinco segundos. |

A carga sobe com o tempo de combate, acertos e dano recebido. Ao chegar a 100%, clique no retrato ou use 1–3 no PC. **ULT automática** pode ser alternada na batalha e nas configurações. A reserva impede gastar a mesma carga duas vezes; o efeito ocorre no impacto da animação. Pausa e 2× controlam simulação, dash, carga e efeitos juntos. Gestos de idle e flashes vermelhos de dano continuam ativos.

Cada heroína evolui até o nível 30 com ouro/EXP e possui três habilidades de cinco níveis. Relíquias pertencem à run; melhorias e desbloqueios são permanentes.

## Recrutamento

| Heroína | Desbloqueio permanente |
| --- | --- |
| Branca de Neve | Vencer três runs distintas após convocá-la. |
| Rapunzel | Restaurar 60 PV reais como convidada. A ULT também conta; excesso de cura não conta. |
| Mulan | Acertar oito Terceiros cortes como convidada. |
| Ariel | Vencer dois capítulos diferentes com ela viva na equipe final. |

Convites entram imediatamente na formação e herdam as relíquias. Se os três espaços estiverem ocupados, escolha uma substituição temporária. Recarregar a mesma run não duplica créditos. O progresso está em **Heróis → Ver requisito**.

## Os doze capítulos

1. Bosque dos Sussurros
2. Torre dos Ecos
3. Pomar do Espelho
4. Desfiladeiro de Jade
5. Palácio da Meia-noite
6. Santuário das Marés
7. Forja das Cinzas
8. Biblioteca do Último Fio
9. Pântano dos Reflexos
10. Observatório da Aurora
11. Dunas do Tempo
12. Coração do Tear

Cada capítulo tem introdução, desfecho, chefe e escolha permanente entre esperança (+5 PV por heroína) e coragem (+1 dano). O epílogo e a conquista final exigem os doze capítulos. O capítulo 8 revela as quatro agulhas ocultas e deixa de encerrar a campanha. O diário permite rever os diálogos sem repetir recompensas.

## Idle e salvamento

O baú, liberado após o primeiro capítulo, acumula ouro e EXP por até oito horas com o jogo aberto ou fechado. A patrulha automática repete capítulos concluídos, escolhe o primeiro upgrade oferecido e para na derrota ou ao sair.

Save local em `user://campaign_v1.json`, **schema 4**, com gravação temporária e backup. Saves dos schemas 1–3 preservam ouro, níveis, personagens e capítulos. Um progresso antigo com oito capítulos abre o capítulo 9; a conquista de conclusão passa a exigir os doze. A formação antiga recebe linhas válidas. Checkpoints táticos preservam convidadas, vida, combos, relíquias, ofertas, posições e carga de ULT no início do encontro atual. Não há servidor, login, anúncios ou sincronização entre dispositivos.

**Configurações → Resetar conta deste dispositivo** mostra uma confirmação antes de apagar o progresso. Confirmar substitui tanto o save principal quanto o backup por uma conta nova, apaga o checkpoint e reinicia com a Chapeuzinho. Cancelar preserva tudo. O reset também reinicia preferências e estatísticas; não altera arquivos de outros aplicativos.

## PC e celular

A janela padrão no PC é **1280 × 720**, redimensionável, com tela cheia e controles de teclado. Batalhas mudam para uma composição horizontal com painel de ULTs à direita. As outras telas possuem navegação lateral e resumo da jornada quando há largura suficiente. Em retrato, a interface respeita a área segura e mantém os controles na base. Redimensionar uma batalha não cria outra run nem reinicia sua animação/carga.

| Controle | Ação |
| --- | --- |
| Mouse / toque | Navegação, formação e ULTs |
| 1, 2, 3 | ULT da integrante correspondente |
| Espaço / Esc | Pausar ou retomar o combate |
| A | Alternar ULT automática |
| F11 | Tela cheia / janela |
| Ctrl+B | Ativar/desativar debug; começa desligado |

O laboratório continua acessível só com debug ativado e fora de combates. Música, efeitos e vozes têm volumes independentes. As chamadas são sintéticas. Efeitos/vozes usam pools com limites de repetição. Consulte `assets/audio/COMBAT_AUDIO.md`.

## Exportar para PC

Instale os templates de exportação da **mesma Godot 4.7**. No editor, use **Projeto → Exportar → Windows PC / Linux PC**. Ou, na pasta do projeto:

```sh
mkdir -p build/windows build/linux
godot --headless --path . --export-release "Windows PC" build/windows/RogueTales.exe
godot --headless --path . --export-release "Linux PC" build/linux/RogueTales.x86_64
```

No Windows, crie as duas pastas pelo Explorador ou com `New-Item -ItemType Directory -Force build/windows, build/linux` no PowerShell. O executável incorpora o pacote do jogo; não exige instalar Godot para jogar. Não há assinatura digital ou instalador. A exportação Android requer SDK/templates e configuração de assinatura; nenhum APK está incluído.

## Arte e desempenho

A arena de ruínas foi gerada com a ferramenta integrada ImageGen, preservada em `assets/ui/ruins_arena.png`; o prompt completo está em `assets/ui/ruins_arena_prompt.json`. UI, texto, botões e barras são nativos da Godot. As artes de madeira anteriores continuam disponíveis, mas as telas principais usam cartões lisos e decoração reduzida.

Oito folhas de monstros editáveis estão em `scenes/enemies/`. Os quatro novos capítulos reutilizam as folhas dos temas de pomar, torre, palácio e biblioteca; classes/atributos e esquadrões variam. Os fundos e sprites não mudam a cada capítulo para doze artes exclusivas. Procedência em `assets/*/ART_NOTES.md`.

Texturas, retratos, estilos e cenas usam cache; a arena tem até seis unidades e evita instanciar recursos por quadro. O fundo é um TextureRect retido. Texturas usam filtragem linear/mipmaps e limites de importação. Limite de 30/60 FPS e movimento reduzido estão nas configurações; suspender salva, pausa áudio e limita processamento em segundo plano. Medições headless verificam lógica, não desempenho em celulares reais.

## Código e verificação

- `scripts/interface.gd`: interface minimalista, layouts PC/celular, formação, ULTs e reset.
- `scripts/main.gd`: navegação, história, progressão e orquestração das batalhas.
- `scripts/tactics.gd`: classes, alvos, esquadrões, esquiva, status e ULTs.
- `scripts/tactical_arena.gd`: posicionamento, animações, dash, projéteis e barras junto às unidades.
- `scripts/run.gd`, `campaign.gd`, `catalog.gd`: run, persistência e conteúdo.
- `export_presets.cfg`: exports Windows/Linux x86-64.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/tactics.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/idle.gd
godot --headless --path . --script tests/recruitment.gd
godot --headless --path . --script tests/presentation.gd
godot --headless --path . --script tests/combat_presentation.gd
```

As suítes usam saves isolados. Cobrem campanha completa de doze capítulos com renda obtida no jogo, targeting/fallback por classe, esquiva, cinco ULTs distintas, consumo único, pausa, mudanças de proporção durante o combate, migração, reset/cancelamento/backup, desbloqueios, derrota, patrulha e epílogo. Capturas gráficas verificam telas de PC e retrato. O executável Linux é iniciado no ambiente de validação; o export Windows é gerado e sua estrutura é verificada, mas não é executado neste ambiente Linux.
