# Suíte 0.9.6

Execute `python3 tools/check_095.py --godot /caminho/para/godot`. O runner considera falha qualquer erro de script, mesmo que o Godot retorne código zero após uma asserção.

- `rules_095`: 53 verificações das fichas, fórmula híbrida, defesa, recursos e persistência.
- `boons_095`: 58 verificações das bênçãos, incluindo Full House, controles, limites e sobrevivência.
- `integration_095`: as 48 combinações de protagonista/bênção contra chefes e a cena real; desbloqueios, desejos, mercador e fichas PC/mobile.
- `corrections_096`: pólvora e seu contador, abertura 1/2/3, convite garantido opcional e feito da Alice por itens, rodadas, imunidades, derrota e persistência.
- Os outros testes do runner verificam arte, toque, formação, dificuldade, HUD, equipamentos, economia, eventos, recrutamento e regressões visuais.

As expectativas alteradas dos testes de interface/economia foram migradas para dano periódico por vez, feitos específicos, ausência das antigas mutações e limites corretos de mana. Os testes HD continuam usando os originais da UI, sem voltar a extrair retratos das pequenas células de combate.

Testes históricos de combate (`hero_abilities`, `party_combat`, `tactics`, `battle_flow`, `ultimate_overhaul`, `ult_revision`, `idle`, `smoke` e `new_roster`) descrevem o sistema anterior (AP/PP por rodada, cooldowns em segundos, passivas e ULTs substituídas). Permanecem no repositório como histórico; seus contratos de mecânica foram substituídos pelos três testes 0.9.5. Não são anunciados como aprovados nesta versão. Testes visuais antigos adicionais continuam disponíveis para investigação manual.
