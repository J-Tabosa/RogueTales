# RogueTales: O Último Fio

Roguelite de combate por esquadrões em **Godot 4.7 / GDScript**. Uma run atravessa **12 fases**, com 12 protagonistas, builds temporárias, encontros raros de companheiros e equipes de até três integrantes em três linhas. Interface mobile, galeria de silhuetas, habilidades individuais, ataques automáticos por intervalo, passivas com recarga e ULTs. No PC, os controles ficam na lateral; no celular, na base.

## Jogar

Importe `project.godot` na Godot 4.7 e pressione **F5**. Escolha **Nova run**, um protagonista já revelado e uma bênção inicial. As **12 fases formam uma única expedição**, com chefes nas fases **4, 8 e 12**. Vida, energia, equipe e build continuam de uma fase à próxima. O combate é automático por iniciativa; ULTs também podem ser usadas manualmente.

Após vencer, escolha uma de três melhorias. Há **25% de chance por tela** de uma carta ser um convite temporário, inclusive na primeira recompensa. Não existe convite garantido. O sorteio é da tela inteira, não de cada uma das três cartas. Recarregar não altera as opções. O grupo comporta três integrantes; com a equipe cheia, um convite exige uma substituição.

Entre fases, escolha cartas de rota: combate comum, elite, fogueira, mercador ou evento. Elites têm +35% de PV e +15% de dano; ao vencê-las, ganhe +25 ouro e +10% de dano na run. A fogueira custa 18 ouro e recupera a equipe; o mercador vende suprimentos e relíquias, com compras salvas individualmente. A página proibida troca PV máximos por dano. Chefes têm uma rota obrigatória.

No modo Conto, derrota, abandono ou vitória na fase 12 encerram a tentativa. No Infinito, a fase 12 abre uma nova volta. **Ouro da run, relíquias, transformações e convidados são temporários**. Desbloqueios, feitos, recordes e memórias são permanentes. As memórias abrem novas bênçãos iniciais; as três primeiras estão disponíveis desde o começo. Bônus de níveis, treinamento e escolhas da campanha antiga não entram nos atributos de novas runs. Uma build forte pode vencer sem receber um convite.

A coleção usa **faixas verticais com artes grandes e pergaminho**: carrossel no celular e uma faixa larga no PC. Personagens bloqueados são silhuetas pretas, com nome **???**, classe e habilidades ocultas. Um convite permite experimentar o viajante no combate, mas a ficha só é revelada com o desbloqueio permanente. Só um protagonista começa a próxima run.

## Classes e alvos

| Classe | Regra |
| --- | --- |
| Vanguarda | Fica na frente. Ataca a linha de frente. Avança ao meio e depois à retaguarda quando as linhas anteriores caem. |
| Atiradora | Fica atrás. Prioriza a retaguarda e usa a frente quando o fundo cai. |
| Maga | Fica atrás. Alcança as três linhas; prioriza o alvo proporcionalmente mais ferido. Magia ignora 65% da armadura. |
| Assassina | Fica no meio. Busca a retaguarda mais ferida e tem 35% de esquiva. |
| Artilheira | Fica atrás. Alcança todas as linhas e prioriza a menor armadura. |

As regras também valem para os inimigos, que agora lutam em esquadrões de até três unidades, com classe, linha, vida, armadura, esquiva e relógio de ataque próprios. A morte de um alvo permite escolher outro elegível, incluindo durante a preparação do golpe. Cada acerto pertence a uma única animação. Mulan e Rapunzel avançam ao alvo; as maçãs de Branca de Neve viajam em linha reta.

## Combate idle e feedback

A referência de Unicorn Overlord é a apresentação da arena: equipes em lados opostos, personagens avançando para golpear e projéteis atravessando o campo. Nas runs, o combate é automático por intervalo individual, sem AP/PP na interface. Uma animação completa sua antecipação, impacto e retorno antes da próxima ação. Aliados e inimigos têm a mesma oportunidade de agir; a ordem prioriza quem está esperando há mais tempo.

