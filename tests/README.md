# Suíte 1.0.0

- `character_asset_paths`: carrega os doze personagens nas pastas definitivas, animações de tamanho fixo, retratos HD, efeitos básicos e de Ultimate, e confere o manifesto de reconstrução sem folhas substituídas.

Execute `python3 tools/check_095.py --godot /caminho/para/godot`. O runner considera falha qualquer erro de script, mesmo que o Godot retorne código zero após uma asserção.

- `enemy_balance`: leitura do Excel entregue e de PCK, preservação dos atributos-base e da progressão, alterações de vida/dano/defesas/esquiva, iniciativa e três ataques reais na própria vez, texto compartilhado/inline, rejeição de dados inválidos e recuperação.

- `seasonal_routes_100`: 6.025 verificações, todas as 17 rotas, 680 combates e 136 mercados, chances das quatro estações, cenários HD, inimigos por bioma, encontros definidos, prefixos/checkpoints/RNG, relíquia de vaga, teto cinco e migração de runs antigas.
- `seasonal_ui_100`: 2.220 verificações e 130 arenas (65 mapas × PC/mobile), cada uma com 5 aliados e 9 inimigos. Escolhas por toque/clique e aquisição real do item mítico.
- `weather_100`: 58 verificações de neve/chuva/sol/brasas/interiores, pausa, movimento reduzido, qualidade baixa e efeito de fogo acionado por uma ULT real da Lume.
- `progression_0910`: compra por 5.000 memórias, migração de coleção, Iniciativa 50 da Umi sem reaplicar a correção, 1.728 posições geradas, limites 3/6/9, inimigos sem esquiva, uma campanha de 60 combates e 12 mercados, equipe máxima de cinco e migração de equipes antigas.
- `release_ui_0910`: compra por toque/clique, combate real da Alice com itens negativos, origem segura nos retratos e log, 48 bênçãos no sandbox, montagem da equipe, Negociante e preservação integral do save normal. Com renderização nativa, aceita um diretório de capturas após `--` e verifica 540×960 e 1280×800.
- `bonuses_098`: tabelas, probabilidades, elegibilidade, adição de percentuais, defesa, crítico, esquiva, Iniciativa negativa, mana, curas, básicos extras, loja, migração e idempotência de HP/grupo em JSON.
- `bonuses_ui_098`: seleção/retorno/confirmação por toque e clique na cena real, seis fundos de raridade, nove beneficiários, rolagem, prévia negativa e confirmação da loja em PC/mobile.
- `rules_095`: 53 verificações das fichas, fórmula híbrida, defesa, recursos e persistência.
- `boons_095`: 58 verificações das bênçãos, incluindo Full House, controles, limites e sobrevivência.
- `integration_095`: as 48 combinações de protagonista/bênção contra chefes e a cena real; desbloqueios, desejos, mercador e fichas PC/mobile.
- `corrections_096`: pólvora e seu contador, abertura 1/2/3, convite garantido opcional e feito da Alice por itens, rodadas, imunidades, derrota e persistência.
- `wishes_silk_097`: toques/cliques reais nos desejos em combate, ressurreição com Aladin caído, abate, gesto de arrastar sem ativação e ult da Silk completa em 1×/2×/3×.
- Os outros testes do runner verificam arte, toque, formação, dificuldade, HUD, equipamentos, economia, eventos, recrutamento e regressões visuais.

As expectativas alteradas dos testes de interface/economia foram migradas para dano periódico por vez, feitos específicos, ausência das antigas mutações e limites corretos de mana. Os testes HD continuam usando os originais da UI, sem voltar a extrair retratos das pequenas células de combate.

Os testes anteriores usam `test_accounts.gd` para representar uma conta legada com Scarlet; assim suas verificações de combate não dependem de comprar o primeiro personagem. Os testes 0.9.10 exercitam a conta nova real, com todos os personagens bloqueados.

Testes históricos de combate (`hero_abilities`, `party_combat`, `tactics`, `battle_flow`, `ultimate_overhaul`, `ult_revision`, `idle`, `smoke` e `new_roster`) descrevem o sistema anterior (AP/PP por rodada, cooldowns em segundos, passivas e ULTs substituídas). Permanecem no repositório como histórico; seus contratos de mecânica foram substituídos pelos três testes 0.9.5. Não são anunciados como aprovados nesta versão. Testes visuais antigos adicionais continuam disponíveis para investigação manual.
