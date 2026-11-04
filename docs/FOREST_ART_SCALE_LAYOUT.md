# Arte, escala e formação das florestas

O lenhador recebeu oito quadros limpos via imagegen: contorno escuro, remoção da borda branca e transparência nos vãos entre braços e tronco. O atlas original gerado e seu prompt estão em tools/art_sources/phase1. O script tools/register_lumberjack_clean.gd só recorta e registra os pixels em telas de 768×768, alinhando o chão em y=640; não recolore a arte. Os oito PNGs de runtime continuam nos mesmos caminhos.

A referência de escala passa a ser o maior lado visível da primeira pose de cada família de animação, em vez da altura do recorte original de importação. Todos os inimigos comuns das quatro florestas ocupam o mesmo limite visual; lobos compridos ficam com a mesma largura, sem distorcer suas proporções. Chefes mantêm fator 1,25. Quadros posteriores, efeitos e composição do grupo não alteram a escala. Idle e ataque possuem referências próprias para compensar a diferença de resolução das fontes de aves e guaxinim. A medição ignora alpha abaixo de 10%, sem alterar os pixels apresentados.

Formação compartilhada por aliados e inimigos: uma unidade em 0,66; duas em 0,53/0,79; três em 0,40/0,66/0,92. Unidades derrotadas preservam o espaço durante o encontro. Projeção do chão, barras e hitboxes acompanham a formação.

Validação em Godot 4.7.2: phase1_enemies (11.623 verificações); phase1_visual (74 verificações), também com renderização OpenGL em 540×960 e 1280×800; arena_equipment_layout aprovado nos layouts PC/mobile. Conferência de transparência, limites de escala, quadros de impacto e retorno ao idle. Não foi gerado APK nesta alteração.