- **Ritmo:** caminhada de 2,8 s até o encontro, entrada dos inimigos, aviso de 1,15 s e início da luta. Golpes duram pelo menos 1,12 s, ataques inimigos 1,3 s, com recuperação entre ações.
- **ULT:** faixa de 62 px no canto, com nome e personagem; preparação de 0,55 s e efeito ilustrado de seis quadros no impacto. O aviso não cobre a arena. As doze ULTs usam folhas geradas com o criador de imagens: cortes, ondas, cartas, flechas, fogo e fios. Alice abre um leque dos quatro naipes e espalha as cartas até cada alvo real. A abertura mantém a duração em 1×/2×. ULTs gastam 100 mana; comandos durante uma ação ficam na fila.
- **Passivas:** avisos laterais com personagem, habilidade e efeito. As reações recarregam 6 s depois de consumidas; sinergias compartilham esse recurso interno. Não exigem configuração tática do jogador.
- **Vida e mana:** números e barras nos cartões laterais do PC e inferiores do celular, além dos PV sobre as unidades. Escudo aparece numericamente; cura, dano, guarda e esquiva aparecem no campo.
- **Histórico:** quatro mensagens recentes no canto e até 150 entradas por encontro. O botão Histórico pausa para ler ataques, alvos reais atingidos, valores, cura, escudo, ULT e passivas. Não há previsão de alvo inimigo na tela.
- **Fim de encontro:** o golpe fatal e seu retorno terminam, a vitória fica 1,2 s e a recompensa abre como pop-up sobre a arena. Após escolher, o grupo caminha até a encruzilhada, escolhe uma rota no pop-up e segue até o próximo encontro. Derrotas também aguardam o golpe terminar.
- **Ameaça:** menos crescimento de PV, dano inimigo mais alto, ataques fortes por classe a cada terceiro movimento e dano mínimo de 28% antes de escudos. Após 28 s, a pressão aumenta gradualmente o dano inimigo até 3×, impedindo sustento infinito por cura. A pressão fica visível no HUD. Pausa, 2× e movimento reduzido são respeitados.

Os checkpoints legados mantêm suas rodadas anteriores para poderem ser concluídos.

## Formação, escala e biomas

A formação das runs segue a classe e corrige checkpoints antigos: **vanguarda à frente, assassinos no meio, magos/atiradores/artilheira atrás**. Personagens da mesma linha ficam lado a lado, com a mesma coordenada de profundidade. Humanos têm a mesma altura visível, medida pela arte em vez do tamanho do arquivo. Gato de Botas e Vendedora têm metade dessa altura. Os pés ficam ancorados durante ataque, caminhada e mudança de resolução.

Oito biomas cobrem os doze atos: bosque (1/3), castelo (2/5), gelo/jade (4/10), marés (6), fogo (7), biblioteca/tear (8/12), pântano (9) e dunas (11). Cada um tem cenário próprio e **seis inimigos distintos**, totalizando 48 identidades com quatro poses de ataque por identidade. Encontros sorteiam variantes sem repetir a mesma dentro do grupo. Melee avança com dash e retorna; magos conjuram em área; assassinos procuram a retaguarda, com fallback pelo meio e frente.

As artes foram feitas com **image_gen integrado**, usando Scarlet e Alice como referência de desenho, e empacotadas pelo Godot em WebP com alpha. Cenários e inimigos em `assets/biomes/`; ULTs em `assets/effects/`. Prompts completos em `assets/BIOME_ART_PROMPTS.json`. `tools/detect_biome_frames.py` identifica as regiões pela transparência e cria metadados de cada pose; `tools/prepare_biome_art.gd` usa esses metadados para empacotar as imagens no Godot, preservando a arte mesmo quando a folha não tem linhas uniformes. As imagens não dependem de caminhos temporários em runtime.

## Pontuação e recorde

Cada encontro vencido concede 100 pontos, mais 300 por chefe, 150 por elite, 25 por aliado sobrevivente, até 120 por tempo (`max(0, 120 - 2 × segundos de combate)`) e 100 se ninguém perdeu PV. Escudos podem preservar esse bônus; dano de status também é contado. A pontuação aparece na luta, na recompensa e no resultado. O maior total fica no perfil e na tela inicial, inclusive quando a tentativa termina em derrota. A continuação infinita mantém os pontos; uma nova run começa do zero. Saves antigos carregam com zero pontos e mantêm o restante do progresso.

