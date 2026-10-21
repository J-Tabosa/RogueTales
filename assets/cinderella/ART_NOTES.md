# Arte provisória da Cinderela

A geração integrada de uma spritesheet própria foi bloqueada pelo serviço de imagens, inclusive após uma tentativa com figurino discreto. Não há spritesheet gerada para esta personagem.

- `cinderella_reference.png` é uma cópia **inalterada** da referência fornecida pelo usuário (1456 × 1088). O PNG completo contém a dupla original; o recurso nativo exibe somente a região da Cinderela.
- `cinderella_frames.tres` usa MeshTexture nativo da Godot, contorno poligonal, orientação espelhada para a direita e deformação de vértices para passos e arremesso de cristal. São poses provisórias da mesma ilustração, sem redesenho de partes ocultas e sem modificar os pixels da referência. O shader `reference_motion.gdshader` elimina resíduos vermelhos do fundo somente durante a renderização; o contorno e a animação continuam provisórios.
- Idle: quatro poses a 2 FPS, pausa de 4–8 segundos e balanço eventual. A piscada automática fica desativada (`blink_chance = 0`), pois não existe desenho de olhos fechados; `idle_blink` contém quatro espaços substituíveis.
- Walk e attack: quatro poses a 6 FPS. Não representam uma caminhada redesenhada completa; substitua as texturas por sprites próprias quando disponíveis.
- Cena: `scenes/heroes/cinderella.tscn`. Canvas 1000 × 600 e origem (360, 580); impacto em 48% da duração do ataque. FPS, escala, ordem e tipo de ataque continuam editáveis no Inspector.

A referência permanece com o figurino original. Não foi usado fallback de API nem geração externa. Os PNGs das outras heroínas foram criados no modo integrado ImageGen; esta personagem usa a referência e geometria nativa como placeholder.
