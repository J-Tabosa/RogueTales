# RogueTales: O Último Fio

Idle RPG de fantasia em **Godot 4.7 / GDScript**, com oito capítulos, cinco heroínas recrutáveis e formação de até três integrantes. Interface vertical de **1080 × 1920**, adaptável a telas mais altas, com mouse ou toque, progresso offline e salvamento local.

## Jogar

1. Clone o repositório e importe `project.godot` na **Godot 4.7**.
2. Pressione **F5**. Abra o mapa e entre no primeiro capítulo.
3. Você começa só com Scarlet, a Chapeuzinho Vermelho. Convoque outras heroínas como upgrades temporários e cumpra seus requisitos para liberá-las permanentemente em **Heróis**.
4. Derrote inimigos para ganhar ouro e EXP. Nos detalhes de cada heroína, compre níveis e habilidades exclusivas.
5. Depois do capítulo 1, recolha ouro e EXP no baú do início, inclusive depois de fechar o jogo.

O combate é automático. Cada capítulo tem dois encontros e um chefe. Entre encontros, escolha uma relíquia ou um convite temporário de heroína. Cada capítulo completo corresponde a uma run. A derrota mantém o ouro, a EXP, os recrutamentos e as melhorias permanentes. Uma nova expedição restaura a vida da equipe.

## Campanha

A Costureira roubou os finais dos contos e prendeu os reinos com oito agulhas. As princesas precisam recuperar suas vozes e decidir o que escrever depois.

| Capítulo | Local | Chefe |
| --- | --- | --- |
| 1 | Bosque dos Sussurros | O Devorador de Trilhas |
| 2 | Torre dos Ecos | A Guardiã da Janela |
| 3 | Pomar do Espelho | O Espelho Faminto |
| 4 | Desfiladeiro de Jade | O General Sem Nome |
| 5 | Palácio da Meia-noite | O Relógio Partido |
| 6 | Santuário das Marés | O Leviatã Silencioso |
| 7 | Forja das Cinzas | O Ferreiro de Destinos |
| 8 | Biblioteca do Último Fio | A Costureira dos Finais |

Cada capítulo tem introdução, desfecho e uma memória permanente: **esperança** concede +5 PV máximos a cada princesa; **coragem** concede +1 de dano. O epílogo varia conforme essas escolhas. O diário permite rever os diálogos sem conceder recompensas novamente.

## Recrutamento por requisitos

Terminar capítulos não concede personagens automaticamente. Uma nova conta tem somente **Scarlet (Chapeuzinho Vermelho)**. Entre os encontros aparecem três upgrades: quando há uma heroína elegível, um deles é um convite para lutar até o fim daquela run. O primeiro convite da primeira run é da Branca de Neve; os seguintes variam entre as outras heroínas disponíveis.

| Heroína | Requisito de desbloqueio permanente |
| --- | --- |
| Branca de Neve | Vencer três runs distintas após escolhê-la como convite |
| Rapunzel | Restaurar 60 PV reais com sua cura; vida excedente e relíquias não contam |
| Mulan | Acertar oito golpes do combo Terceiro corte |
| Ariel | Vencer dois capítulos diferentes com ela viva na formação final |

A convidada entra imediatamente na arena e ataca junto com a equipe. Se os três espaços estiverem ocupados, escolha quem substituir apenas naquela run; a formação permanente fica preservada. Relíquias já escolhidas também beneficiam a nova integrante. Uma heroína não pode ser convocada duas vezes na mesma run.

O vínculo acumula entre runs e é registrado ao vencer ou perder. Abandonar registra o que estava salvo nos encontros já concluídos. Só vitórias contam para Branca de Neve e Ariel; cura e combos também contam em derrotas. Sair para o início mantém o checkpoint, sem encerrar ou contar outra run. A retomada preserva convidadas, vida, contadores, relíquias e as mesmas ofertas. Recarregar não duplica o crédito de uma run.

**Heróis → Ver requisito** mostra a descrição e o progresso. Ao completar a missão, a heroína fica disponível para começar futuras runs e evoluir permanentemente; ela entra na formação automaticamente se houver espaço. Princesas já desbloqueadas em saves antigos permanecem disponíveis. Uma heroína permanente fora da formação também pode aparecer como reforço temporário.

## Heroínas e evolução

Até três heroínas lutam simultaneamente, com vida, intervalo e animação independentes. A primeira da formação recebe os ataques; quando cai, a próxima assume. Curas não revivem integrantes durante o capítulo.