## Sinergias da equipe

As três duplas escolhidas têm efeitos concretos e nomes exibidos no impacto. Exigem os dois personagens vivos, um gatilho e a passiva do parceiro pronta, com recarga de **6 s**. Não criam ações recursivas ou ataques simultâneos. A build lista os vínculos ativos; as descobertas são guardadas ao encerrar a run.

| Dupla | Gatilho e efeito |
| --- | --- |
| João + Maria | Maria acerta uma presa marcada; João dispara um virote adicional de 80% e renova o veneno. |
| Scarlet + Vendedora | Uma acerta o fogo aplicado pela outra; a parceira detona duas parcelas de queimadura. |
| Mulan + Peter | Um golpe com sombras recebe um corte adicional de Mulan na vanguarda. |

## Chefes

| Fase | Mecânica |
| --- | --- |
| 4: General Sem Nome | O estandarte reduz 40% do dano recebido pelo General. Destruí-lo interrompe sua próxima ação. Alterna preparação e corte na frente. |
| 8: Guardiã do Índice | Reimprime a forma da última ULT usada **neste combate**, usando seu próprio poder. Pode copiar cura e escudo; a cópia é consumida uma vez. Uma ULT nova usada durante a preparação fica para a ação seguinte. |
| 12: Costureira dos Finais | Dois fios selam ativas de personagens da equipe. Os fios ligados ao personagem são expostos a qualquer classe. Destruí-los liberta a ativa; ataques básicos e ULTs funcionam durante o selo. A chefe drena energia enquanto os fios sustentam sua cura. |

Os inimigos animam seus golpes e o histórico registra o resultado real. Ataques em área mostram os resultados de cada alvo, incluindo proteção, esquiva e cura. Os fios têm ligações visuais; personagens afetados recebem a indicação de ativa selada no cartão.

## Eventos da companhia

Seis encontros ligados às duplas podem aparecer como carta de rota. Funcionam também com apenas um dos personagens: só quem está vivo no grupo fala. Há duas escolhas comuns e uma alternativa exclusiva que exige os dois vivos. Ela pode conceder transformações, proteção, cura ou energia. A alternativa de uma dupla ausente não revela nomes de personagens bloqueados. O evento, as opções e sua conclusão são salvos; voltar ao início não duplica recompensas. Cada evento aparece uma vez por volta de 12 fases.

## Modo infinito

Vença as 12 fases da run e escolha **Continuar no infinito** na vitória. Essa opção não aparece na preparação. Equipe, vida, mana, habilidades e build seguem para a fase 13. A vitória normal já foi salva; a continuação usa um novo identificador e não paga novamente os feitos e memórias das primeiras 12 fases. Checkpoints infinitos de versões anteriores continuam válidos. Temas e mecânicas de chefes se repetem, com chefes a cada quatro fases e força crescente pela profundidade total. A curva continua finita em profundidades altas.

As relíquias genéricas continuam disponíveis, com acúmulos sem limite de três e ganhos decrescentes de dano, armadura, drenagem e crítico. Habilidades exclusivas continuam únicas. Ofertas deixam de incluir crítico/velocidade já no teto. Os valores marginais reais aparecem na carta. O save usa um resumo compacto dos atributos, contagens e modificadores para novos convidados, preservando a ordem das adições de PV e maldições sem guardar uma lista que cresça a cada fase.

O recorde infinito é separado das vitórias do Conto. Cada novo marco pessoal de 12 páginas acrescenta 20 memórias à recompensa terminal. Derrota ou abandono encerram a tentativa e resolvem feitos e marcos uma única vez.

## Personagens e ULTs

