# Inimigos das Florestas da Fase 1

As quatro florestas iniciais usam 16 monstros do pacote aprovado. Os demais mapas e desafios secretos conservam seus cadastros e suas artes.

## Substituições

| Floresta | Comuns | Chefe solo |
| --- | --- | --- |
| Primavera | Lobo Cinza, Javali, Caçador de rifle | Urso Pardo |
| Verão | Falcão, Guaxinim, Lobo Marrom | Serpente |
| Outono | Lebre de Dentes Afiados, Raposa, Lobo Preto | Lenhador |
| Inverno | Lobo Branco, Coruja Branca, Caçador de espingarda | Alce |

A lista do Markdown entregue prevalece sobre os rascunhos anteriores: Lobo Preto está no Outono; Guaxinim está no Verão; Serpente é o chefe do Verão. Chefes não aparecem no sorteio dos comuns. Os combates 1-1, 1-2 e 1-3 têm um, dois e três inimigos; 1-4 varia entre um e três; 1-5 continua mercado; 1-6 tem apenas o chefe.

## Conversão dos atributos

Referência: média das 12 fichas de nível 1 em `scripts/roster_data.gd`, sem treinamento, itens, bênçãos ou passivas condicionais. Dano usa a soma de Dano Físico e Dano Mágico de cada personagem; todos os novos monstros causam dano físico. Defesa Física e Defesa Mágica usam suas respectivas médias, nas unidades em pontos do combate. “Vel” é Iniciativa e não FPS.

| Referência | Média |
| --- | ---: |
| PV | 215.833333 |
| Dano total | 22.416667 |
| Defesa Física | 2.083333 |
| Defesa Mágica | 2.916667 |
| Iniciativa | 46.666667 |

Os valores abaixo são as bases aplicadas na primeira floresta, sem multiplicar novamente o bônus de chefe. Não há diluição de dano por quantidade de inimigos nem crescimento adicional a cada fase desse mapa. Elites continuam com +35% PV e +15% dano; o crescimento dos mapas posteriores e do infinito permanece separado. A planilha conserva precisão completa; a tabela arredonda apenas a exibição.

| Floresta | Monstro | Classe | PV | Dano | DF | DM | Iniciativa |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Inverno | Lobo Branco | Assassino | 118.708 | 16.812 | 0.625 | 0.875 | 58.333 |
| Inverno | Coruja Branca | Assassino | 97.125 | 15.692 | 0.521 | 0.729 | 58.333 |
| Inverno | Caçador de Inverno | Atirador | 118.708 | 22.417 | 0.625 | 0.875 | 37.333 |
| Inverno | Alce (chefe) | Vanguarda | 949.667 | 23.538 | 2.188 | 3.062 | 42.000 |
| Outono | Lebre de Dentes Afiados | Assassino | 75.542 | 12.329 | 0.313 | 0.438 | 65.333 |
| Outono | Raposa | Assassino | 97.125 | 14.571 | 0.521 | 0.729 | 58.333 |
| Outono | Lobo Preto | Assassino | 129.500 | 19.054 | 0.729 | 1.021 | 56.000 |
| Outono | Lenhador (chefe) | Vanguarda | 863.333 | 25.779 | 1.875 | 2.625 | 39.667 |
| Primavera | Lobo Cinza | Assassino | 118.708 | 16.812 | 0.625 | 0.875 | 56.000 |
| Primavera | Javali | Vanguarda | 215.833 | 15.692 | 1.458 | 2.042 | 44.333 |
| Primavera | Caçador de Primavera | Atirador | 97.125 | 20.175 | 0.521 | 0.729 | 39.667 |
| Primavera | Urso Pardo (chefe) | Vanguarda | 1036.000 | 25.779 | 2.396 | 3.354 | 37.333 |
| Verão | Falcão | Assassino | 86.333 | 15.692 | 0.417 | 0.583 | 63.000 |
| Verão | Guaxinim | Vanguarda | 140.292 | 13.450 | 0.833 | 1.167 | 46.667 |
| Verão | Lobo Marrom | Assassino | 118.708 | 17.933 | 0.625 | 0.875 | 56.000 |
| Verão | Serpente (chefe) | Assassino | 777.000 | 28.021 | 1.354 | 1.896 | 42.000 |

Todos iniciam com um ataque por turno, zero esquiva, zero chance crítica e zero dano mágico. Bestas têm categoria explícita `beast`; caçadores e lenhador são `humanoid`. O rifle mantém alcance longo/prioridade de retaguarda; a espingarda tem alcance médio e escolhe vanguarda/meio enquanto houver alvos nessas posições.

## Artes e animações