| Heroína | Ataque e habilidade inicial | Três habilidades evoluíveis |
| --- | --- | --- |
| Scarlet | Bomba em arco; queimadura | Dano de pólvora, queimadura, crítico |
| Rapunzel | Dash e golpe de cabelo corpo a corpo; cura coletiva a cada terceiro golpe | Cura, vitalidade, redução de dano inimigo |
| Branca de Neve | Maçã rápida em linha reta; veneno e autocura | Veneno, dano de maçãs, drenagem |
| Mulan | Dash e golpe de espada corpo a corpo; armadura e terceiro golpe fortalecido | Armadura, combo, velocidade |
| Ariel | Tridente e marés; cura coletiva e lentidão | Cura das marés, lentidão, dano do tridente |

Cada heroína sobe até o **nível 30**, gastando EXP e ouro. Cada nível aumenta sua vida base em 6% e dano base em 4%, de forma aditiva. As três habilidades exclusivas têm cinco níveis cada; o custo começa em 35 ouro e cresce em 30 por compra. Formação, níveis e habilidades ficam bloqueados durante uma expedição ativa; conclua-a ou abandone-a pelo menu de pausa para alterá-los.

O perfil possui nome e retrato editáveis, nível de conta, estatísticas e seis conquistas com recompensas resgatáveis uma única vez. A EXP da conta sobe o nível automaticamente; a evolução das heroínas é comprada na tela de detalhes.

## Ciclo idle

- **Baú de provisões:** liberado após concluir o capítulo 1; acumula até oito horas, com o jogo aberto ou fechado. A renda aumenta com os capítulos concluídos. Ouro vai à carteira; EXP vai à conta e às heroínas da formação presente no resgate.
- **Patrulha automática:** opção nas configurações para repetir capítulos já concluídos. Pula os diálogos vistos, escolhe o primeiro upgrade oferecido (incluindo convites; com a formação cheia, substitui o terceiro espaço) e reinicia após a vitória. Para ao sair ou na derrota.
- **Progresso permanente:** níveis, habilidades, memórias e recrutamentos sobrevivem às derrotas. Relíquias e convites pertencem à expedição atual.

O relógio local determina o acúmulo offline; um relógio que retrocede não concede tempo adicional. Não há servidor, conta online, compras ou anúncios.

## Telas e configurações

- Início com continuação, baú de provisões e acesso à formação.
- Mapa dos oito capítulos, apresentação, diálogos e escolhas de memória.
- Coleção de heróis, requisitos de desbloqueio, detalhes, níveis, habilidades e ordem de vanguarda.
- Combate, pausa, relíquias, vitória, derrota, recrutamento e epílogo.
- Diário, perfil, edição de perfil, conquistas, ajuda e créditos.
- Configurações de música, efeitos, vozes de ataque, qualidade visual, limite de 30/60 FPS, velocidade do texto, movimento reduzido, combate 1×/2× e patrulha automática.

**ESC** pausa o combate. As ferramentas de desenvolvimento começam **desativadas em toda inicialização**. **Ctrl+B** ativa/desativa o painel de debug; o laboratório de animações só fica disponível depois dessa ativação e fora de uma expedição em combate. Desativar o debug fecha o laboratório. Nenhum botão de teste aparece no menu normal.

A interface usa uma largura lógica de 540 e uma altura adaptável de 960 a 1280. O viewport parte de 1080 × 1920 e se expande com a proporção da janela. Telas altas ganham mais espaço de rolagem; navegação e botões inferiores acompanham a base da tela. Diálogos se expandem e janelas de escolha permanecem centralizadas. Em paisagem, o jogo mantém uma coluna vertical centralizada sobre o fundo ilustrado. Em dispositivos móveis, respeita a área segura informada pelo sistema para recortes e barras. Texto MSDF, filtragem linear e mipmaps suavizam a redução das sprites. A qualidade alta adiciona antialiasing nas formas circulares dos cenários/inimigos e usa mipmaps; a baixa mantém a interface em alta resolução com filtragem mais simples. Não depende de MSAA 2D, indisponível no renderizador de compatibilidade.

## Interface de floresta encantada

A arte da interface combina madeira entalhada, heras, detalhes dourados e verde profundo. Seis assets originais gerados com `image_gen` ficam em `assets/ui/`: painéis, botões, placa de ouro, mapa dos oito reinos, logo RogueTales em letras bolha e fundo de floresta. Os prompts completos estão em `assets/ui/PROMPTS.json`, com procedência e usos em `assets/ui/ART_NOTES.md`.

