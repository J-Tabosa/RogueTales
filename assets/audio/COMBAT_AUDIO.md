# Áudio de combate

`explosion.wav`: ruído filtrado e grave descendente, 0,55 s.
`victory.wav`: acorde e arpejo ascendente, 1,37 s.
`achievement.wav`: fanfarra de sinos agudos, 1,62 s.
`attack_*.wav`: cinco chamadas não verbais sintéticas, feitas com eSpeak NG (variantes femininas) e filtradas com FFmpeg. Não são gravações nem imitações de atrizes. Os WAVs estão incluídos; eSpeak e FFmpeg só são necessários para regenerá-los.

Reprodução: seis players de efeitos e dois de voz reutilizados. Uma chamada por princesa a cada quatro segundos, com intervalo global mínimo de 0,45 s. Música, efeitos e vozes têm volumes independentes persistidos. A explosão ocorre no impacto da bomba; a voz no início do ataque; os jingles acompanham a vitória e o resgate de uma conquista.

Para regenerar: `python tools/make_combat_audio.py` (Python padrão, eSpeak NG e FFmpeg). A síntese usa semente fixa; nenhum serviço de rede é usado durante o jogo.
