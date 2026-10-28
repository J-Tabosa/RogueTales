# Consistência visual e inspeção de personagens

## Alterações

- A altura da arena depende somente do viewport. Três inimigos na mesma linha não reduzem mais a equipe inteira. As três posições fixas são espelhadas; barras dessas formações ficam ao lado dos pés.
- Humanos da coleção usam 248 px de altura visível e a mesma linha dos pés. Gato e Vendedora mantêm 62% e 75%. Os perfis de largura são compartilhados por coleção, combate e cenas editáveis.
- A propriedade dos pixels do spritesheet é calculada separadamente por fileira. Isso impede que a cabeça da fileira seguinte capture as botas da pose acima. Espera e caminhada mantêm altura e âncora constantes.
- Mulan e Ariel receberam novas folhas com o design preservado e traço ajustado; Branca recebeu outro redesign completo como cientista do veneno. João tem dez novos quadros de estocada: cabo curvo atrás da mão e ponta reta para a frente. Todos preservam 4 quadros de espera, 4 de piscada, 16 de movimento e 10 de ataque. Os efeitos aprovados foram preservados.
- Cada personagem tem uma imagem de corpo e um portrait isolados pela mesma máscara dos quadros. Nenhuma imagem da interface reaproveita um retângulo que possa conter partes de poses vizinhas. Os retratos continuam estáticos e compartilhados em cache.
- O botão **i** pausa e abre uma ficha responsiva: oito caixas de atributos atuais, personagem ao lado, cartões de automática, passiva e ULT e condições ativas. Fechar restaura o estado de pausa anterior. As descrições incluem os buffs da run.
- PC abre em tela cheia, incluindo migração do antigo padrão implícito de janela. Uma escolha explícita futura é salva. F11 é tratado pela janela nativa e pelo jogo, com proteção contra duplicidade. O combate tem botão F11. No editor embutido, a janela independente continua existindo ao alternar para janela para manter foco e teclado.
- **Configurações → Ferramentas DEBUG** (ou **Ctrl+B**) **→ Revelar todos os personagens → Animações** permite conferir os doze kits, inclusive os ainda bloqueados. A revelação é temporária; não altera desbloqueios ou o protagonista permitido da conta. Desativar debug volta a ocultar os não adquiridos.
- O carrossel controla o gesto completo de touch: arrastar não seleciona uma carta ao soltar; tocar continua selecionando.

## Arte e reprodução

As dez folhas novas e a correção da caminhada da Ariel foram criadas pelo gerador nativo de imagens usando Scarlet e Rapunzel como referência. Originais e prompts exatos estão em `old/source/revision_3/`. A pasta antiga continua excluída das importações/exportações por `old/.gdignore`.

A estrutura atual está documentada em `assets/characters/ART_PIPELINE.md`. Os onze personagens revisados usam WebP e `FRAME_LAYOUT.json`; os JPEGs substituídos foram removidos. `assets/characters/sources.json` mantém apenas o Gato, efeitos básicos, arenas e segredos ainda usados. Para reconstruir essas dependências JPEG e máscaras alfa:

```sh
GODOT=/caminho/do/godot python tools/build_art.py
```

## Validação

`tests/visual_consistency.gd` verifica F11 por eventos reais, tela cheia padrão, debug temporário, 34 quadros, altura/limites dos cartões, estabilidade da arena com três inimigos, oito caixas e números atuais das habilidades. Em uma sessão gráfica, acrescenta capturas em celular e PC:

```sh
godot --path . --script res://tests/visual_consistency.gd -- /caminho/capturas
```

As suítes existentes cobrem progressão, saves, combates, recrutamento, chefes, efeitos e formação. `tests/character_revision_visual.gd` confere os 16 quadros das caminhadas, toque real, ficha e duelos; `tests/art_integration_visual.gd` cobre os 12 mundos e efeitos. A validação mobile aqui usa viewports e eventos de toque; o aparelho físico continua sendo uma etapa separada.