O mapa é uma trilha vertical ilustrada com oito marcadores interativos, estados de bloqueio/conclusão e rolagem até o próximo capítulo. Valores de ouro e textos continuam sendo renderizados pela Godot; não estão gravados nas imagens. Os cantos das molduras mantêm a proporção com nove fatias nativas. O cabeçalho abrevia valores grandes; o perfil mantém os números completos.

Ao entrar em um capítulo, repetir pela patrulha ou retomar um checkpoint, aparece uma transição de loading com o logo colorido, o capítulo e uma barra. Dura cerca de 0,3 s (0,12 s com movimento reduzido), cede quadros à apresentação e inicia/retoma a run uma única vez. Não adiciona uma espera de vários segundos nem usa dados de rede.

## Desempenho

- Texturas e regiões de atlas são compartilhadas. Arquivos PNG originais ficam preservados, mas a importação limita as texturas da UI a 768/1024 px e os fundos a 1536 px, com mipmaps.
- Retratos nas listas, perfil e atributos são sprites estáticas em cache; não instanciam cinco loops de animação e materiais de shader a cada navegação. Personagens na arena continuam animadas.
- Cenários mantêm sua lista de desenho durante o combate. Somente o percurso entre encontros redesenha o fundo, limitado a 30 quadros/s em alta e 15 no modo leve.
- Personagens paradas deixam de reenviar parâmetros idênticos ao shader. Mudanças de qualidade, pausa e velocidade são aplicadas quando mudam. Estilos de UI e estilos de inimigos são reutilizados.
- Efeitos visuais seguem o limite de 60/30 FPS escolhido. O relógio de dano, dash e animação permanece independente desse limite visual.
- Ao suspender o aplicativo, o progresso é salvo, a música pausa e o limite cai a 5 FPS caso o sistema ainda processe quadros. Retomar restaura as preferências e contabiliza o tempo do baú offline.

`tools/benchmark_visuals.gd` mede 10.000 atualizações de três heroínas em modo headless, sem renderização. Na mesma máquina de desenvolvimento, a lógica de idle passou de 98.284 para 61.091 µs e a de ataques de 118.684 para 96.804 µs, respectivamente cerca de 38% e 18% menos tempo de script. É um microteste de CPU; não representa FPS ou autonomia medidos em um celular. Valide uma exportação no aparelho alvo para comparar GPU, memória e aquecimento.

A trilha em loop e os efeitos sintetizados são originais deste projeto. Os controles de volume são independentes. Consulte `assets/audio/README.md`.

## Monstros e áudio de combate

Cada capítulo tem uma spritesheet original gerada com `image_gen`, com inimigo comum e chefe: floresta, torre, pomar, soldados de neve, guardas do palácio, praia, forja e biblioteca. Cada um possui quatro quadros de idle e quatro de ataque. As cenas em `scenes/enemies/` são editáveis no Inspector; o relógio de combate respeita FPS, durações, pausa e velocidade 2×. Os atlas usam separadores ajustados às folhas, com tela de quadro fixa, sem alterar os PNGs originais. Prompts em `assets/enemies/PROMPTS.json`.

Heroínas e monstros piscam em vermelho ao sofrer dano. Dano contínuo tem intervalo entre flashes. A bomba tem som de explosão; as cinco heroínas possuem chamadas curtas sintéticas; vitória e conquistas resgatadas têm jingles próprios. As vozes são geradas por síntese, com limite de repetição e sobreposição; não são gravações de atrizes. Consulte `assets/audio/COMBAT_AUDIO.md`.

## Salvamento e migração

O save continua em `user://campaign_v1.json`, agora com **schema 3**, para preservar instalações anteriores. A gravação usa arquivo temporário e cópia `.bak`; um save inválido tenta recuperar o backup. Não existe sincronização na nuvem.

Saves antigos da campanha mantêm capítulos, ouro, equipe sobrevivente, habilidades e memórias. **Cinderela foi removida**: suas habilidades compradas são reembolsadas uma única vez na migração. Se ela estava na formação de uma expedição salva, essa expedição retorna ao acampamento para evitar associar sua vida a outra heroína. A versão antiga de três fases é independente e não concede capítulos automaticamente.

Ao continuar uma expedição, o jogo retorna **ao início do encontro atual**, com a formação daquela run (incluindo convidadas), vida, contadores de requisitos e relíquias registrados naquele ponto. Uma escolha de relíquia pendente mantém as mesmas opções ao sair e voltar. Encontros concluídos não concedem recompensas duplicadas. O desfecho pendente também pode ser retomado após fechar o jogo.

## Animações editáveis

