# Ficha de habilidades e equipamentos

## Ficha

- Cartões ilustrados, com nome e resumo atual do efeito/dano; duas colunas no PC e uma no celular.
- Botão circular `i` de pelo menos 44×44 abre a descrição e o cálculo completos. Passar o mouse sobre uma habilidade não abre a descrição automaticamente.
- Sprite grande à direita, olhando para a esquerda, também no layout mobile.
- Os onze atributos e o texto/formatação dos bônus acumulados da run foram preservados.
- 36 ilustrações (12 personagens × básica/passiva/especial), fornecidas por três atlas de 4×3 células, em `assets/ui/skills`. São usadas por `scripts/skill_art.gd` sem cópias ou recortes destrutivos.

## Chapeuzinho

Redução exata de 75% nos parâmetros adicionais de contorno, mantendo 25% do reforço anterior:

- Retrato: raio externo 1,4 → 0,35; reforço interno 0,45 → 0,1125 (corrigidos pela escala).
- Arena: raio na tela 1,2 → 0,3.
- Cena original: raio 3,5 → 0,875.
- Os parâmetros dos demais personagens e os arquivos de arte originais foram preservados.

## Equipamentos

- `Remover equipamento · espaço N` ocupa a largura do painel e tem texto destacado, no lugar do pequeno botão de menos.
- Um item usado por outro personagem continua selecionável. Equipar abre um aviso com o nome do atual usuário, destino e espaços envolvidos. Se necessário, também informa qual item do destino voltará à bolsa.
- `Não, manter` (ou ESC) fecha a confirmação sem alterar equipamentos, atributos, vida ou bolsa.
- `Sim, trocar` valida novamente personagens, espaços e fase, transfere exatamente uma cópia e atualiza o checkpoint/HUD.
- A vida atual não aumenta com a transferência; fica limitada ao novo máximo quando necessário. O item substituído permanece na bolsa.
- Combate e confirmações desatualizadas não permitem transferências. Rolagem por toque ao fundo é suspensa enquanto o aviso está aberto.
- Se houver mais de um usuário do mesmo tipo de item, o aviso identifica explicitamente o primeiro usuário na ordem da equipe. Só a cópia dele é transferida.

## Verificação

Godot 4.7.2. `skills_equipment_102.gd` aprovado sem renderização e com OpenGL Compatibility (Mesa llvmpipe), em 1280×800, 540×960 e 360×640. Inclui as 36 regiões distintas, botão de informação, sprite grande virado para a esquerda, transferência/cancelamento/remoção, toque com mouse emulado, checkpoint, ESC, bloqueio de combate e validação de confirmação antiga.

Também aprovados: `equipment_ui.gd`, `combat_readability.gd` (ajustado ao botão de informação) e `arena_equipment_layout.gd`.

São alterações no projeto; nenhum novo APK foi exportado nesta atualização. Sem teste em aparelho físico.

## Ajuste da ficha e tipografia

- Habilidades em coluna única em PC e celular, com uma frase de resumo própria por personagem e valores coloridos preservados.
- Nome acompanhado de Básico, Passiva ou Habilidade; os desejos manuais de Aladin são Especial.
- Informação em botão quadrado de 44 px com margem de 5 px nos quatro lados. Clicar/tocar fora fecha os detalhes; dentro mantém aberto; outro i troca o conteúdo.
- Goldman Regular como fonte global e Goldman Bold para destaques de combate. Fontes distribuídas com licença SIL OFL em assets/fonts/goldman/OFL.txt.
- Validado com Godot 4.7.2 em 1280×800, 540×960 e 360×640, incluindo renderização OpenGL e eventos de mouse/toque.
