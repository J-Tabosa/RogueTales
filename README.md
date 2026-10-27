# RogueTales: O Último Fio

Roguelite em **Godot 4.7**, PC e Android, com 12 protagonistas e equipes de até cinco. Versão **1.0.0**: 65 cenários HD das quatro estações, 17 percursos autorais, bifurcações por estação e oito mapas por run. Cada mapa mantém seis fases. Neve, chuva, raios de sol e brasas usam shaders; a ULT da Lume aquece as bordas da arena. Detalhes em [ROTAS_100](docs/ROTAS_100.md).

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

A equipe tem até cinco personagens e até três por posição: vanguarda, meio e retaguarda. A linha horizontal do Cortejo das Cartas atravessa essas posições. A abertura é fixa: 1-1 tem um inimigo, 1-2 dois e 1-3 três. Os limites dos encontros comuns são três nos estágios 1–2, seis nos estágios 3–6 e nove a partir do estágio 7. Chefes mantêm dois acompanhantes; desafios secretos são individuais. Todos os inimigos atuais têm esquiva zero.

Em cada estágio, X-1 a X-4 são combates com recompensas, X-5 oferece Mercador ou Negociante e X-6 é o chefe. Eventos aleatórios opcionais podem aparecer antes dos combates. Cada run começa em uma das quatro florestas, sorteada com chances iguais. As bifurcações seguem exatamente os percursos do pacote: oito mapas até o Castelo do Autor, com 40 combates e oito mercados. Mapas determinam cenário, clima e conjunto de inimigos. Os encontros de personagens do catálogo aparecem como convites opcionais após o chefe local.

Cada personagem custa 5.000 memórias para desbloqueio permanente. Contas novas começam com todos bloqueados e 5.000 memórias para comprar o primeiro. Coleções e saldos de saves anteriores são preservados. Convites de aliados continuam temporários durante a run; feitos liberam bênçãos, sem substituir a compra do personagem.

Após um chefe, se ninguém tiver sido recrutado nesta run, uma das três ofertas é garantidamente um personagem. O jogador pode escolher outra recompensa. Depois do primeiro recrutamento, convites voltam à chance comum de 25%.

A capacidade começa em três e aumenta pela **Página dos Viajantes**, item mítico consumido ao receber: +1 vaga nesta run, até cinco. A compra direta de vagas foi removida. A página não ocupa equipamento e deixa de ser sorteada ao atingir o teto. Cada personagem equipa dois itens. A bolsa exibe aparência e descrição; trocas são feitas entre encontros. Ouro, desejos, recursos e equipamentos pertencem à run; coleção e feitos persistem.

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

No PC, **Configurações → Ferramentas DEBUG** ou **Ctrl+B** permite liberar os 12 personagens e as 48 bênçãos, montar uma equipe de até cinco e iniciar uma run de teste com os 39 itens na bolsa. O teste usa uma campanha temporária; sair do debug restaura o progresso normal e a tentativa pendente. Essas ferramentas não aparecem no Android.

O preset **Android Teste** exporta APK arm64, código 21, versão 1.0.0-teste, pacote `com.jtabosa.roguetales.preview.v07`. Use a mesma chave das versões anteriores para instalar como atualização. Chaves e SDKs não são versionados.

## Código

- `world_routes.gd`: os 65 territórios e 17 percursos originais; validação dos prefixos e cache de cenários.
- `combat_atmosphere.gd`: clima por território e efeitos de tela; pausa e movimento reduzido.
- `run_bonuses.gd`: tabelas, sorteio, elegibilidade, prévias, aplicação e persistência.
- `roster_data.gd`: atributos e descrições consolidados.
- `combat_rules.gd`: dano, condições, escudos, kits, desejos e sobrevivência.
- `battle_flow.gd`: rodadas, iniciativa, sequências e interrupções de ULT.
- `hero_blessings.gd`: bênçãos e desbloqueios persistentes.
- `run.gd` / `campaign.gd`: recursos, recompensas e salvamento.
- `tactics.gd` / `boss_rules.gd`: alvos, encontros e comportamento dos chefes.
- `expedition_ui.gd` / `interface.gd` / `character_inspector.gd`: navegação e apresentação.

Arte e áudio mantêm os créditos nas respectivas pastas de `assets/`. Os 65 cenários fornecidos foram preservados byte a byte; os roteiros e hashes de origem estão em `docs/worlds/`. Saves de runs anteriores continuam nas suas 12 etapas originais até o encerramento. Novas runs usam as quatro estações.
