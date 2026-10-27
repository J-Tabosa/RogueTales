# RogueTales: O Último Fio

Roguelite em **Godot 4.7**, PC e Android, com 12 protagonistas, equipes de até nove personagens e 12 estágios de seis fases. Versão **0.9.8**: Bônus Únicos e de Grupo, seis raridades com fundos cinza/verde/azul/roxo/laranja/vermelho, prévia e confirmação de alvo e Iniciativa.

## Regras e personagens

As fontes de design fornecidas estão preservadas em [personagens](docs/RogueTales_Personagens.md) e [mecânicas](docs/RogueTales_Mecanicas.md). [REGRAS_095](docs/REGRAS_095.md) registra a implementação, compatibilidade e convenções provisórias dos pontos que os MDs deixaram em aberto.

- Cada rodada ordena os vivos por **Iniciativa, com teto 100 e sem piso negativo**. Cada um executa sua **Quantidade de Ataques** na própria vez. A iniciativa não concede ações adicionais.
- **Dano Físico/Mágico** e **Defesa Física/Mágica** são independentes. Mitigação por pontos: `bruto × 100 / (100 + defesa)`. Híbridos calculam as parcelas separadamente; dano real ignora as defesas, com escudos ainda absorvendo.
- Mana vem dos acertos elegíveis ou do início da própria vez, conforme a ficha. Não há regeneração por segundo nem ganho natural por receber dano. Excedente e mana entre combates são preservados.
- ULTs podem intercalar básicos sem consumir os restantes. Alice usa quatro cargas, conserva sobras e ulta automaticamente. Aladin usa desejos manuais, sem mana, inclusive caído e no mercador; não participa da ULT automática.
- Uma bênção pessoal por run. As 48 bênçãos usam seus feitos específicos, chefes secretos e conclusão como protagonista. Vencer doze fases não substitui os feitos novos.
- Condições e escudos contam turnos do beneficiário. Silk mantém parcelas de escudo entre combates, com os prazos restantes. Peter mantém sombras ofensivas que não bloqueiam dano.

Scarlet causa +10% de dano por carga de pólvora no alvo e mostra o contador até a detonação; Alice alterna naipes com dano híbrido; Snow quebra escudos; Umi cura por ricochete; Silk protege e retalia; Mulan usa combos e contra-ataques; Gretel aplica doses de veneno e maldição; João marca e executa seis estocadas; Lume fortalece fogo periódico; Aladin administra três desejos; Peter cria sombras por esquiva; Gato ganha dano pela porcentagem de vida faltante.

## Bônus da run

A especificação original está em [RogueTales_Bonus.md](docs/RogueTales_Bonus.md); os detalhes de integração e compatibilidade em [BONUS_098.md](docs/BONUS_098.md). Bônus não ocupam equipamento: Único (70%) exige escolher um personagem; Grupo (30%) alcança compatíveis atuais e futuros recrutados. Raridades comum/incomum/raro/épico/lendário/mítico: 40/28/18/9/4/1%, com valores exatos. Percentuais de dano e cura somam; crítico usa pontos percentuais. Iniciativa aceita direção positiva ou negativa, com prévia do resultado. Abrir ou cancelar não consome ouro/recompensa.

Saves anteriores preservam os atributos e efeitos legados, sem convertê-los em bônus novos. O histórico da build identifica esses efeitos. Espalhamento permanece fora do sorteio: dano secundário, seleção de alvos e interação com ricochetes aguardam definição, conforme o Markdown. Equipamentos e bênçãos mantêm seus catálogos e regras.

## Interface e arte

Retratos HD separados das células de animação de combate. Idles executam um gesto lento e aguardam 7–11 segundos; deslocamento usa pose estática. Efeitos das ULTs seguem seus alvos, com 16 cores de auras translúcidas, ícones de condições, bolhas de escudo e opção de movimento reduzido. As fichas PC/mobile exibem os atributos novos e permitem rolagem por toque.

A formação tem até três por posição: vanguarda, meio e retaguarda. A linha horizontal do Cortejo das Cartas atravessa essas posições. A abertura do estágio 1 é fixa: 1-1 tem um inimigo, 1-2 tem dois e 1-3 tem três. Depois, os encontros comuns desse estágio variam de um a três. Encontros comuns limitam-se a 6 no estágio 2 e 9 do estágio 3 em diante. Chefes, desafios secretos e infinito mantêm suas regras.

Após um chefe, se ninguém tiver sido recrutado nesta run, uma das três ofertas é garantidamente um personagem. O jogador pode escolher outra recompensa. Depois do primeiro recrutamento, convites voltam à chance comum de 25%.

Cada personagem equipa dois itens. A bolsa exibe aparência e descrição; trocas são feitas entre encontros. Ouro, desejos, recursos e equipamentos pertencem à run; coleção e feitos persistem.

## Executar e validar

Abra `project.godot` no Godot 4.7. A cena principal é `scenes/main.tscn`.

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/rules_095.gd
godot --headless --path . --script res://tests/boons_095.gd
godot --headless --path . --script res://tests/integration_095.gd
python3 tools/check_095.py --godot /caminho/para/godot
```

`integration_095.gd` exercita as 48 combinações contra chefes, checkpoints, desbloqueios e a cena real. Com renderização nativa e um diretório após `--`, captura as telas PC/mobile para revisão. O runner também valida arte HD, auras, toque, recrutamento, economia, equipamentos, formações e interface. Testes históricos de regras substituídas são identificados em `tests/README.md`.

O preset **Android Teste** exporta APK arm64, código 18, versão 0.9.8-teste, pacote `com.jtabosa.roguetales.preview.v07`. Use a mesma chave das versões anteriores para instalar como atualização. Chaves e SDKs não são versionados.

## Código

- `run_bonuses.gd`: tabelas, sorteio, elegibilidade, prévias, aplicação e persistência.
- `roster_data.gd`: atributos e descrições consolidados.
- `combat_rules.gd`: dano, condições, escudos, kits, desejos e sobrevivência.
- `battle_flow.gd`: rodadas, iniciativa, sequências e interrupções de ULT.
- `hero_blessings.gd`: bênçãos e desbloqueios persistentes.
- `run.gd` / `campaign.gd`: recursos, recompensas e salvamento.
- `tactics.gd` / `boss_rules.gd`: alvos, encontros e comportamento dos chefes.
- `expedition_ui.gd` / `interface.gd` / `character_inspector.gd`: navegação e apresentação.

Arte e áudio mantêm os créditos nas respectivas pastas de `assets/`. Não foram geradas novas artes nesta migração de regras.
