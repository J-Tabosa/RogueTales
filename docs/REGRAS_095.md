# Migração 0.9.5 — fichas de 26/10/2026

Os dois MDs originais estão preservados nesta pasta. `roster_data.gd` reúne os números e descrições; `combat_rules.gd` executa os kits. Não são usados os campos antigos de exportadores (`ultCoeff`, armadura percentual, mana por segundo etc.). Os IDs internos continuam `ariel`, `rapunzel`, `maria` e `matches` para preservar artes e saves; os nomes visíveis são Umi, Silk, Gretel e Lume.

## Convenções de implementação para pendências dos MDs

Estas convenções viabilizam a execução e **não representam novas decisões finais de balanceamento**:

- Desempates de iniciativa mantêm o critério já usado pelo projeto: aliados primeiro, depois índice estável no grupo. Ressaca reordena somente quem ainda não começou sua vez. A ordem de quem já agiu permanece.
- PV, danos e mana conservam frações em ponto flutuante. O híbrido soma as parcelas mitigadas antes do piso único de um. A interface arredonda para apresentação. Defesas negativas ficam em zero até haver regra de amplificação aprovada.
- Dano real ignora somente as defesas: reduções explícitas, imunidade, esquiva de ataques diretos e escudos continuam válidos. Dano periódico não esquiva, critica ou gera mana por impacto.
- Início da vez: encerra proteção até a próxima vez, renova limites próprios, envelhece escudos; tenta escape da maldição; resolve condições na ordem estável em que foram aplicadas; aplica controles, recuperação da Lume e mana por vez. Condições expiram no fim da vez, preservando o debuff durante as ações do último turno.
- Duração de escudos: cinco próximas vezes do beneficiário, por parcela. Consumo em ordem de aplicação (FIFO). Somente parcelas de Silk persistem entre encontros; nunca recebem duração nova. Bônus de Defesa Mágica acompanha especificamente a parcela da ult. O bônus é fotografado antes de aplicar ao grupo para não se amplificar durante o próprio laço.
- Quebra-Escudos reduz novas aplicações em 50%; não destrói parcelas existentes. Corta-Cura não acumula com outra fonte igual. Maldição forte perde seus componentes associados quando o alvo escapa da maldição.
- Condições de dano de fontes diferentes conservam a origem. Reaplicação da mesma fonte renova a condição; limites próprios de Gretel, Lume e João continuam separados. Bolha, Ressaca e Sangramento não acumulam.
- Sono para a condição aleatória da Alice usa a convenção provisória isolada de 50% de perder a vez, por um turno. O MD não define um padrão global final. Veneno genérico usa 10% do Dano Mágico por dose; fogo usa a referência da Lume. Essas escolhas estão concentradas nas funções de condição para revisão posterior.
- Alice resolve empate dos atributos de Espadas pelo físico; híbrido usa uma rolagem crítica por impacto, mantendo ambas as parcelas. Naipes seguem Ouros → Copas → Paus → Espadas. Coringa não alimenta o contador nem o recurso.
- Peter com a bênção inicial começa com **pelo menos uma** sombra, preservando as que já tiver; recuperar sombra do agressor só é testado pelo básico do próprio Peter. Esses dois pontos são explicitamente pendentes no MD.
- O sistema configurável de prioridades continua pendente. Mantém-se a prioridade existente de alvos válidos: vanguarda passa à posição seguinte quando vazia; atiradores preferem retaguarda; assassinos agora podem escolher nas três posições. Seleção secundária é estável e usa proximidade para fragmentos. O jogador pode apontar um alvo válido; Mulan/Gato usam a coluna desse alvo, Alice usa sua linha.

## Compatibilidade e apresentação

Os campos legados `damage` e `armor` continuam como adaptadores dos bônus existentes. `physical_damage`/`magic_damage` são os atributos independentes; o multiplicador legado escala ambos. `armor` conserva os pontos de Defesa Física obtidos por itens/upgrades, sem impor defesa inicial às classes novas. Magia não ignora uma porcentagem arbitrária da armadura.

O upgrade antigo de intervalo e o relógio foram convertidos em Iniciativa (+10 e +15, respectivamente), sem dar ações extras. Removidas as 36 mutações antigas das ofertas: elas contradiziam as fichas novas e não podem somar outras bênçãos. Eventos que ofereciam duas mutações aposentadas usam seu fallback já existente de 15 ouro por opção (30 no total); a descrição foi atualizada. As antigas sinergias por tempo não adicionam golpes ou consumo de sombras às fichas consolidadas.

Checkpoints preservam mana sem teto artificial, contadores de Alice/Mulan, sombras, desejos, retornos do Gato, usos por estágio e as parcelas de escudo com duração restante. Coleção, itens e chave Android mantêm sua identidade. Saves anteriores continuam reconhecidos, mas as regras passam a ser as novas; não é possível prometer o mesmo equilíbrio da versão anterior após esta substituição de fichas.

Desejos possuem menu manual pelo cartão de Aladin e nas telas de caminho/equipe/mercador. Vida funciona com Aladin morto, Riqueza usa `200 × (estágio + 1)` e Morte fotografa seu poder antes de gastar a carga. Desejos nunca entram na fila automática de ULTs.

## Validação e pontos de design restantes

Os testes novos verificam fórmulas, imunidades, recursos, limites, persistência e os kits/bênçãos. A integração exercita as 48 combinações com chefes reais e revisa a interface renderizada em 1280×800 e 540×960. O APK é verificado por assinatura, alinhamento e integridade do pacote; isso não equivale a um teste físico no celular.

Nove alvos de Scarlet, o escudo 200 de Silk e a economia provisória de Riqueza mantêm os requisitos exatos; os testes não afrouxam os desbloqueios para torná-los mais fáceis. O sistema de prioridade configurável, as convenções acima e os nomes ainda sugeridos nos MDs permanecem abertos para decisão de design. As artes atuais são reutilizadas para os novos efeitos mecânicos.
