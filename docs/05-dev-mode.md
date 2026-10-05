# 05 — Dev Mode

Painel dentro do jogo para mexer em qualquer valor **ao vivo** enquanto joga, testar progressão rápido
e salvar o balanceamento ajustado de volta no projeto.

## Acesso

- Tecla **F1** (ou `'`/`~`) abre/fecha. No mobile/Deck: tocar 5× no canto superior esquerdo.
- Disponível **apenas** em builds de debug (`OS.is_debug_build()`) ou exports com a feature tag `dev`.
  Em builds de release o autoload `DevMode` se desativa e o painel não existe.
- O jogo continua rodando com o painel aberto (pode pausar pelo próprio painel).

## Abas

### Status (o coração do dev mode)
- Lista **todos** os status registrados no `Stats`, com busca por nome (ex.: digitar `carry`).
- Para cada status: **base · modificadores (lista com origem) · valor final**.
- Controles por status:
  - **Multiplicador** (slider 0.1× – 100×, campo numérico livre).
  - **Valor absoluto** (força um valor fixo).
  - **Base** (edita o valor base, que pode ser gravado no `stats.json`).
  - Botão de reset.
- Atalhos para os mais usados no topo: `production.yield` (farm item multiplier),
  `player.carry_capacity` (stack carry), `player.move_speed`, `sell.price`, `production.rate`,
  `customer.spawn_interval`.

### Economia
- Adicionar/definir dinheiro e estrelas (botões +100, +10K, +1M, campo livre).
- Multiplicador de custo de desbloqueios e upgrades (`unlock.cost`, `upgrade.cost`).

### Tempo
- Velocidade do jogo (`Engine.time_scale`): 0.1× – 10×.
- Pausar/avançar 1 frame.
- Simular tempo offline: "fingir que fiquei X horas fora" → abre o popup de ganhos offline.

### Progressão
- Desbloquear o próximo pad / todos / resetar desbloqueios.
- Definir nível de cada upgrade; comprar/remover nós da árvore de passivas.
- Definir nível e XP da fazenda.

### Spawn e mundo
- Gerar cliente agora, gerar caminhão agora.
- Encher/esvaziar containers (pilha do jogador, balcões, produtores).
- Teleportar para área.

### Debug visual
- Mostrar zonas (coleta, entrega, caixa, pads) com contorno.
- Overlay de FPS, draw calls, número de nós/itens visíveis.
- Overlay de taxa de renda ($/s ativo e automatizado).

### Save e presets
- Salvar, carregar, resetar save, exportar/importar o save em JSON.
- **Presets de balanceamento:** salvar o conjunto atual de overrides com um nome
  (ex.: `teste_carry_alto`) em `user://dev_presets/` e carregar depois.
- **Gravar no projeto:** rodando a partir do editor, grava os valores base editados de volta em
  `res://data/balance/*.json` (com confirmação e mostrando o diff). Assim o ajuste feito jogando vira o balanceamento oficial.
- **Recarregar balanceamento:** relê os JSON do disco sem reiniciar (editar no VS Code → recarregar → testar).

## Como funciona por dentro

- Overrides do dev são uma camada no `StatSystem` (`set_dev_override`), aplicada por último na fórmula.
  Não tocam nos modificadores reais, então desligar o dev mode volta tudo ao normal.
- Overrides **não** vão para o save do jogador (ficam em `user://dev/session.json`, presets em `user://dev/presets/`),
  para não contaminar o progresso de teste. A sessão é restaurada ao abrir o jogo de novo; o selo "DEV ×N" lembra que há overrides ativos.
- "Aplicar na base" transforma o override atual em valor base (base × multiplicador, ou o valor fixo) — depois é só "Gravar bases no projeto".
- Implementado no M3: abas Status, Economia, Tempo, Mundo e Save e balanço. Progressão (desbloqueios/upgrades/passivas)
  e simulação de tempo offline entram junto com esses sistemas (M4–M6).
- Toda ação do painel passa pelos mesmos sistemas do jogo (`Economy`, `UnlockSystem`, …), então o dev mode
  também serve para testar esses sistemas.
- Status novos aparecem automaticamente no painel ao serem registrados em `stats.json`.
