# Correções 0.9.7

## Aladin em combate

O handler da lista rolável bloqueava o evento de mouse emulado enquanto o dedo estava pressionado, mesmo quando o gesto era apenas um toque. O cartão nunca recebia o início do clique. O teste anterior chamava `try_ultimate` diretamente e não cobria esse caminho. O novo teste reproduz o bloqueio com o handler anterior e envia a sequência real de toque/pressão/soltura ao viewport para validar a correção.

Toques passam ao cartão; arrastos continuam rolando sem ativar o especial. A soltura do arrasto limpa a supressão de eventos para não bloquear outros botões. Barras decorativas de PV/mana também deixam o clique chegar ao cartão. A informação do personagem e os botões de itens conservam seus próprios destinos.

O cartão mostra **Usar desejos**, sem depender de mana ou do Aladin estar vivo. O menu apresenta **Ressurreição**, **Abate** e **Riqueza**, preservando os IDs e limites de uso por run. Abrir o menu pausa a luta; fechar retoma o estado anterior. Ressurreição restaura a presença visual dos personagens efetivamente revividos, sem reiniciar a animação dos aliados que já estavam vivos. Abate mantém as regras de inimigos normais e chefes.

## Ult da Silk / Rapunzel

O atlas antigo da ult tem recortes que incluem partes de poses vizinhas; a ordem anterior também repetia a segunda pose quase a execução inteira. A apresentação agora usa a sequência intacta de 12 quadros do casulo já existente, normalizada para o mesmo corpo do idle. Nenhuma imagem foi recriada ou reduzida.

O corpo permanece ancorado e os fios são desenhados como trajetórias animadas no chão até os aliados. Raízes pequenas acompanham os escudos; não se estica mais um quadro do atlas ao longo de uma diagonal. Escudo, bônus defensivo, custo, alvos e instante mecânico de impacto permanecem os mesmos. O teste percorre a execução inteira em 1×, 2× e 3×, verifica os quadros distintos, posição, escala, um único ganho de escudo e retorno ao idle.

## Validação

`tests/wishes_silk_097.gd` usa a cena real em PC e celular, cliques e toques emulados reais, os botões de escolha e os callbacks de impacto. Com um diretório após `--`, salva capturas de desejos e de etapas da ult para revisão visual. O runner completo `tools/check_095.py` inclui esta regressão e as suítes anteriores. Exportação Android arm64 0.9.7-teste, código 17, com o mesmo pacote e chave de teste das versões anteriores.
