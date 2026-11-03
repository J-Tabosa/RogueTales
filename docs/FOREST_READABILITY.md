# Leitura do mundo 1

As quatro florestas iniciais usam ataques a 6 fps, ou 4,5 fps para coruja e falcão. Idle voador a 2,5 fps; demais a 4 fps. Tempos de impacto derivam da mesma taxa dos frames, mantendo contatos e dano sincronizados. Não houve alteração no seletor/global de velocidade, iniciativa ou quantidade de ataques; a apresentação de cada ataque inimigo ocupa mais tempo.

O primeiro estágio do Conto recebe 85% da vida e 80% do dano da planilha. A planilha segue editável e essa assistência é aplicada sobre seus valores. Infinito e demais mapas não recebem essa redução.

Impactos de espécies usam desenhos próprios: disparo para caçadores, onda de choque para javali/alce, arco verde para serpente e cortes para os demais. O atlas genérico antigo continua apenas para inimigos fora desse elenco.

Serpente: primeiro impacto acertado aplica atordoamento por uma ação, respeitando imunidades. A animação segura o quadro de contato e a posição do alvo durante 3,6 unidades de apresentação (1,2 s no seletor 2x atual). Não repete dano durante a pose. Pausar também congela a constrição.

Validação Godot 4.7.2 headless: phase1_enemies, 11.575 verificações; phase1_visual, 73 verificações, sem falhas. Inclui a arena real em layouts PC/mobile, quadros de impacto, pausa, posição da constrição, imunidade e expiração do stun. Não é teste em aparelho físico.