Abra uma cena em `scenes/heroes/`, selecione o `AnimatedSprite2D` e edite **Sprite Frames**, FPS, duração, ordem, escala e offset. Cada instância tem recursos próprios. O código respeita os FPS configurados.

- O idle espera de 4 a 8 segundos entre piscadas e balanços eventuais de quatro quadros.
- Os ombros acompanham o progresso da caminhada, com origem nos pés. Ariel usa `walk` para nadar/flutuar.
- O ataque tem preparação, um único acerto e recuperação, sincronizados à duração dos quadros. Alterar os FPS também altera o instante do impacto.
- Mulan e Rapunzel avançam até o inimigo, golpeiam com a própria sprite e retornam à posição original; não lançam espada nem cabelo como projéteis.
- A maçã da Branca de Neve percorre uma linha reta até o alvo. Só a bomba da Scarlet usa uma trajetória em arco.
- Pausa e velocidade 2× afetam animação, dash e impacto em conjunto. A troca de encontro cancela golpes pendentes e restaura a formação.

**Arte:** os cenários de combate continuam desenhados por código; interface e monstros usam as novas imagens geradas. As spritesheets continuam editáveis e algumas têm poucos quadros. A resolução maior melhora texto e amostragem, mas não cria detalhes ausentes nas imagens originais. Procedência e observações estão em `assets/*/ART_NOTES.md`.

## Estrutura

| Arquivo | Responsabilidade |
| --- | --- |
| `scripts/catalog.gd` | Capítulos, diálogos, heroínas, requisitos e balanceamento |
| `scripts/campaign.gd` | Formação, evolução, desbloqueios por run, idle, conquistas e persistência |
| `scripts/run.gd` | Vida, dano, cura, veneno, queimadura e relíquias |
| `scripts/arena.gd` | Formação visual, dash, projéteis, efeitos e ambientes |
| `scripts/hero.gd` | Idle, ombros e posicionamento temporal dos quadros |
| `scripts/main.gd` | Telas, navegação e fluxo de história/combate |
| `scripts/ui_skin.gd` | Artes compartilhadas, atlas e molduras de nove fatias |
| `scripts/backdrop.gd` | Cenários retidos e rolagem de viagem limitada por qualidade |
| `scripts/audio.gd` | Música e efeitos com volumes independentes |
| `scripts/enemy.gd` | Animações de inimigos e chefes, cache e flash de dano |
| `scenes/heroes/*.tscn` | Modelos editáveis das cinco heroínas |
| `scenes/enemies/*.tscn` | Inimigo comum e chefe editáveis dos oito capítulos |
| `tools/make_audio.py` | Geração reproduzível da trilha original |
| `tools/make_combat_audio.py` | Geração reproduzível de explosão, vozes e jingles |
| `tools/build_enemy_frames.py` | Reconstrução dos atlas e cenas dos monstros |
| `tests/smoke.gd` | Campanha completa, regras, saves e debug |
| `tests/idle.gd` | Migração, idle, evolução, telas, patrulha e ataques |
| `tests/recruitment.gd` | Convites, quatro requisitos, saves com convidadas e desbloqueio após três vitórias reais |
| `tests/presentation.gd` | Artes, cache, cinco proporções, área segura, loading, pausa e suspensão |
| `tests/combat_presentation.gd` | Dezesseis inimigos, flashes, sincronização e limites de áudio |
| `tools/benchmark_visuals.gd` | Microteste reproduzível de atualização das animações |

## Verificação

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/idle.gd
godot --headless --path . --script tests/recruitment.gd
godot --headless --path . --script tests/presentation.gd
godot --headless --path . --script tests/combat_presentation.gd
```

Os testes usam saves isolados. Cobrem os oito capítulos com renda da campanha e repetições para evoluir, recrutamento temporário, formação de três, habilidades, relíquias, recuperação de save, pausa, velocidade, impacto único, derrota, replay, epílogo e proteção do debug por Ctrl+B. A suíte idle cobre o reembolso da personagem removida, limite offline, resgates únicos, relógio regressivo, níveis, conquistas, perfil, preferências, repetição automática, trajetória reta da maçã e dash/retorno das duas atacantes corpo a corpo.

A suíte de recrutamento verifica os quatro requisitos, crédito único por run, cura efetiva, combos, sobrevivência de Ariel em capítulos distintos, substituição com equipe cheia, herança de relíquias, migração e persistência. Também joga combates reais até a terceira vitória com convite da Branca de Neve e confirma sua presença na próxima formação inicial.

Abra com F5 para jogar no computador. Para um APK, configure o SDK Android e os templates de exportação na Godot; nenhum APK está incluído.
