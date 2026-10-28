# Chapeuzinho / Scarlet — redesenho de 28/10/2026

Originais fornecidos pelo autor na conversa de redesenho: cabelo loiro
espetado, capa vermelha, detalhes dourados e bombas com caveira rosa.

- `idle.png`: ChapeuzinhoVermelhIDLE.png, oito poses.
- `attack.png`: ChapeuzinhoVermelhAATK.png, doze poses.
- `ultimate.png`: ChapeuzinhoVermelhoUlt.png, dezesseis poses.
- `portrait.png`: recorte transparente HD do mesmo desenho, 1024 × 1536.

Os PNGs originais são preservados sem alterações; SHA256.json permite conferir
as fontes. Esta pasta não é importada nem exportada pelo Godot.

Reconstruir apenas Scarlet, com Pillow/numpy/scipy instalados:

```bash
GODOT=/caminho/do/godot python3 tools/import_scarlet_redesign.py
```

O analisador identifica corpos inteiros antes de atribuir bombas e cestos
destacados. O Godot remove o fundo verde, preserva as poses e gera WebP
lossless com uma escala por animação, apoio nos pés e células acolchoadas.
A ULT usa os dezesseis quadros em ordem, sem repetir a antiga pose de cast.
Seleção, equipe e avisos de passiva/ULT usam o retrato HD e seu recorte facial.
As pausas do idle, a pose estática no deslocamento e as regras de combate
permanecem as já definidas.
