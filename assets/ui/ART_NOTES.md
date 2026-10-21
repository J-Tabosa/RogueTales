# Floresta encantada — interface RogueTales

Seis artes originais foram geradas com a ferramenta integrada `image_gen`, para uso no projeto:

| Arquivo | Uso |
| --- | --- |
| `wood_panel.png` | Molduras dos painéis, atributos, melhorias e arena |
| `wood_button.png` | Botões, navegação e cartões de escolhas |
| `gold_wallet.png` | Placa de ouro no cabeçalho |
| `world_map.png` | Mapa ilustrado dos oito reinos |
| `logo.png` | Nome RogueTales em letras bolha coloridas |
| `enchanted_forest.png` | Fundo das telas e transições entre capítulos |

Direção: madeira de nogueira, heras esmeralda, detalhes em ouro e uma atmosfera de conto de fadas animado. Nenhum asset oficial de estúdio foi utilizado. Os PNGs finais foram copiados diretamente da geração e preservados, incluindo o canal alfa; não houve retoque ou redução destrutiva dos originais. O texto da interface permanece nativo, renderizado pela Godot e editável no código e independente das imagens, exceto pelo wordmark RogueTales.

Os prompts finais completos e o método de geração estão em `PROMPTS.json`. `scripts/ui_skin.gd` configura regiões de atlas para ignorar margens transparentes e nove fatias para manter cantos e bordas proporcionais. O importador da Godot limita as texturas da UI a 768/1024 px e fundos a 1536 px, com mipmaps. Isso preserva os arquivos de arte completos no repositório e evita texturas desnecessariamente grandes na GPU.
