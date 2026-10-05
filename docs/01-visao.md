# 01 — Visão do Jogo

> Nome provisório: **Farm Collect**. Nome final está em aberto (ver [09-decisoes-e-perguntas.md](09-decisoes-e-perguntas.md)).

## Pitch

Um jogo **cozy, casual e incremental** de fazenda no estilo "idle arcade": você anda pela fazenda,
coleta o que os animais e plantações produzem, empilha os itens nas costas, leva até o balcão,
vende para clientes, pega o dinheiro e usa para desbloquear e melhorar tudo. A fazenda cresce
diante dos seus olhos — e um dia vira um império com fábricas processando seus próprios produtos.

É o jogo que os anúncios "fake" do Township prometem — só que de verdade.

## Pilares (toda decisão de design passa por aqui)

1. **Dopamina constante** — algo bom acontece a cada poucos segundos: itens voando para a pilha,
   dinheiro estourando, barra de desbloqueio enchendo, número subindo. Nunca uma tela parada.
2. **Fácil e gostoso de jogar** — um único controle (mover). Coletar, entregar e pagar acontecem
   automaticamente ao pisar nas áreas. Zero menus obrigatórios para o loop principal.
3. **Progresso visível** — cada compra muda o mundo fisicamente (nova cerca, novo animal, área nova).
   O jogador vê a fazenda crescer, não só um número.
4. **Incremental de verdade** — upgrades, árvore de passivas e automação fazem o jogador sentir
   que ficou ordens de grandeza mais forte do que no começo.
5. **Leve** — roda liso em celular médio e em qualquer PC/Steam Deck. Build pequeno.

## Referências

| Referência | O que pegamos |
|---|---|
| Anúncios do Township (imagens em `docs/referencias/` quando adicionadas) | Visual low-poly, pilhas de itens, zonas "SELL", dinheiro empilhado, caminhões de pedido |
| Gênero "idle arcade" (My Mini Mart, Idle Farm Arcade, etc.) | Andar + empilhar + pads de desbloqueio que drenam dinheiro |
| Jogos incrementais (Cookie Clicker, Idle Miner) | Curvas de custo exponenciais, árvore de passivas, ganhos offline |

**Regra legal:** nada de nome, logo, personagens ou assets do Township. Só a ideia de gameplay.

## Público

Jogadores casuais e cozy (mobile e Steam), fãs de jogos incrementais/idle, sessões curtas
(5–15 min no celular) e longas (Steam, deixar rodando).

## Plataformas

PC (Steam, incluindo Steam Deck) primeiro → Android → iOS. Possível build Web para demo/anúncio jogável.

## Escopo

### v1 (lançamento) — Fazenda
- Fazenda que começa pequena e expande por áreas.
- Produtores: plantação de trigo, galinhas (ovos), vacas (leite).
- Balcões de venda, clientes, caminhões de pedido.
- Upgrades com dinheiro, árvore de passivas, ajudantes e máquinas de fazenda (automação).
- Ganhos offline, save, configurações, dev mode.

### Futuro (a arquitetura já prevê, não implementar agora)
- **Fábrica**: segunda localidade que processa produtos da fazenda (ovo → caixa de ovos, leite → queijo,
  trigo → pão, porco → bacon). O jogador decide quanto da produção **vende** e quanto **transfere** para a fábrica.
- Mais animais/plantações, prestígio ("nova temporada"), eventos sazonais.

### Fora de escopo
- Multiplayer, combate, construção livre em grid estilo Township real, energia/stamina que trava o jogador.
