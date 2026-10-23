# Personagens, leitura de combate e duelos secretos

A formação aprovada continua com as mesmas posições. As folhas de animação agora têm limites por fileira: um quadro não pode puxar o pé da pose acima. Espera e caminhada usam a mesma altura visível e a mesma âncora dos pés. Mulan ganhou uma caminhada completa; o Gato usa 62% da altura humana, e a Vendedora continua com 75%. Os perfis de largura são compartilhados por arena, cenas editáveis e galeria. Rapunzel, Peter e Vendedora preservam seus desenhos aprovados.

Branca de Neve recebeu 34 quadros na temática de cientista do veneno: laço vermelho, cabelo preto, maçã, frasco verde, jaleco branco e roupa azul. Os originais e prompts estão em `old/source/revision_2`; a folha anterior está em `old/assets/snow_white`. Somente JPEG com máscara alfa PNG é carregado pelos novos sprites e chefes. `old/.gdignore` impede importação e exportação do acervo.

O botão **i** dos cartões abre os atributos atuais e pausa a batalha. Mostra PV, escudo, mana máxima, ataque, intervalo mínimo em 1×, crítico, armadura, esquiva, cura por acerto e as habilidades/passivas/ULTs com números. As descrições usam o mesmo ator modificado pelos upgrades da run. A coleção mostra números iniciais ou os valores atuais quando o personagem está na equipe. O intervalo considera o piso de 1,5 s e lentidão; animações e a fila podem adiar uma ação.

Caveira verde e chama ficam junto aos PV e podem coexistir. Cada indicador mostra dano por segundo; toque nele para ver duração e dano ainda pendente. Condições expiradas somem. A passiva de Mulan agora reage à esquiva: a condição antiga exigia guarda de vanguarda, embora sua classe seja assassina.

A velocidade alterna **1× → 2× → 3×** e fica salva. A galeria aceita arraste real de touchscreen sem selecionar um cartão durante o gesto. A opção de formação inicial foi removida. Tela cheia restaura tamanho e posição da janela; a execução embutida pelo editor usa uma janela nativa separada para tela cheia e devolve o jogo ao sair.

## Duelos pessoais

Uma rota de evento pode revelar um desafio se o personagem estiver vivo no bioma correspondente. Dentro de uma rota de evento, quando há um desafio elegível, metade dos sorteios prioriza os desafios pessoais. A rota continua opcional; recusá-la não tem penalidade.

Todos os duelos têm **um único chefe, sem lacaios**, com orçamento de vida/dano equivalente a 12 fases adiante e um ataque especial a cada três ações. Não substituem nem pulam a próxima fase normal. Ganhar concede **600 pontos, 75 + 5 × (mundo − 1) ouro**, o bônus pessoal abaixo e recupera 25% dos PV máximos do herói vencedor, se estiver vivo. Cada duelo só concede recompensa uma vez por run. O desafio ativo, a tela de recompensa, os atributos recebidos e os chefes já vencidos sobrevivem ao salvamento. O infinito mantém os bônus da mesma run.

| Herói | Bioma | Chefe | Bônus pessoal na run |
|---|---|---|---|
| Scarlet | Floresta | Lobo Mau | +25% dano; +10 pontos percentuais de crítico |
| Branca de Neve | Floresta / pântano | Rainha do Veneno | +25% dano; +4 mana por acerto |
| Rapunzel | Castelo / ruínas arcanas | Carcereira da Torre | +25% PV; +4 armadura |
| Mulan | Gelo / montanhas de Jade | General de Jade Sombrio | −20% intervalo; +10 pontos percentuais de crítico |
| Ariel | Costa | Bruxa da Maré Negra | +15% dano; +8 mana por acerto |
| João | Castelo | Duque do Açúcar | +25% dano; +10 pontos percentuais de crítico |
| Maria | Castelo | Condessa da Taça Vazia | +25% dano; +4 PV de cura por acerto |
| Alice | Castelo / ruínas arcanas | Rainha de Copas | +15% dano; +8 mana por acerto |
| Gato de Botas | Castelo / deserto | Carrasco das Nove Vidas | +25% PV; +20% dano |
| Vendedora | Fogo | Rei da Fornalha | +25% dano; +3 armadura |
| Peter Pan | Floresta / costa / pântano | Capitão da Âncora | +20% dano; +10 pontos percentuais de esquiva |
| Aladin | Deserto / ruínas arcanas | Vizir das Areias Violetas | +20% PV; +8 mana por acerto |

## Verificação

`tests/character_revision.gd` verifica os 12 desafios, disponibilidade, inimigo único, recompensa sem avançar fase, retomada sem duplicar bônus, números atuais, veneno, reação da Mulan e persistência de 1×/2×/3×.

`tests/character_revision_visual.gd` usa renderização real: 16 quadros de caminhada por personagem revisado em 540×960 e 1280×800; pares de condições e expiração; clique no botão i com o cartão de ULT desabilitado; arraste por eventos reais de touchscreen; apresentação dos 12 chefes e diálogos; recompensa/retomada; coleção numérica; tela cheia nativa e janela separada do editor. `tests/art_integration_visual.gd` cobre também os 12 mundos e os efeitos já existentes.

Execute os testes de lógica com `godot --headless --path . --script res://tests/character_revision.gd`. Para os visuais, use `godot --path . --script res://tests/character_revision_visual.gd -- /caminho/para/capturas` em uma sessão gráfica. A validação de celular usa viewport e eventos de touch; não substitui teste em aparelho físico.
