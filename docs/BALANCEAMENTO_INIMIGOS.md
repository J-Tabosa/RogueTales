# Balanceamento por Excel

Edite **[data/inimigos.xlsx](../data/inimigos.xlsx)**. A aba `Inimigos` contém 79 fichas: 48 inimigos dos oito biomas, os três chefes usados nas expedições, 12 desafios secretos e 16 monstros exclusivos das quatro florestas iniciais. Veja [Fase 1](FASE1_INIMIGOS.md) para as novas bases e animações. A aba `Guia` explica os campos. As células amarelas aceitam edição; as cinza identificam o cadastro existente.

## Aplicar alterações

1. Abra `data/inimigos.xlsx` no Excel ou LibreOffice.
2. Altere os valores na aba `Inimigos` e salve no mesmo arquivo, em formato `.xlsx`.
3. Inicie o próximo combate. O jogo relê a planilha ao criar os inimigos, inclusive durante uma run aberta. Inimigos já em combate mantêm seus atributos até o fim do encontro.

Não é necessário exportar CSV, instalar Excel na máquina que executa o jogo ou executar um conversor. No Google Sheets, importe a planilha, edite e baixe novamente como **Microsoft Excel (.xlsx)**, substituindo o arquivo do projeto. A edição online sozinha não altera o arquivo local.

Nos executáveis de PC produzidos pelos presets deste projeto, também é possível colocar uma cópia chamada `inimigos.xlsx` **ao lado do executável**. Essa cópia tem prioridade sobre a versão embutida e é conferida entre encontros. Remova-a para voltar à versão embutida. Durante execução no editor, o jogo usa `data/inimigos.xlsx`.

No Android, a planilha faz parte do APK; edite a planilha e exporte uma nova versão. Os três presets de exportação incluem `data/*.xlsx`. O jogo continua funcionando sem acesso à internet.

## Campos

| Campo | Significado |
| --- | --- |
| `id` | Chave permanente do cadastro. Não renomear, duplicar ou remover. |
| `tipo`, `bioma`, `classe` | Referências do inimigo existente. A classe determina alvo e tipo de dano; sua alteração é rejeitada. |
| `nome` | Nome exibido no combate. Não troca a arte nem as habilidades; itens que reconhecem bruxas e feras continuam usando as regras de identificação pelo nome. |
| `vida_base` | Vida de referência antes da progressão do encontro. Deve ser positiva. |
| `ataque_base` | Dano bruto de referência por golpe: mágico para `mage`, físico para as outras classes. Zero é permitido. |
| `def_fisica_base`, `def_magica_base` | Pontos de defesa iniciais, somados ao crescimento já existente. Zero é permitido. |
| `iniciativa` | Ordem na rodada, com teto 100 e valores negativos permitidos. Não concede ataques extras. |
| `qtd_ataques` | Quantos ataques o inimigo executa em sua própria vez: inteiro de 1 a 20. |
| `esquiva` | Probabilidade entre 0 e 0,8. A célula exibe porcentagem: digite `10%` para 0,1. |
| `intervalo_visual` | Intervalo usado pela apresentação do ataque, em segundos. A sequência de turnos continua sob controle de `battle_flow.gd`. |

Vida e ataque preservam a curva atual de dificuldade: profundidade, encontros de elite, acompanhantes e endless continuam aplicados. Se o ataque-base de uma ficha passar de 13 para 26, seu dano bruto dobra na mesma dificuldade. O dano recebido pelo alvo ainda depende de defesas, esquiva e efeitos.

As bases comuns de vida são `86 × 0,72 × Biomes.HP[variante]`; ataque `13 × Biomes.POWER[variante]`. Os chefes usam bases de vida `86 × 1,5 × 0,70` e ataque `13 × 1,2`. Os secretos usam `86 × 1,5` e `13 × 1,32`, com o acréscimo original de 12 na profundidade. As defesas mantêm seu crescimento original por estágio ou profundidade. Os números fornecidos na planilha preservam o balanceamento anterior.

Estandarte de Ferro, Fio Rubro e Fio Violeta herdam a ficha do inimigo comum sorteado para aquela posição. Suas regras continuam aplicadas depois do balanceamento: o estandarte não causa dano e os fios causam 60% do dano herdado. As campanhas legadas anteriores às expedições conservam seus atributos originais.

## Cadastro e validação

Mantenha a aba `Inimigos`, os cabeçalhos e todas as linhas cadastradas. É possível filtrar, ordenar as linhas e reorganizar as colunas; a leitura usa cabeçalhos e IDs, sem depender da posição da linha. Use valores literais; fórmulas na tabela de integração são rejeitadas para evitar resultados desatualizados de cálculo.

Adicionar uma Gosma requer cadastrar seu ID e sua participação nos encontros, além de definir arte e comportamento. Acrescentar apenas uma linha desconhecida à planilha não cria uma criatura no jogo. Ao ampliar o catálogo, atualize `enemy_balance.gd` e acrescente a ficha correspondente ao Excel, preservando as alterações de balanceamento já feitas nas outras linhas.

Arquivos corrompidos, campos obrigatórios vazios, IDs desconhecidos ou repetidos, linhas faltando e valores fora das faixas são rejeitados como um conjunto. O jogo mantém o último carregamento válido na mesma sessão e registra o motivo no console. Se ainda não houve carregamento válido, usa os atributos originais. Uma correção salva é reconhecida no combate seguinte. O leitor aceita strings compartilhadas, texto inline, entidades XML e abas identificadas pelas relações do próprio XLSX; não exige bibliotecas adicionais.

## Validação técnica

`tests/enemy_balance.gd` lê o arquivo entregue, compara o crescimento dos encontros com as fórmulas originais, altera cópias XLSX e verifica vida, dano, defesas, iniciativa, esquiva e três ataques reais na própria vez. Também testa texto compartilhado/inline, leitura dentro de PCK, dados inválidos e recuperação. `tests/encounter_difficulty.gd` e `tests/rules_095.gd` cobrem os limites de encontros e as regras de combate afetadas.

```bash
godot --headless --path . --script res://tests/enemy_balance.gd
godot --headless --path . --script res://tests/encounter_difficulty.gd
godot --headless --path . --script res://tests/rules_095.gd
```

Os testes desta alteração foram executados em Godot 4.6.1 headless; o projeto permanece configurado para Godot 4.7. Não foi gerado um APK ou executável nesta alteração.