- Originais: o ZIP enviado permanece intacto; `docs/phase1_source_sha256.json` registra os 20 PNGs originais. O importador não redesenha as artes.
- Saída: 139 PNGs RGBA em `assets/enemies/phase1/<monstro>/attack/` e `idle/`. Personagens sem IDLE próprio reutilizam o primeiro frame do ataque.
- Todos os frames de cada monstro usam canvas 768×768 e pivô fixo, definido no manifesto. Os pés são a referência dos terrestres; o centro de voo é a referência das aves.
- Os nove PNGs já transparentes não recebem chroma key. Os verdes recebem alpha suave e despill. Os dois fundos brancos usam preenchimento conectado às bordas, preservando regiões internas e efeitos.
- A separação usa os corpos conectados e a proximidade dos efeitos, em vez de cortar cegamente 1774 por quatro: várias silhuetas ultrapassam a projeção nominal da própria coluna. Cada pixel com alpha pertence a exatamente um frame.
- Coruja IDLE é reescalado em 0,56×; Falcão em 0,63×; Guaxinim em 0,40×, em relação às respectivas folhas originais, para aproximar a cabeça/corpo do ataque. Guaxinim muda de quadrúpede no IDLE para bípede no ataque, conforme solicitado.
- Ataques usam 10 FPS configuráveis no manifesto, sem loop. Ao concluir, selecionam imediatamente o IDLE. Coruja e Falcão têm quatro frames de IDLE em loop; Guaxinim tem um frame estático.
- Dano e lançamento do tiro ocorrem nos frames de impacto do anexo. Urso e Guaxinim distribuem o dano base entre seus múltiplos impactos: três garradas não triplicam o atributo Dano. A ação e o consumo de ataque continuam únicos.
- Deslocamento e pausa usam o relógio da arena; o sprite é espelhado durante a volta para a direita. Chefes e suas áreas de seleção recebem exatamente 1,25×. Não herdam estandarte, fios ou cópia de ULT dos chefes antigos.

| Monstro | Frames ATK | Frames IDLE | Impactos (1-based) |
| --- | ---: | ---: | --- |
| Alce | 8 | 1 | 5 |
| Caçador de Inverno | 8 | 1 | 5 |
| Coruja Branca | 8 | 4 | 6 |
| Lobo Branco | 8 | 1 | 5 |
| Lebre de Dentes Afiados | 8 | 1 | 5 |
| Lenhador | 8 | 1 | 6 |
| Lobo Preto | 8 | 1 | 5 |
| Raposa | 8 | 1 | 5 |
| Caçador de Primavera | 8 | 1 | 5 |
| Javali | 12 | 1 | 9 |
| Lobo Cinza | 8 | 1 | 5 |
| Urso Pardo | 8 | 1 | 4, 5, 6 |
| Falcão | 6 | 4 | 4 |
| Guaxinim | 8 | 1 | 5, 6 |
| Lobo Marrom | 8 | 1 | 5 |
| Serpente | 8 | 1 | 6 |

## Arquivos e manutenção

- `scripts/phase1_enemies.gd`: cadastro, conversão percentual, sorteio por floresta, carregamento e cache dos SpriteFrames.
- `assets/enemies/phase1/manifest.json`: caminhos dos 139 PNGs, pivôs, FPS e impactos; os arquivos `.import` guardam suas opções de importação.
- `tools/import_phase1_enemies.py`: reprodução da remoção dos fundos, separação e normalização. Depende de Pillow, numpy e scipy. Recebe a pasta extraída com `--source` e uma pasta temporária de revisão com `--qa`.
- `data/inimigos.xlsx`: 16 fichas `phase1_*` acrescentadas às 63 anteriores; valores anteriores, tabela, validações, filtro e congelamento preservados. A planilha continua sendo relida entre combates.
- Integração em `enemy.gd`, `tactics.gd`, `boss_rules.gd`, `run.gd`, `tactical_arena.gd`, `main.gd` e `enemy_balance.gd`; manifesto incluído nos três presets de exportação.
- `tests/phase1_enemies.gd` e `tests/phase1_visual.gd`: cadastro, proporções, alpha, contagem, chefes solo, impactos, pausa, retorno ao IDLE e apresentação PC/mobile. Os testes legados de planilha/limites mantêm seus cenários isolados.

## Validação

Executado em Godot 4.7.2 oficial (`ed1daf0bf`):

- `phase1_enemies`: 11.538 verificações, zero falhas.
- `phase1_visual`: 68 verificações, zero falhas, renderização OpenGL e 16 capturas nas quatro florestas em PC e mobile. Valida os impactos reais nos frames 4/5/6 do Urso, pausa, retorno imediato e hitbox do chefe.
- `enemy_balance`: 869 verificações, zero falhas, incluindo leitura do XLSX empacotado.
- `rules_095`: 53 verificações, zero falhas.
- `seasonal_routes_100`: 6.026 verificações, 17 rotas e 65 cenários HD.
- `encounter_difficulty`: 15.360 encontros, chefes/secretos, RNG do checkpoint e limite no infinito.
- `combat_readability`: aprovado.
- Atualização de conquistas incorporada sem sobrescrever `4adb439`; `goals_speed` e `phase1_visual` aprovados novamente após a integração.
- 139 PNGs verificados por integridade, alpha e margens; composição inspecionada em fundos claro/escuro. Conferidas as arenas renderizadas no PC e no mobile.

APK: `RogueTales-1.0.1-fase1.apk`, Android código 23, arm64-v8a, pacote `com.jtabosa.roguetales.preview.v07`. Tamanho 362.346.243 bytes. ZIP íntegro, alinhamento nativo de 16 KB e assinatura v2/v3 verificados. Certificado anterior preservado: `528b1117691e72b07deb073f7587da9de4643fe017069bd1e7545eb76d8cf377`. SHA-256 do APK: `182b6e2f4a823d3d7d5877ba13f75f982045f965918f8c9892bef76cc192341f`. Nenhuma chave privada é incluída no repositório. Sem teste em aparelho físico neste ambiente.
