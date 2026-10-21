# RogueTales: O Último Fio

Idle RPG de fantasia em **Godot 4.7 / GDScript**, com uma campanha completa de oito capítulos, seis heroínas recrutáveis e formação de até três integrantes. Interface vertical de 540 × 960, controlada por mouse ou toque.

## Jogar

1. Clone o repositório e importe `project.godot` na **Godot 4.7**.
2. Pressione **F5**. Abra o mapa e entre no primeiro capítulo.
3. Scarlet começa a jornada; as outras heroínas são recrutadas na história.
4. Monte sua equipe, escolha a vanguarda e invista o ouro em melhorias.

O combate é automático. Cada capítulo contém dois encontros e um chefe. Entre encontros, escolha uma relíquia que dura apenas durante aquela expedição. A derrota mantém o ouro conquistado, os recrutamentos e as melhorias permanentes. Capítulos concluídos podem ser repetidos para conseguir mais ouro.

## Campanha

A Costureira roubou os finais dos contos e prendeu os reinos com oito agulhas. As princesas precisam recuperar suas vozes e decidir o que escrever depois.

| Capítulo | Local | Chefe | Recrutamento ao concluir |
| --- | --- | --- | --- |
| 1 | Bosque dos Sussurros | O Devorador de Trilhas | Rapunzel |
| 2 | Torre dos Ecos | A Guardiã da Janela | Branca de Neve |
| 3 | Pomar do Espelho | O Espelho Faminto | Mulan |
| 4 | Desfiladeiro de Jade | O General Sem Nome | Cinderela |
| 5 | Palácio da Meia-noite | O Relógio Partido | Ariel |
| 6 | Santuário das Marés | O Leviatã Silencioso | — |
| 7 | Forja das Cinzas | O Ferreiro de Destinos | — |
| 8 | Biblioteca do Último Fio | A Costureira dos Finais | Epílogo |

Cada capítulo tem introdução, desfecho e uma memória permanente: **esperança** concede +5 PV máximos a cada princesa; **coragem** concede +1 de dano a cada princesa. O epílogo varia de acordo com as escolhas. O diário permite rever diálogos sem conceder recompensas novamente.

## Equipe e melhorias

Até três princesas lutam simultaneamente, com vida, escudo, intervalo e animação independentes. A primeira da formação recebe os ataques; quando cai, a próxima assume. Curas não revivem integrantes caídas durante o capítulo. Uma nova expedição restaura a formação.

| Heroína | Função e habilidade inicial | Três melhorias exclusivas |
| --- | --- | --- |
| Scarlet | Bombas e queimadura | Dano de pólvora, queimadura, crítico |
| Rapunzel | Cura coletiva a cada terceiro golpe | Cura, vitalidade, redução de dano inimigo |
| Branca de Neve | Veneno e autocura por acerto | Veneno, dano de maçãs, drenagem |
| Mulan | Armadura e terceiro golpe fortalecido | Armadura, combo, velocidade |
| Cinderela | Escudo para a equipe a cada encontro | Barreira, dano de cristal, crítico |
| Ariel | Cura coletiva e lentidão dos inimigos | Cura das marés, lentidão, dano do tridente |

Cada melhoria tem cinco níveis. O custo começa em 35 ouro e cresce em 30 por nível. Formação e melhorias ficam bloqueadas enquanto existir uma expedição ativa; conclua-a ou abandone-a pelo menu de pausa para alterar a equipe.

## Telas e controles

- Início e continuação da jornada.
- Mapa com oito capítulos e bloqueio por progressão.
- Apresentação do capítulo, diálogos e escolhas de memória.
- Equipe com recrutamentos e ordem de vanguarda.
- Melhorias individuais, com custos e níveis.
- Combate com três barras de vida, escudos, preparação dos ataques, pausa e 1×/2×.
- Escolha de relíquias, vitória, derrota, recrutamento e epílogo.
- Diário, opções de movimento reduzido/velocidade, ajuda e créditos.