| Personagem | Classe | ULT |
| --- | --- | --- |
| Scarlet | Artilheira | **Final explosivo**: 200% de dano a todos e queimadura. |
| Rapunzel | Assassina / suporte | **Coroa de fios**: cura 35% dos PV máximos e concede 20% de escudo às aliadas vivas. |
| Branca de Neve | Atiradora | **Maçã da sentença**: 400% de dano na retaguarda e veneno fortalecido. |
| Mulan | Vanguarda | **Dragão de jade**: 320% de dano à frente e escudo de 35% para si. |
| Ariel | Maga | **Sinfonia abissal**: 160% em todos, cura coletiva de 20% e lentidão por cinco segundos. |
| João | Assassino | **Caçada cruzada**: rajada de 420% na retaguarda. |
| Maria | Assassina | **Receita da bruxa**: 280% na retaguarda e veneno fortalecido por 6 s. |
| Alice | Maga | **Cortejo dos naipes**: magia de 200% em todos. |
| Gato de Botas | Vanguarda | **Nove vidas, um corte**: 360% na frente e escudo de 25% para si. |
| Vendedora de Fósforos | Atiradora | **Último fósforo**: 400% na retaguarda e queimadura por 5 s. |
| Peter Pan | Assassino | **Passo do outro lado**: 300% na retaguarda e +25 pontos de esquiva por 5 s. |
| Aladin | Mago | **Três desejos**: 200% em todos, cura e escudo coletivos de 15%. |

A carga sobe com o tempo de combate, acertos e dano recebido. Ao chegar a 100%, clique no retrato ou use 1–3 no PC. **ULT automática** pode ser alternada na batalha e nas configurações. A reserva impede gastar a mesma carga duas vezes; o efeito ocorre no impacto da animação. Pausa e 2× controlam simulação, dash, carga e efeitos juntos. Gestos de idle e flashes vermelhos de dano continuam ativos.

Cada personagem possui **uma ativa automática, uma passiva com recarga e sua ULT**, além de **três transformações exclusivas** oferecidas durante a run (36 opções no total). Exemplos: a pólvora de Scarlet explode e pode proteger a equipe; Maria consome veneno para se curar; Alice alterna quatro naipes; Peter cria e consome sombras; Gato alterna carga e corte; Aladin alterna desejos. As descrições e opções estão em `scripts/expedition_content.gd`; os efeitos reais, em `scripts/hero_abilities.gd`.

Relíquias genéricas podem acumular até três cópias. Uma transformação exclusiva só pode ser escolhida uma vez por personagem na tentativa. O histórico de melhorias e eventos é reaplicado na mesma ordem ao retomar, incluindo eventos que multiplicam PV máximos depois de uma relíquia que soma PV.

## Recrutamento

| Personagem | Desbloqueio permanente |
| --- | --- |
| Branca de Neve | Vencer três chefes como convidada, acumulados entre runs. |
| Rapunzel | Restaurar 60 PV reais como convidada. A ULT também conta; excesso de cura não conta. |
| Mulan | Acertar oito Terceiros cortes como convidada. |
| Ariel | Vencer dois chefes de fases diferentes com ela viva como convidada. |

Os sete novos personagens exigem **20 ataques básicos acertados como convidados**, acumulados entre runs. João e Maria são unidades separadas.

Convites entram imediatamente na formação e herdam as relíquias. Se os três espaços estiverem ocupados, escolha uma substituição temporária. Recarregar a mesma run não duplica créditos. A coleção só revela a ficha após o desbloqueio. Feitos de convidados contam no encerramento, mesmo se a run terminar depois em derrota. Saves de capítulos antigos ainda podem terminar pelo fluxo compatível da campanha anterior.

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

As doze áreas fornecem os temas das fases. O diário permite rever os diálogos das páginas já concluídas sem repetir recompensas. Introduções, desfechos e escolhas de esperança/coragem da campanha anterior continuam disponíveis para checkpoints legados; os bônus dessas escolhas não alteram os atributos das novas runs.

## Salvamento e compatibilidade

Save local em `user://campaign_v1.json`, **schema 6**, com gravação temporária e backup. Contas dos schemas 1–5 preservam personagens, ouro, níveis, capítulos e checkpoints antigos. Estes checkpoints continuam pelo fluxo anterior; novas partidas começam pela expedição de 12 fases. O baú e a patrulha da campanha antiga não aparecem na navegação de novas runs.

