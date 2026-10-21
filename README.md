# RogueTales: O Último Fio

Idle RPG de fantasia em **Godot 4.7 / GDScript**, com oito capítulos, cinco heroínas recrutáveis e formação de até três integrantes. Interface vertical de **1080 × 1920**, com mouse ou toque, progresso offline e salvamento local.

## Jogar

1. Clone o repositório e importe `project.godot` na **Godot 4.7**.
2. Pressione **F5**. Abra o mapa e entre no primeiro capítulo.
3. Scarlet começa a jornada. Recrute as outras heroínas na história e organize a formação pela tela **Heróis**.
4. Derrote inimigos para ganhar ouro e EXP. Nos detalhes de cada heroína, compre níveis e habilidades exclusivas.
5. Depois do capítulo 1, recolha ouro e EXP no baú do início, inclusive depois de fechar o jogo.

O combate é automático. Cada capítulo tem dois encontros e um chefe. Entre encontros, escolha uma relíquia que dura apenas durante aquela expedição. A derrota mantém o ouro, a EXP, os recrutamentos e as melhorias permanentes. Uma nova expedição restaura a vida da equipe.

## Campanha

A Costureira roubou os finais dos contos e prendeu os reinos com oito agulhas. As princesas precisam recuperar suas vozes e decidir o que escrever depois.

| Capítulo | Local | Chefe | Recrutamento ao concluir |
| --- | --- | --- | --- |
| 1 | Bosque dos Sussurros | O Devorador de Trilhas | Rapunzel |
| 2 | Torre dos Ecos | A Guardiã da Janela | Branca de Neve |
| 3 | Pomar do Espelho | O Espelho Faminto | Mulan |
| 4 | Desfiladeiro de Jade | O General Sem Nome | — |
| 5 | Palácio da Meia-noite | O Relógio Partido | Ariel |
| 6 | Santuário das Marés | O Leviatã Silencioso | — |
| 7 | Forja das Cinzas | O Ferreiro de Destinos | — |
| 8 | Biblioteca do Último Fio | A Costureira dos Finais | Epílogo |

Cada capítulo tem introdução, desfecho e uma memória permanente: **esperança** concede +5 PV máximos a cada princesa; **coragem** concede +1 de dano. O epílogo varia conforme essas escolhas. O diário permite rever os diálogos sem conceder recompensas novamente.

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
- **Patrulha automática:** opção nas configurações para repetir capítulos já concluídos. Pula os diálogos vistos, escolhe a primeira relíquia oferecida e reinicia após a vitória. Para ao sair ou na derrota.
- **Progresso permanente:** níveis, habilidades, memórias e recrutamentos sobrevivem às derrotas. Relíquias pertencem à expedição atual.

O relógio local determina o acúmulo offline; um relógio que retrocede não concede tempo adicional. Não há servidor, conta online, compras ou anúncios.

## Telas e configurações

- Início com continuação, baú de provisões e acesso à formação.
- Mapa dos oito capítulos, apresentação, diálogos e escolhas de memória.
- Coleção de heróis, detalhes, níveis, habilidades e ordem de vanguarda.
- Combate, pausa, relíquias, vitória, derrota, recrutamento e epílogo.
- Diário, perfil, edição de perfil, conquistas, ajuda e créditos.
- Configurações de música, efeitos, qualidade visual, limite de 30/60 FPS, velocidade do texto, movimento reduzido, combate 1×/2× e patrulha automática.

**ESC** pausa o combate. As ferramentas de desenvolvimento começam **desativadas em toda inicialização**. **Ctrl+B** ativa/desativa o painel de debug; o laboratório de animações só fica disponível depois dessa ativação e fora de uma expedição em combate. Desativar o debug fecha o laboratório. Nenhum botão de teste aparece no menu normal.

A interface usa coordenadas lógicas de 540 × 960 e escala para o viewport de 1080 × 1920. Texto MSDF, filtragem linear e mipmaps suavizam a redução das sprites. A qualidade alta adiciona antialiasing nas formas circulares dos cenários/inimigos e usa mipmaps; a baixa mantém a interface em alta resolução com filtragem mais simples. Não depende de MSAA 2D, indisponível no renderizador de compatibilidade.

