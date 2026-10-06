# 03 — Economia e Balanceamento

Todos os números abaixo são o **ponto de partida (v0)**. Eles serão ajustados jogando, via dev mode
(ver [05-dev-mode.md](05-dev-mode.md)). A fonte da verdade no projeto são os arquivos em `data/balance/`.

## 1. Moedas

| Moeda | Como ganha | Onde gasta |
|---|---|---|
| **Dinheiro** ($) | Vendas, caminhões, offline | Pads de desbloqueio, upgrades |
| **Estrelas** (★) | Subir de nível da fazenda | Árvore de passivas |
| *(futuro)* Sementes de ouro | Prestígio | Bônus permanentes |

Números grandes formatados: 1.2K, 3.4M, 5.6B, 7.8T, depois aa, ab, ac…

## 2. Fórmula de status

Todo valor de gameplay é um **status** (ver [04-arquitetura.md](04-arquitetura.md#3-sistema-de-status-e-modificadores)):

```
final = (base + Σ flat) × (1 + Σ percent) × Π multiplier
final = clamp(final, min, max)
se dev override ativo:  final = override_absoluto  OU  final × override_multiplicador
```

- `flat`: soma direta (ex.: Mochila +2 de carga).
- `percent`: somados entre si (ex.: +10% e +15% = +25%).
- `multiplier`: multiplicam entre si (raros e fortes, ex.: nó-chave ×2).

## 3. Status (lista v1)

| ID do status | Base | Unidade | Mín | Observação |
|---|---|---|---|---|
| `player.move_speed` | 4.0 | m/s | 1 | |
| `player.carry_capacity` | 8 | itens | 1 | "stack carry" |
| `player.pickup_rate` | 8 | itens/s | 1 | coleta de pilhas |
| `player.drop_rate` | 10 | itens/s | 1 | entrega no balcão |
| `player.magnet_radius` | 0 | m | 0 | nó-chave Ímã |
| `production.rate` | 1.0 | × | 0.1 | multiplicador global de velocidade |
| `production.rate.<item>` | 1.0 | × | 0.1 | por item (egg, milk, wheat) |
| `production.yield` | 1.0 | × | 1 | "farm item multiplier" — itens por ciclo (fração vira chance) |
| `production.double_chance` | 0 | % | 0 | |
| `production.output_capacity` | 30 | itens | 5 | pilha de saída dos produtores |
| `production.super_chance` | 0 | % | 0 | nó-chave Super safra |
| `production.super_multiplier` | 10 | × | 1 | |
| `sell.price` | 1.0 | × | 0.1 | multiplicador global de preço |
| `sell.price.<item>` | 1.0 | × | 0.1 | |
| `sell.tip_chance` | 0 | % | 0 | |
| `sell.tip_bonus` | 0.5 | × | 0 | gorjeta = +50% do valor do pedido |
| `sell.vip_chance` | 0 | % | 0 | nó-chave Clientes VIP |
| `sell.vip_multiplier` | 5 | × | 1 | |
| `counter.capacity` | 30 | itens | 5 | |
| `counter.serve_time` | 0.6 | s | 0.1 | tempo por cliente no caixa |
| `customer.spawn_interval` | 5.0 | s | 0.5 | menor = mais clientes |
| `customer.max_queue` | 5 | clientes | 1 | por balcão |
| `customer.buy_min` / `customer.buy_max` | 1 / 3 | itens | 1 | |
| `customer.patience` | 25 | s | 5 | |
| `customer.move_speed` | 2.5 | m/s | 0.5 | |
| `worker.move_speed` | 3.0 | m/s | 1 | |
| `worker.carry_capacity` | 6 | itens | 1 | |
| `machine.speed` | 1.0 | × | 0.1 | |
| `farm.xp_gain` | 1.0 | × | 0.1 | |
| `offline.max_hours` | 2 | h | 0 | |
| `offline.efficiency` | 0.25 | × | 0 | |
| `unlock.cost` | 1.0 | × | 0.01 | só para dev/balanceamento |
| `upgrade.cost` | 1.0 | × | 0.01 | só para dev/balanceamento |

## 4. Itens v1

| Item | ID | Preço base | Produção base | Produtor |
|---|---|---|---|---|
| Trigo | `wheat` | $2 | canteiro rebrota em 8 s, 1 trigo por canteiro | Plantação |
| Ovo | `egg` | $3 | 1 a cada 4 s por galinha | Galinheiro (até 6 galinhas) |
| Leite | `milk` | $8 | 1 a cada 7 s por vaca | Curral (até 4 vacas) |

Futuros itens processados (fábrica): caixa de ovos, queijo, pão, bacon — preços ~3–4× o valor da entrada.

Preço final de venda = `preço_base × sell.price × sell.price.<item>` (× 1.5 se gorjeta).

## 5. Curvas de custo

```
custo_upgrade(nível) = base × crescimento^nível × upgrade.cost
xp_para_próximo(nível) = 50 × 1.35^(nível − 1)
```

| Upgrade | Base | Crescimento | Efeito/nível |
|---|---|---|---|
| Botas | $25 | 1.55 | +6% `player.move_speed` (percent) |
| Mochila | $30 | 1.60 | +2 `player.carry_capacity` (flat) |
| Mãos rápidas | $35 | 1.55 | +10% pickup e drop rate |
| Preço justo | $50 | 1.65 | +10% `sell.price` |
| Fazenda fértil | $40 | 1.60 | +8% `production.rate` |
| Propaganda | $35 | 1.60 | −6% `customer.spawn_interval` (percent negativo, clamp) |
| Treinamento *(M6)* | $150 | 1.70 | +8% velocidade e +1 carga dos ajudantes |

Árvore de passivas: nós custam 1–3★ e 5★ os nós-chave (ver `passives.json`).
M5: 15 nós (Fazendeiro, Produção, Comércio). M6 adiciona Automação e Descanso (~25 no total).
Propaganda tem nível máximo 12 (o intervalo de clientes tem piso de 0,5 s).

Fonte da verdade: `data/balance/upgrades.json` e `data/balance/passives.json`.

## 6. Sequência de desbloqueios v1

Fonte da verdade: `data/balance/unlocks.json` (custos × status `unlock.cost`). Implementado até o #11 no M4;
o resto entra com seus sistemas (M5 Mesa de Upgrades, M6 ajudantes/máquinas/caminhões).

| # | ID | Pad | Custo | Área | Pré-requisito | Efeito |
|---|---|---|---|---|---|---|
| 0 | — | *(início)* Galinheiro c/ 2 galinhas + balcão de ovos | — | A1 | — | |
| 1 | `chicken_3` | Galinha #3 | $15 | A1 | — | coop +1 |
| 2 | `chicken_4` | Galinha #4 | $60 | A1 | 1 | coop +1 |
| 3 | `area_field` | Expansão: Campo (leste) | $120 | A2 | 1 | abre a cerca leste |
| 4 | `wheat_field` | Plantação de trigo (6 canteiros) | $80 | A2 | 3 | |
| 5 | `wheat_counter` | Balcão de trigo | $100 | A2 | 4 | |
| 6 | `chickens_5_6` | Galinhas #5 e #6 | $250 | A1 | 2 | coop +2 |
| 7 | `wheat_beds_2` | Canteiros +6 | $300 | A2 | 5 | field +6 |
| 8 | `area_pasture` | Expansão: Pasto (oeste) | $600 | A3 | 5 | abre a cerca oeste |
| 9 | `barn` | Curral + vaca #1 | $400 | A3 | 8 | |
| 10 | `milk_counter` | Balcão de leite | $450 | A3 | 9 | |
| 11 | `cow_2` | Vaca #2 | $900 | A3 | 9 | barn +1 |
| — | *(M5)* | Mesa de Upgrades | $40 | A1 | 1 | |
| — | *(M6)* | Caixa, carregador, irrigação, esteira, ordenhadeira, estrada/caminhões, coletor de dinheiro | $700+ | | | |
| — | *(M6)* | Placa "Terreno à venda" (teaser fábrica) | — | A5 | | |

## 7. Metas de ritmo (o que o balanceamento precisa atingir)

| Momento | Meta |
|---|---|
| Primeira venda | < 20 s |
| Primeiro pad comprado | < 45 s |
| Mesa de Upgrades | ~2 min |
| Abrir o Campo | ~4 min |
| Primeira vaca | ~10 min |
| Primeiro ajudante | ~15 min |
| Caminhões | ~30 min |
| Fazenda v1 "completa" (todos os pads) | 2–3 h de jogo ativo |
| Depois disso | Upgrades infinitos + árvore até a fábrica chegar |

Regra geral: **o próximo objetivo deve estar sempre a menos de 1–2 minutos de distância** no início,
alongando aos poucos.

## 8. Ganhos offline

```
renda_auto_por_s = medida nos últimos 5 min de jogo, só da renda que NÃO dependeu do jogador
                   (vendas feitas por caixas/ajudantes/máquinas)
tempo = min(agora − último_save, offline.max_hours × 3600)
ganho = renda_auto_por_s × tempo × offline.efficiency
```

Sem automação = sem ganho offline. Isso torna os ajudantes desejáveis e não quebra o início.
Proteção: se o relógio do sistema voltou no tempo, ganho = 0.

## 9. Arquivos de balanceamento

```
data/balance/stats.json        # base, min, max de cada status
data/balance/items.json        # preço base, tempo de produção
data/balance/upgrades.json     # base, crescimento, efeitos
data/balance/unlocks.json      # sequência de pads, custos, pré-requisitos
data/balance/passives.json     # nós da árvore, custo, efeitos, vizinhos
data/balance/progression.json  # curva de XP, estrelas por nível, offline
data/balance/producers.json    # produtores: item, unidades iniciais e máximas (galinhas, vacas)
```

JSON foi escolhido para balanceamento porque é fácil de editar, comparar em diffs, gerar por planilha e
**gravar de volta pelo dev mode**. Ver decisão D3 em [09-decisoes-e-perguntas.md](09-decisoes-e-perguntas.md).