Sair durante um combate retoma no **início daquele encontro**, preservando a mesma tentativa. Nas recompensas, rotas e loja, retoma a tela correspondente com as mesmas opções, histórico, compras, vida, energia, convidados, estados das habilidades e estado do gerador aleatório. Os IDs das runs impedem receber duas vezes feitos ou recompensas terminais.

**Configurações → Resetar conta deste dispositivo** pede confirmação e substitui save e backup por uma conta nova. Cancelar preserva tudo. Não há servidor, login ou sincronização entre dispositivos.

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

O laboratório de animações fica nas configurações e só mostra personagens já revelados. Música, efeitos e vozes têm volumes independentes. As chamadas são sintéticas. Efeitos/vozes usam pools com limites de repetição. Consulte `assets/audio/COMBAT_AUDIO.md`.

## Exportar para PC

Instale os templates de exportação da **mesma Godot 4.7**. No editor, use **Projeto → Exportar → Windows PC / Linux PC**. Ou, na pasta do projeto:

```sh
mkdir -p build/windows build/linux
godot --headless --path . --export-release "Windows PC" build/windows/RogueTales.exe
godot --headless --path . --export-release "Linux PC" build/linux/RogueTales.x86_64
```

No Windows, crie as duas pastas pelo Explorador ou com `New-Item -ItemType Directory -Force build/windows, build/linux` no PowerShell. O executável incorpora o pacote do jogo; não exige instalar Godot para jogar. Não há assinatura digital ou instalador. A exportação Android requer SDK/templates e configuração de assinatura; nenhum APK está incluído.

## Animações dos novos personagens

João, Maria, Alice, Gato de Botas, Vendedora de Fósforos, Peter Pan e Aladin possuem a mesma contagem da Scarlet, com poses próprias:

| Animação | Quadros | FPS |
| --- | --- | --- |
| `idle` | 4 | 2 |
| `idle_blink` | 4 | 12 |
| `walk` | 16 | 12 |
| `attack` | 10 | 10 |

São **34 quadros por personagem, 238 novos quadros**. A ULT usa a animação de ataque e aplica seu efeito próprio uma vez no impacto. Aladin flutua em seu tapete durante o deslocamento. As cenas editáveis ficam em `scenes/heroes/`; cada personagem tem `frames.tres`, duas folhas originais e dois atlas preparados em `assets/<id>/`. A preparação nativa Godot isola as poses e acrescenta margem transparente para evitar recortes ou partes do quadro vizinho. O laboratório (Ctrl+B) permite escolher os 12 personagens e as quatro animações com controle de velocidade.

Para refazer os atlas após trocar a arte: instale Pillow, NumPy e SciPy, configure `GODOT` para a Godot 4.7 e execute `python tools/prepare_roster.py`. As folhas originais não são modificadas. O export usa apenas os atlas preparados. As vozes sintéticas existentes continuam disponíveis para os cinco personagens anteriores; os sete novos usam os efeitos de combate compartilhados.

## Arte e desempenho

A nova arena lateral foi criada com ImageGen e está em `assets/ui/storybook_battle.png`; o prompt completo está em `assets/ui/storybook_battle_prompt.json`. A arte anterior permanece em `assets/ui/ruins_arena.png`. UI, texto, botões e barras são nativos da Godot. As artes de madeira anteriores continuam disponíveis, mas as telas principais usam cartões lisos e decoração reduzida.

Oito folhas de monstros editáveis estão em `scenes/enemies/`. Os quatro novos capítulos reutilizam as folhas dos temas de pomar, torre, palácio e biblioteca; classes/atributos e esquadrões variam. Os fundos e sprites não mudam a cada capítulo para doze artes exclusivas. Procedência em `assets/*/ART_NOTES.md`.

Texturas, retratos, estilos e cenas usam cache; a arena tem até seis unidades e evita instanciar recursos por quadro. O fundo é um TextureRect retido. Texturas usam filtragem linear/mipmaps e limites de importação. Limite de 30/60 FPS e movimento reduzido estão nas configurações; suspender salva, pausa áudio e limita processamento em segundo plano. Medições headless verificam lógica, não desempenho em celulares reais.

## Código e verificação

