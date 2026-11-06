# Recompensa e gestor de equipe

Correção incremental sobre a versão anterior às runas (`e1aaf16`).

- **Recompensa:** “Rodada vencida” centralizado, “Escolha uma melhoria” como subtítulo, sem contagem de pontos. O painel acompanha o centro da tela, limita a altura e rola somente as opções quando necessário.
- **Voltar:** a seta fecha o modal, mantém a batalha pausada e conserva as ofertas. “Escolher melhoria” reabre a mesma recompensa. Nenhum bônus é aplicado, descartado ou sorteado novamente ao voltar.
- **HUD:** faixa de quem ataca removida; estágio, fase, mapa e aviso de passiva preservados. Ouro sobreposto no canto superior esquerdo da arena e “Escolher melhoria” no superior direito. Arena ampliada para 984×726 no PC, com gestor mais estreito; passiva posicionada abaixo do ouro.
- **Gestor:** retrato quadrado à esquerda, moldura dupla chanfrada, divisores com losango, nome em serifa, botão de informação em losango, números dentro de vida/mana e espaço separado para escudo. Os dois espaços de equipamento e o acionamento de ULT/desejos mantêm os mesmos comandos.
- **Barras:** cantos arredondados, contorno preto de 2 px no gestor e números claros com contorno escuro nos dois temas. As placas sob os personagens usam raio de 6 px. Paletas, cores de raridade, cores por faixa de vida e regras de combate preservadas.

## Código

`scripts/reward_modal.gd` contém o painel de recompensa; `scripts/team_card.gd` desenha a moldura do gestor. Os ornamentos ficam em `assets/ui/team_card_rule.svg` e `assets/ui/team_shield.svg`, tingidos pela paleta ativa.

`scripts/expedition_ui.gd` conecta as recompensas e a seta. `scripts/interface.gd` posiciona o HUD e os cartões. `scripts/ui_theme.gd`, `scripts/theme_surface.gd`, `scripts/health_display.gd` e `scripts/tactical_arena.gd` preservam os cantos arredondados e a leitura dos recursos.

Foram removidos o painel da vez de atacar, `battle_text_box()` e suas cinco caixas separadas por personagem, as posições do ouro no cabeçalho e o uso do modal alto genérico na recompensa comum. O preenchimento retangular de `theme_surface.gd` deixou de cobrir as placas arredondadas. Este projeto usa controles nativos de Godot, sem CSS.

## Validação

Godot 4.7, temas claro/escuro, 1920×1080, 1366×768, 1280×720 e 390×844. `tests/reward_team_ui.gd` captura batalha e recompensa, verifica limites dos textos/barras e testa cliques reais na informação, na seta e em reabrir, comparando o checkpoint antes/depois.

Testes adicionais: `ui_themes`, `arena_equipment_layout`, `bonuses_ui_098`, `wishes_silk_097`, `rules_095`, `combat_readability` e `skills_equipment_102`. O workflow **Combat interface** publica logs e capturas no artefato de cada execução.
