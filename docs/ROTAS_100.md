# Quatro estações — 1.0.0

O pacote fornecido traz 65 cenários de 1671/1672 × 941 pixels e 17 percursos completos: quatro de Primavera, quatro de Verão, quatro de Outono e cinco de Inverno. As imagens estão intactas em `assets/worlds/`; roteiros, catálogo e hashes SHA-256 do pacote estão em `docs/worlds/`.

## Jornada

A primeira floresta é sorteada com probabilidade de 25% por estação. Após o chefe e sua recompensa, o jogador escolhe o próximo território dentre os sucessores legais. O histórico inteiro da rota é validado: chegar a um cenário compartilhado não permite misturar trechos de percursos diferentes. Todas as rotas terminam no oitavo mapa, Castelo do Autor.

Cada mapa tem X-1 até X-6: quatro combates com recompensa, Mercador ou Negociante em X-5 e chefe em X-6. São 40 combates e oito mercados, em 48 fases. Eventos opcionais antecedem combates sem pular a fase. Os limites de inimigos continuam 3 nos mapas 1–2, 6 nos mapas 3–6 e 9 a partir do mapa 7. Chefes mantêm dois ajudantes; inimigos atuais não esquivam.

O terreno seleciona um dos oito conjuntos de inimigos existentes. Sua arte, nomes, categoria, atributos e intenções usam o mesmo conjunto. Os chefes reutilizam as mecânicas existentes, com a Costureira no Castelo do Autor. O catálogo não fornece novos kits de chefes ou inimigos; não foram criadas mecânicas adicionais para eles.

Pomar, Campo de Batalha, Ponte para o Castelo, Cidade Fria, Cavernas de Mineração, Navio Pirata, Oceano, Castelo da Rainha Vermelha, Cárcere de Princesa e Cidade Andante respeitam seus encontros definidos. Ao vencer o chefe local, o personagem indicado é garantido entre as recompensas se ainda puder ser convidado. O convite é opcional e temporário; o desbloqueio permanente continua custando 5.000 memórias.

## Arenas

Os cenários preservam a resolução e os pixels originais. Uma projeção por shader separa fundo e piso, usando a faixa de chão segura registrada para cada mapa. A formação conserva até três por posição, com os pés em profundidades 0,44/0,66/0,88; todas ficam dentro da faixa de chão projetada. A projeção recebe a proporção da arena ao redimensionar. Os personagens mantêm escala, enquadramento e ordem de profundidade; as barras ficam em uma camada própria.

O cache mantém no máximo três texturas de cenário, além das referências em uso pela interface, para evitar manter 65 fundos HD residentes no celular.

## Vagas

A equipe começa com capacidade três e tem teto absoluto cinco. A **Página dos Viajantes** é um item mítico de expansão: cada aquisição concede +1 vaga até cinco, uma vez por aquisição. É consumida imediatamente e não ocupa os dois espaços de equipamento de um personagem. Pode aparecer entre recompensas e nos sorteios do mercador, com raridade mítica; custa 550 ouro quando vendida. A compra direta antiga de vagas foi removida.

O item não é sorteado quando a capacidade já está em cinco. Ofertas salvas ficam desabilitadas no teto e não cobram ouro. Salvar e carregar preserva o número de páginas consumidas e a capacidade, sem reaplicar o efeito. Vagas antigas adquiridas são preservadas; a expansão não remove integrantes ao trocar equipamentos.

## Clima e efeitos

Neve em áreas frias abertas, chuva em locais úmidos e sombrios, feixes suaves de sol em mapas abertos e brasas em áreas vulcânicas. Cavernas e interiores cobertos não recebem precipitação externa. Os efeitos ficam dentro da arena, com transparência suficiente para manter personagens e barras legíveis.

A ULT da Lume aciona fogo transitório nas bordas ao atingir os alvos. A onda azul da Umi permanece. Pausar congela o relógio dos shaders; movimento reduzido mantém o clima estático e reduz a intensidade dos efeitos transitórios. Qualidade baixa usa uma camada de partículas. Os shaders não alteram regras, dano ou aleatoriedade do combate.

## Compatibilidade e validação

O save passa à versão 11, preservando coleção, memórias, equipamentos e desbloqueios. Uma tentativa anterior sem dados de estação continua sob sua rota antiga de 12 etapas; a próxima tentativa passa às estações. O infinito segue após a vitória no Castelo do Autor e inicia novos ciclos sazonais mantendo a build e a profundidade acumulada.

29 suítes canônicas aprovadas, incluindo os 17 percursos completos. Validação nativa em 540×960 e 1280×800: 130 arenas com 14 personagens, escolhas por toque/clique, item mítico e shaders compilados/renderizados. O APK conserva pacote e certificado anteriores; código 21 e versão 1.0.0-teste. A validação de exportação não substitui teste em aparelho físico.