- `scripts/expedition_ui.gd`: início, preparação, recompensas, rotas, loja, galeria de silhuetas e resultados.
- `scripts/expedition_content.gd`: kits, 36 transformações, bênçãos e eventos.
- `scripts/hero_abilities.gd`: efeitos das ativas e reações individuais.
- `scripts/team_synergies.gd`: vínculos, gatilhos e recarga das combinações.
- `scripts/boss_rules.gd`: regras dos chefes, intenções e cópia de ULT.
- `scripts/team_events.gd`: seis encontros, falas condicionais e escolhas.
- `scripts/endless_rules.gd`: acúmulos infinitos, curva e saves compactos.
- `scripts/interface.gd`: componentes, layouts de combate PC/celular, ULTs e reset.
- `scripts/main.gd`: navegação, história, progressão e orquestração das batalhas.
- `scripts/battle_flow.gd`: intervalos idle, recargas, fila de ULT e compatibilidade com rodadas legadas.
- `scripts/combat_feedback.gd`: avisos laterais e abertura das ULTs.
- `scripts/mobile_icon.gd`: ícones vetoriais nativos para navegação por toque.
- `scripts/tactics.gd`: classes, alvos, esquadrões, esquiva, status e ULTs.
- `scripts/tactical_arena.gd`: posicionamento, animações, dash, projéteis e barras junto às unidades.
- `scripts/run.gd`, `campaign.gd`, `catalog.gd`: run, persistência e conteúdo.
- `export_presets.cfg`: exports Windows/Linux x86-64.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/biomes_formation.gd
godot --headless --path . --script tests/idle_feedback.gd
godot --headless --path . --script tests/party_combat.gd
godot --headless --path . --script tests/endless_events.gd
godot --headless --path . --script tests/adventure_ui.gd
godot --headless --path . --script tests/expedition.gd
godot --headless --path . --script tests/hero_abilities.gd
godot --headless --path . --script tests/expedition_ui.gd
godot --headless --path . --script tests/battle_flow.gd
godot --headless --path . --script tests/new_roster.gd
godot --headless --path . --script tests/tactics.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/idle.gd
godot --headless --path . --script tests/recruitment.gd
godot --headless --path . --script tests/presentation.gd
godot --headless --path . --script tests/combat_presentation.gd
```

As suítes usam saves isolados. `biomes_formation.gd` valida as 48 identidades/192 poses, seis variantes sorteáveis por bioma, alpha dos recortes, 72 quadros de ULT, formação e migração por classe, alturas humanas e meia escala, dash, área, retaguarda e recordes persistentes. `idle_feedback.gd` verifica as 12 aberturas/efeitos de ULT, passivas reais, logs e pausa, PV/mana numéricos, animação fatal completa, pop-ups sobre a arena, caminhada, ameaça dos inimigos, derrota de uma composição de cura em luta prolongada e conversão/salvamento exatos da build após a vitória. As novas suítes verificam os três efeitos de dupla e a remoção das outras combinações, PP/rodadas/morte, estandarte, cópia comprometida de ULT ofensiva e de cura, selos, alvos fixos, todos os eventos solo/em dupla, retomada sem duplicação, 180 fases infinitas, acúmulos não esgotáveis, recrutamento com a build compacta e marcos pessoais. A interface valida o histórico/pausa, a fase 13, os eventos e layouts mobile/PC com capturas gráficas. Os testes de expedição cobrem as 12 fases contínuas, sorteio em 20 mil recompensas, retomada/RNG, ordem das melhorias/eventos, loja sem compras duplicadas, derrota/vitória, desbloqueios e migração. Os testes de habilidades cobrem todos os 12 kits e 36 opções, incluindo efeitos e gatilhos concretos. O teste de interface joga um encontro animado real e verifica os limites das 12 fases, silhuetas e layout de PC/celular. As suítes anteriores mantêm a cobertura do combate, animações, ULTs, áudio e checkpoints legados.

`godot --headless --path . --script tools/simulate_runs.gd` executa uma sondagem determinística de balanceamento com 20 seeds por protagonista. É uma aproximação das durações das animações, sem renderização; não substitui playtests. Esta atualização inclui apenas o projeto-fonte; gere os exports no Godot.