**ESC** pausa o combate. As ferramentas de desenvolvimento começam **desativadas em toda inicialização**. **Ctrl+B** ativa/desativa o painel de debug; o laboratório de animações só pode ser aberto depois dessa ativação e fora de uma expedição em combate. Desativar o debug fecha o laboratório. Nenhum botão de teste aparece no menu normal.

## Salvamento

Progresso, ouro, equipe, níveis, escolhas e opções ficam em `user://campaign_v1.json`, com gravação temporária e cópia de segurança `.bak`. Um save inválido tenta recuperar o backup. A versão anterior de três fases é independente desta campanha e não concede capítulos concluídos automaticamente.

Ao continuar uma expedição, o jogo retorna **ao início do encontro atual**, com a vida registrada naquele ponto e as relíquias já escolhidas. Uma escolha de relíquia pendente mantém as mesmas opções ao sair e voltar. Recompensas de um encontro já concluído não são concedidas novamente. O desfecho pendente também pode ser retomado depois de fechar o jogo.

## Animações editáveis

Abra uma cena em `scenes/heroes/`, selecione o `AnimatedSprite2D` e edite **Sprite Frames**, FPS, duração, ordem, escala e offset. Cada instância possui recursos próprios. O código não substitui os FPS configurados.

- Idle permanece imóvel por 4–8 segundos, com piscada ou balanço eventual de quatro quadros. Não há respiração contínua exagerada.
- Os ombros acompanham o progresso real da caminhada, com origem nos pés.
- Cada ataque possui um relógio próprio: preparação, acerto único e recuperação. Alterar os FPS também altera o instante do impacto.
- Acertar não encerra a animação no meio. Pausa e velocidade 2× afetam os mesmos relógios; mudar de encontro cancela golpes pendentes.
- Cada integrante mantém a posição na formação durante caminhada e ataque. Ariel utiliza `walk` para nadar/flutuar com a cauda.

**Limitação de arte:** Cinderela ainda usa a referência original com recorte e poses por malha nativa, pois a geração de sua spritesheet foi bloqueada. Não possui piscada desenhada; a chance de piscada fica em zero até esses quadros serem substituídos. As outras folhas também são arte de teste, com poucos quadros em algumas heroínas. Cenários e inimigos usam formas vetoriais desenhadas por código. Os PNGs originais permanecem inalterados; detalhes de procedência estão nos arquivos `assets/*/ART_NOTES.md`.

## Estrutura

| Arquivo | Responsabilidade |
| --- | --- |
| `scripts/catalog.gd` | Oito capítulos, diálogos, heroínas, habilidades e números de balanceamento |
| `scripts/campaign.gd` | Recrutamento, formação, upgrades, escolhas e persistência |
| `scripts/run.gd` | Vida individual, dano, cura, veneno, queimadura, escudos e relíquias |
| `scripts/arena.gd` | Formação visual, animações, efeitos e oito ambientes/inimigos |
| `scripts/hero.gd` | Idle, ombros e posicionamento temporal dos quadros |
| `scripts/main.gd` | Telas, navegação e fluxo de história/combate |
| `scenes/heroes/*.tscn` | Modelos editáveis das seis princesas |
| `tests/smoke.gd` | Campanha completa, regras, saves, regressões e debug |

## Verificação

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/smoke.gd
```

Os testes usam um save isolado e completam os oito capítulos com a renda obtida na campanha. Cobrem recrutamentos, formação de três, habilidades exclusivas, relíquias, recuperação de save, pausa, velocidade, impacto único/recuperação da animação, derrota, replay, epílogo e proteção do debug por Ctrl+B.

Esta versão fecha o ciclo jogável da campanha. Ainda não inclui áudio, progresso offline, loja, monetização, sprites finais de inimigos ou um APK exportado. Para Android, configure o SDK e os templates de exportação na Godot.
