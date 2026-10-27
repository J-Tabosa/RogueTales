# Progressão e correções — 0.9.10

Base: atualização de equipamentos 0.9.9. O catálogo de 27 equipamentos gerais, 12 utilitários dos vilões, ícones e efeitos foi preservado.

## Combates e rota

| Estágios | Máximo de inimigos comuns |
| --- | --- |
| 1–2 | 3 |
| 3–6 | 6 |
| 7 em diante | 9 |

A abertura continua 1/2/3 inimigos em 1-1/1-2/1-3. Todos os inimigos atuais, inclusive chefes e secretos, têm esquiva zero; a esquiva dos aliados permanece.

Cada estágio segue X-1 a X-4 com combate e recompensa; X-5 com escolha entre Mercador e Negociante; X-6 com chefe. Os dois comerciantes oferecem equipamentos, bônus e suprimentos pelas regras atuais. Visitar o mercado avança uma única fase, sem conceder recompensa de combate. Eventos opcionais podem anteceder combates e não substituem sua fase. A campanha completa tem 60 combates e 12 mercados, totalizando 72 fases. Chefes mantêm dois acompanhantes e desafios secretos continuam individuais.

## Equipe e coleção

Limite absoluto de cinco aliados, mantendo até três por posição. O mercador vende as expansões 3→4 por 150 ouro e 4→5 por 400; não existe compra da sexta vaga. Substituir um aliado continua permitido.

Todos os personagens de uma conta nova começam bloqueados e custam 5.000 memórias cada. A conta recebe 5.000 memórias iniciais para escolher e comprar seu primeiro personagem. A compra é permanente, valida saldo e propriedade e não pode ser feita durante uma tentativa pendente. Convites encontrados nas recompensas continuam válidos apenas para a run. Os feitos continuam registrados para bênçãos, sem desbloquear personagens gratuitamente.

Saves anteriores preservam coleção e saldo. Equipes antigas acima do limite mantêm o protagonista e priorizam aliados vivos até cinco; os demais ficam registrados como inativos no checkpoint. Seus equipamentos permanecem disponíveis na bolsa. A migração não é repetida ao recarregar.

## Alice e Umi

O crash da Alice vinha de notificações de dano periódico cuja origem era `item_alice`: a interface tentava buscar esse identificador no catálogo de personagens. A origem agora é normalizada para Alice, com nome seguro no histórico e validação antes de consultar retratos. Origens inimigas ou desconhecidas não entram na fila de retratos de heróis. O registro de condições também tolera dados antigos de turno ausentes ou malformados.

Umi tem Iniciativa base 50. Checkpoints anteriores recebem a diferença de +40 uma vez, preservando penalidades de equipamento e bônus; checkpoints novos registram a versão dos atributos para impedir reaplicação.

## Debug no PC

Configurações → Ferramentas DEBUG, ou Ctrl+B: liberar todos os personagens e habilidades; montar e testar uma run. Os 12 protagonistas e 48 bênçãos ficam disponíveis. A equipe de teste respeita cinco aliados e três por posição; os 39 equipamentos ficam na bolsa para equipar antes do primeiro combate.

O debug usa uma cópia temporária da campanha. Não grava compras, desbloqueios ou checkpoints no save normal. Desativar o debug restaura a coleção e a tentativa normal pendente. As ferramentas não aparecem no Android.

## Verificação

O runner canônico contém 26 suítes. As regressões novas incluem geração em todos os estágios, uma campanha completa, compras, migrações, combate da Alice com dois itens de condições negativas e isolamento do debug. A cena real também é renderizada em 540×960 e 1280×800, com compra por toque/clique e capturas para inspeção visual. A validação do APK confere versão, pacote, certificado, alinhamento e integridade; não substitui teste em aparelho físico.
