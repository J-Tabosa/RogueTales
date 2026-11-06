# Recompensa e gestor de equipe

Correção incremental sobre a versão anterior às runas (`e1aaf16`).

- **Recompensa:** “Rodada vencida” centralizado, sem contagem de pontos. A moldura externa aumentou 32 unidades lógicas em largura e 66 em altura, com uma linha fina na cor do tema e 16 unidades de folga lateral até os cards. Os cards mantêm dimensões, padding, fontes, cores e intervalo de 8 unidades; “Salvar e sair” mantém seu tamanho, com 22 unidades após a lista. O título usa a variação real Cinzel 700 e o subtítulo “Escolha uma melhoria” usa a mesma família em 400. O painel acompanha o centro da tela, limita a altura e rola somente as opções quando necessário, reservando a barra de rolagem na folga lateral para não estreitar os cards.
- **Minimizar:** o botão “–” fica no canto superior direito, alinhado ao título e afastado do ornamento, com tooltip e nome acessível “Minimizar”. Fecha o modal, mantém a batalha pausada e conserva as ofertas. “Escolher melhoria” reabre a mesma recompensa. Nenhum bônus é aplicado, descartado ou sorteado novamente ao minimizar.
- **HUD:** faixa de quem ataca removida; estágio, fase, mapa e aviso de passiva preservados. Ouro sobreposto no canto superior esquerdo da arena e “Escolher melhoria” no superior direito. Arena ampliada para 984×726 no PC, com gestor mais estreito; passiva posicionada abaixo do ouro.
- **Gestor:** retrato alto à esquerda, moldura dupla chanfrada e informação em losango na linha do nome. À direita ficam vida, recurso e a linha de itens/divisor/status. O nome da habilidade fica no tooltip e na descrição de acessibilidade; clicar no status continua acionando a ULT/desejos pelo mesmo botão do card. As fontes usam a Lora existente; o status permanece em itálico. Os dois espaços de equipamento e o acionamento de ULT/desejos mantêm os mesmos comandos.
- **Barras do gestor:** formato hexagonal chanfrado sem arredondamento, contorno preto de 2 px, vida mais alta que mana, números claros com contorno escuro e escudo fora da vida. `character_resource_bar.gd` reaproveita `surface_texture` da interface, recortada dentro do preenchimento. As cinco cores semânticas já existentes são usadas em >75%, >50%, >30%, >15% e ≤15%, com transição de cor de 200 ms. A implementação anterior das barras era sólida; nenhum asset de textura novo foi criado. No PC, o card tem 146 px de altura, com vida de 25 px e mana de 20 px. No celular, mantém os 192 px e as barras de 30/24 px; os slots aumentam para 40×40 px. As placas de campo e as regras de combate não mudam nesta etapa.

## Código

`scripts/reward_modal.gd` contém o painel de recompensa; `scripts/team_card.gd` desenha a moldura do gestor. Os ornamentos ficam em `assets/ui/team_card_rule.svg` e `assets/ui/team_shield.svg`, tingidos pela paleta ativa.

`scripts/expedition_ui.gd` conecta as recompensas e o botão de minimizar. `scripts/interface.gd` posiciona o HUD e os cartões. `scripts/ui_theme.gd`, `scripts/theme_surface.gd`, `scripts/health_display.gd` e `scripts/tactical_arena.gd` preservam os cantos arredondados e a leitura dos recursos.

Foram removidos o painel da vez de atacar, `battle_text_box()` e suas cinco caixas separadas por personagem, as posições do ouro no cabeçalho e o uso do modal alto genérico na recompensa comum. O preenchimento retangular de `theme_surface.gd` deixou de cobrir as placas arredondadas. Este projeto usa controles nativos de Godot, sem CSS.

## Validação

Godot 4.7, temas claro/escuro, 1920×1080, 1366×768, 1280×720 e 390×844. `tests/reward_team_ui.gd` captura batalha e recompensa, verifica limites dos textos/barras, dimensões preservadas dos cards e do botão de saída, pesos da fonte e rolagem somente da lista. Testa cliques reais na informação, em minimizar e em reabrir, comparando o checkpoint antes/depois.

Testes adicionais: `ui_themes`, `arena_equipment_layout`, `bonuses_ui_098`, `wishes_silk_097`, `rules_095`, `combat_readability` e `skills_equipment_102`. A fixture também mostra o card da Mulan com 196/259 PV, escudo 59 e recurso 10/100. O workflow **Combat interface** publica logs e capturas no artefato de cada execução.