A trilha em loop e os efeitos sintetizados são originais deste projeto. Os controles de volume são independentes. Consulte `assets/audio/README.md`.

## Salvamento e migração

O save continua em `user://campaign_v1.json`, agora com **schema 2**, para preservar instalações anteriores. A gravação usa arquivo temporário e cópia `.bak`; um save inválido tenta recuperar o backup. Não existe sincronização na nuvem.

Saves antigos da campanha mantêm capítulos, ouro, equipe sobrevivente, habilidades e memórias. **Cinderela foi removida**: suas habilidades compradas são reembolsadas uma única vez na migração. Se ela estava na formação de uma expedição salva, essa expedição retorna ao acampamento para evitar associar sua vida a outra heroína. A versão antiga de três fases é independente e não concede capítulos automaticamente.

Ao continuar uma expedição, o jogo retorna **ao início do encontro atual**, com a vida e as relíquias registradas naquele ponto. Uma escolha de relíquia pendente mantém as mesmas opções ao sair e voltar. Encontros concluídos não concedem recompensas duplicadas. O desfecho pendente também pode ser retomado após fechar o jogo.

## Animações editáveis

Abra uma cena em `scenes/heroes/`, selecione o `AnimatedSprite2D` e edite **Sprite Frames**, FPS, duração, ordem, escala e offset. Cada instância tem recursos próprios. O código respeita os FPS configurados.

- O idle espera de 4 a 8 segundos entre piscadas e balanços eventuais de quatro quadros.
- Os ombros acompanham o progresso da caminhada, com origem nos pés. Ariel usa `walk` para nadar/flutuar.
- O ataque tem preparação, um único acerto e recuperação, sincronizados à duração dos quadros. Alterar os FPS também altera o instante do impacto.
- Mulan e Rapunzel avançam até o inimigo, golpeiam com a própria sprite e retornam à posição original; não lançam espada nem cabelo como projéteis.
- A maçã da Branca de Neve percorre uma linha reta até o alvo. Só a bomba da Scarlet usa uma trajetória em arco.
- Pausa e velocidade 2× afetam animação, dash e impacto em conjunto. A troca de encontro cancela golpes pendentes e restaura a formação.

**Arte:** cenários e inimigos ainda são placeholders desenhados por código. As spritesheets das heroínas continuam editáveis e algumas têm poucos quadros. A resolução maior melhora texto e amostragem, mas não cria detalhes ausentes nas imagens originais. Procedência e observações estão em `assets/*/ART_NOTES.md`.

## Estrutura

| Arquivo | Responsabilidade |
| --- | --- |
| `scripts/catalog.gd` | Capítulos, diálogos, heroínas e balanceamento |
| `scripts/campaign.gd` | Formação, evolução, idle, conquistas e persistência |
| `scripts/run.gd` | Vida, dano, cura, veneno, queimadura e relíquias |
| `scripts/arena.gd` | Formação visual, dash, projéteis, efeitos e ambientes |
| `scripts/hero.gd` | Idle, ombros e posicionamento temporal dos quadros |
| `scripts/main.gd` | Telas, navegação e fluxo de história/combate |
| `scripts/audio.gd` | Música e efeitos com volumes independentes |
| `scenes/heroes/*.tscn` | Modelos editáveis das cinco heroínas |
| `tools/make_audio.py` | Geração reproduzível da trilha original |
| `tests/smoke.gd` | Campanha completa, regras, saves e debug |
| `tests/idle.gd` | Migração, idle, evolução, telas, patrulha e ataques |

## Verificação

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/idle.gd
```

Os testes usam saves isolados. Cobrem os oito capítulos com renda da campanha, cinco recrutamentos, formação de três, habilidades, relíquias, recuperação de save, pausa, velocidade, impacto único, derrota, replay, epílogo e proteção do debug por Ctrl+B. A suíte idle cobre o reembolso da personagem removida, limite offline, resgates únicos, relógio regressivo, níveis, conquistas, perfil, preferências, repetição automática, trajetória reta da maçã e dash/retorno das duas atacantes corpo a corpo.

Abra com F5 para jogar no computador. Para um APK, configure o SDK Android e os templates de exportação na Godot; nenhum APK está incluído.
