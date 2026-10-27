# Bônus — integração 0.9.8

Fonte normativa: `RogueTales_Bonus.md`, preservada integralmente. Equipamentos (dez comuns e doze troféus), dois espaços, 48 bênçãos e kits não foram rebalanceados nesta etapa.

## Sorteio e valores

As vagas antes preenchidas por relíquias genéricas recebem Bônus. Recrutamento continua 25% por tela e garantido no chefe quando ninguém foi recrutado; equipamentos continuam 40% nos encontros comuns e garantidos nos chefes; três opções permanecem. A vaga genérica da loja usa o mesmo sistema, pelo preço anterior de 32 ouro, com confirmação antes da cobrança.

Cada vaga rola primeiro raridade (40/28/18/9/4/1), depois modalidade (70/30), de forma independente. Sorteia uniformemente entre os atributos válidos. Não há segunda rolagem numérica. Espalhamento está explicitamente desativado, inclusive Único, até o autor definir coeficiente, alvos e interações. Ataques comuns/incomuns não existem; de Grupo só lendário/mítico. Não existe Aumento de Escudo.

Fallback limitado: se não houver atributo útil no modo sorteado, tenta o outro modo **mantendo a mesma raridade**. Se ambos falharem (equipe vazia/inválida), devolve ausência de oferta sem laço/re-rolagem. Numa equipe válida, mesmo caída, Vida Máxima e defesas sempre fornecem alternativa útil, portanto mantêm-se as três opções.

## Combate e interface

Acumuladores `bonus_totals` são separados dos atributos base e dos modificadores de equipamento. Dano físico/mágico e cura somam percentuais; defesas, ataques e mana somam valores absolutos. Chance crítica/esquiva somam pp com tetos 100%/80%. Multiplicador crítico soma pp absolutos sem teto novo. Bônus de dano mágico funciona nas fontes compatíveis da Silk (proteção e retaliação); ela não recebe mana por acerto nem bônus cosmético de crítico. Aumento de Cura exige uma fonte atual real: Umi, Alice, caminho de cura da Lume, roubo de vida ou cura por abate/equipamento. A multiplicação ocorre na cura produzida, antes de Corta-Cura, sem aumentar escudos diretamente. Excedente da Umi mantém seu teto.

Iniciativa é calculada com teto 100, sem limite inferior, incluindo penalidades e restauração do atributo bruto. Grupo usa um sinal único. Prévia considera condições e tetos por personagem. A UI exige personagem para Único e sentido para Iniciativa; abre sem aplicar e confirma atomicamente. Voltar preserva a oferta original. Caídos são identificados e não revivem. Listas usam o mesmo componente de rolagem por toque da ficha.

Fundos e bordas: Comum cinza, Incomum verde, Raro azul, Épico roxo, Lendário laranja, Mítico vermelho. Nomes continuam visíveis, além da cor, nas ofertas, confirmação, loja e histórico da build.

## Persistência e compatibilidade

Checkpoint `bonuses` formato 1 contém serial dos IDs, histórico (atributo/modalidade/raridade/magnitude/sinal/alvo), acumuladores individuais e ledger `bonus_applied`. Cada grupo é aplicado uma vez por personagem, incluindo novos recrutados compatíveis. HP é alterado uma vez na aquisição, mantendo a vida faltante ou zero dos caídos; carregar restaura metadados sem repetir efeitos ou cura. Trocar equipamentos não altera os acumuladores.

Relíquias antigas **não são convertidas**: os atributos, contagens, template para futuros recrutas e efeitos originais continuam preservados pela restauração legada. A build os identifica como “Bônus legados · efeitos originais preservados”. Ofertas antigas já salvas permanecem resgatáveis nas regras antigas. Novos sorteios usam apenas o sistema 0.9.8. Assim não se apagam saves nem se inventa um mapeamento mais forte para cura fixa/efeitos mistos.

## Validação

O runner `tools/check_095.py` inclui duas suítes 0.9.8 e mantém as regressões de combate, bênçãos, 48 combinações de chefe, retratos HD, animações, auras, toque, dificuldade, recrutamento, eventos e equipamentos. Testes de UI/economia passam a confirmar os novos bônus em vez de simular concessão imediata. Capturas nativas em 540×960 e 1280×800 verificam fundos, enquadramento e rolagem. A validação do APK verifica versão/código, assinatura da chave anterior, alinhamento e integridade ZIP; não substitui teste em aparelho físico.
