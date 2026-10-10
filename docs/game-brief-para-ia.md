# Farm Collect — resumo do jogo para trocar ideias com outra IA

> Documento autocontido, feito para ser colado numa conversa com outra IA. Descreve o jogo como ele
> **existe hoje** (marco M8 concluído), com os números reais, e termina com perguntas concretas.
> "Farm Collect" é um nome provisório.

## 1. Em uma frase

Jogo **cozy, casual e incremental** de fazenda em **3D low-poly com câmera isométrica**, no estilo
"idle arcade": você anda pela fazenda, coleta o que animais e plantações produzem, empilha nas costas,
entrega no balcão, vende para clientes, pega o dinheiro e usa para destravar áreas, melhorar tudo e
automatizar. É a experiência que os anúncios "fake" de Township prometem, mas de verdade.

- **Plataformas:** Steam primeiro (inclui Steam Deck), depois Android e iOS. Tela vertical no celular.
- **Tecnologia:** Godot 4.7.2, GDScript, renderer Compatibility (roda em celular médio).
- **Estado:** vertical slice completo da fazenda (M0–M8: loop, dev mode, desbloqueios, upgrades, árvore de
  passivas, automação, caminhões, ganhos offline, arte, menu/pausa/configurações, save robusto).
  Falta: playtest com outras pessoas, plataformas/lançamento (M9) e a **fábrica** (pós-v1).
- **Equipe:** uma pessoa + IA. Sem orçamento de arte: assets CC0 (Kenney, KayKit).

## 2. Pilares de design

1. **Dopamina constante:** algo bom a cada poucos segundos (itens voando para a pilha, dinheiro estourando,
   barra de desbloqueio enchendo, números subindo).
2. **Fácil de jogar:** um único controle (mover). Coletar, entregar e pagar acontecem ao pisar nas áreas.
3. **Progresso visível:** cada compra muda o mundo fisicamente (cerca nova, animal novo, área nova).
4. **Incremental de verdade:** upgrades, árvore e automação fazem o jogador sentir ordens de grandeza.
5. **Leve:** build pequeno, sessões curtas no celular (5–15 min) e longas na Steam (deixar rodando).

Fora de escopo: multiplayer, combate, construção livre em grid, energia/stamina que trava o jogador.

## 3. Loop principal (o que o jogador faz)

```
coletar -> empilhar -> entregar no balcão -> cliente compra -> pegar dinheiro -> comprar pad/upgrade -> automatizar
```

1. Galinhas, trigo e vacas produzem itens numa **pilha de saída** (zona de coleta).
2. O jogador pisa na zona: os itens voam para a pilha nas costas (limite de carga).
3. Pisa na zona de entrega do **balcão**: itens saem da pilha para o estoque do balcão.
4. **Clientes** chegam, fazem fila, compram 1–3 itens se houver estoque e **alguém estiver no ponto "SELL"**
   (o jogador, até contratar um Caixa).
5. A venda gera **notas numa pilha de dinheiro**; pisar nela transfere para a carteira.
6. **Pads de desbloqueio** no chão drenam dinheiro enquanto o jogador está em cima; ao encher, algo novo
   surge no mundo (área, animal, balcão, máquina, ajudante).
7. **Mesa de Upgrades** (dinheiro, níveis infinitos) e **Árvore de Passivas** (estrelas de nível) aceleram tudo.

### Fazenda (áreas)
| Área | Conteúdo |
|---|---|
| A1 Início | Galinheiro (2 galinhas), balcão de ovos, mesa de upgrades |
| A2 Campo (leste) | Plantação de trigo (6→12 canteiros), balcão de trigo, irrigação |
| A3 Pasto (oeste) | Curral (1→4 vacas), balcão de leite, ordenhadeira |
| A4 Estrada (norte) | Doca de caminhões, coletor de dinheiro |
| A5 "Terreno à venda" | Teaser da fábrica (futuro) |

### Itens e produtores
| Item | Preço base | Tempo de produção | Produtor (unidades) |
|---|---|---|---|
| Trigo | $2 | 8 s por canteiro | Campo: 6 base, até 12 |
| Ovo | $3 | 4 s por galinha | Galinheiro: 2 base, até 6 |
| Leite | $8 | 7 s por vaca | Curral: 1 base, até 4 |

## 4. Sistemas e números reais

Todo valor de gameplay é um **status** (`base + soma flat) × (1 + soma percent) × produto multiplier`, com
mínimo/máximo). Upgrades, passivas e desbloqueios só registram modificadores. Principais status:

| Status | Base | Observação |
|---|---|---|
| `player.move_speed` | 4 m/s | teto 8 (2×), para não ficar incontrolável |
| `player.carry_capacity` | 8 itens | |
| `player.pickup_rate` / `drop_rate` | 8 / 10 itens/s | |
| `customer.spawn_interval` | 4 s | **por balcão aberto** |
| `customer.buy_min`/`buy_max` | 1 / 3 itens | |
| `customer.patience` / `max_queue` | 25 s / 5 por balcão | |
| `counter.serve_time` | 0,6 s | |
| `production.yield` / `double_chance` / `super_chance` | 1 / 0 / 0 | super = ×10 itens |
| `sell.tip_chance` / `vip_chance` | 0 / 0 | gorjeta +50%; VIP ×5 |
| `worker.move_speed` / `carry_capacity` | 3 m/s / 6 | ajudantes |
| `truck.order_size` / `interval` / `bonus` | 12 itens / 40 s / ×1,5 | pedido cresce 15% por nível da fazenda |
| `offline.max_hours` / `efficiency` | 2 h / 25% | só renda automatizada conta |

### Upgrades (Mesa, pagos com dinheiro; custo = base × crescimento^nível)
| Upgrade | Base | Cresc. | Efeito por nível |
|---|---|---|---|
| Botas | $25 | 1,55 | +5% velocidade (máx. nível 20) |
| Mochila | $30 | 1,60 | +2 de carga |
| Mãos rápidas | $35 | 1,55 | +10% coleta e entrega |
| Preço justo | $50 | 1,55 | +15% preço de venda |
| Fazenda fértil | $40 | 1,60 | +8% velocidade de produção |
| Propaganda | $35 | 1,50 | −8% intervalo de clientes (máx. nível 10) |
| Treinamento | $150 | 1,70 | +8% velocidade e +1 carga dos ajudantes (após o 1º ajudante) |

### Nível da fazenda e árvore de passivas
- **XP = dinheiro vendido.** `xp_para_próximo = 50 × 1,35^(nível−1)`. Cada nível dá 1 estrela.
- Árvore em grafo, **5 ramos × 5 nós** (4 normais de 1–3★ + 1 nó-chave de 5★), cada nó exige um vizinho comprado:

| Ramo | Nós | Nó-chave |
|---|---|---|
| Fazendeiro | +velocidade, +carga, +coleta | **Ímã** (coleta a 1,5 m sem pisar na zona) |
| Produção | +taxa, +colheita dupla, +rendimento | **Super safra** (1% de chance de ×10) |
| Comércio | +preço, +gorjeta, clientes compram mais | **Cliente VIP** (5% pagam ×5) |
| Automação* | +velocidade/carga de ajudantes, +velocidade de máquinas | **Turno extra** |
| Descanso* | +horas e +eficiência offline | **Fazenda que não dorme** (offline a 100%) |

\* Exigem o primeiro ajudante (Caixa) comprado.

### Automação
- **Caixa** (um por balcão): vende sem o jogador no SELL.
- **Carregador de ovos:** leva ovos do galinheiro ao balcão em loop. **Esteira de ovos:** máquina que faz o mesmo.
- **Irrigação** (+40% trigo) e **Ordenhadeira** (+50% leite): efeitos de status vindos de desbloqueios.
- **Caminhões de pedido:** pedem 1–2 itens (quantidade cresce com o nível da fazenda), pagam ×1,5, sem
  punição se demorar (o caminhão vai embora e outro vem).
- **Coletor de dinheiro:** recolhe as pilhas dos balcões.
- **Ganhos offline:** ao voltar, "sua fazenda rendeu $X". Só conta renda de vendas automatizadas; se o
  relógio do sistema voltou, é zero.

### Sequência de desbloqueios (22 pads; custos atuais)
`chicken_3` $15 → `upgrade_board` $40 → `chicken_4` $60 → `area_field` $80 → `wheat_field` $80 →
`wheat_counter` $100 → `chickens_5_6` $150 → `wheat_beds_2` $250 → `area_pasture` $200 → `barn` $150 →
`milk_counter` $250 → `cashier_egg` $400 → `cow_2` $800 → `carrier_egg` $1,2K → `irrigation` $2K →
`egg_conveyor` $3K → `area_road` $3,5K → `truck_bay` $3K → `cashier_wheat` / `cashier_milk` $8K cada →
`milking_machine` $50K → `cows_3_4` $120K → `money_collector` $280K.
Filosofia: **baratos no começo, caros no fim**.

## 5. Ritmo (metas × simulação)

Um simulador de economia (modelo de fluxo, política de compra gulosa) compara a linha do tempo com as metas:

| Momento | Meta | Simulado |
|---|---|---|
| Primeira venda | < 20 s | ~14 s |
| Primeiro pad | < 45 s | ~24 s |
| Mesa de Upgrades | ~2 min | ~0:51 |
| Abrir o Campo | ~4 min | ~3:00 |
| Primeira vaca | ~10 min | ~9:18 |
| Primeiro ajudante | ~15 min | ~13:48 |
| Caminhões | ~30 min | ~34:25 |
| Fazenda completa | 2–3 h | ~2:20 |

Regra: o próximo objetivo deve estar a menos de 1–2 minutos no início, alongando aos poucos.

**Dinâmica econômica importante (descoberta pelo simulador):**
- A renda é limitada pela **demanda de clientes** (cada balcão: ~0,5 item/s no começo), não pela produção.
  Por isso Propaganda e Preço justo são muito fortes cedo, e galinhas/produção só importam quando a demanda sobe.
- No fim do jogo a renda é limitada pelo **leite** (máx. 4 vacas) e pelo **tempo do jogador carregando**
  trigo e leite (só os ovos têm carregador). Resultado: esperas longas (10–30 min) entre os pads grandes,
  preenchidas só por upgrades e estrelas. **É o ponto mais fraco do design atual.**

## 6. Juice, onboarding e UX

- Itens voam em arco até a pilha (pop de escala, som com pitch subindo), pilha "MAX", notas brotam no
  balcão, dinheiro voa para o HUD e o contador rola, pads com anel de progresso, desbloqueio com
  squash & stretch + confete + pan de câmera, banner "Nível X!", vibração no celular.
- Onboarding sem texto: uma **seta guia** no chão aponta a próxima ação; depois do tutorial, um marcador
  aponta o pad disponível mais barato.
- Menu principal com diorama, pausa, configurações (volume, idioma pt-BR/en, vibração, qualidade gráfica).
- **Dev mode (F1):** painel para mexer em qualquer status ao vivo, dar dinheiro/estrelas, pular níveis.

## 7. Arte e áudio

Estilo "brinquedo": minimalista, poly, cores suaves. Personagens e animais animados (Kenney CC0), prédios
e cenário (KayKit CC0), fonte Fredoka. Música cozy em loop e SFX sintetizados (ainda placeholders).

## 8. Futuro já previsto na arquitetura

- **Fábrica** (2ª localidade): o jogador decide, por item, quanto vai para venda e quanto vai para a
  fábrica via caminhões. Receitas: 6 ovos → caixa de ovos; 3 leites → queijo; 4 trigos → pão; porco → bacon.
  Produtos processados valem ~3–4× o valor de entrada, com balcões e caminhões próprios.
- Prestígio ("nova temporada"), mais animais/plantações, eventos sazonais, mais idiomas, build Web demo.

## 9. Perguntas em aberto

1. **Monetização:** premium na Steam + mobile com anúncios? F2P com compras? (ainda não decidido)
2. **Prestígio já na v1 ou só depois da fábrica?**
3. **Nome final** do jogo.
4. Personagem fixo ou com customização leve?

## 10. O que eu quero de você (outra IA)

Responda com ideias **concretas, priorizadas e com estimativa de esforço** (pequeno/médio/grande), pensando em
um desenvolvedor solo com assets CC0:

1. **Conteúdo para a fazenda e para a fábrica:** novos produtores, itens, máquinas, receitas, clientes
   especiais, eventos sazonais, mini-objetivos. O que dá a maior sensação de novidade por unidade de trabalho?
2. **Corrigir as esperas do fim do jogo** sem quebrar o início: que fontes de crescimento adicionar
   (novos tipos de demanda, mais vacas, ajudantes de trigo/leite, upgrades com efeito real)?
3. **Retenção e sessão curta no celular:** metas diárias, baús, bônus offline, anúncios recompensados
   que não estraguem o cozy, coleções, conquistas.
4. **Estratégia de design incremental:** como equilibrar demanda × produção × transporte, quando
   introduzir cada mecânica, como evitar que upgrades "não façam nada" quando outro gargalo domina.
5. **Prestígio:** formato que combine com um jogo cozy (nova temporada, sementes de ouro?) e momento certo.
6. **Lançamento:** estratégia de Steam (demo, Next Fest, wishlist), preço, trailer feito do próprio jogo,
   e como adaptar para Android/iOS.
7. **Riscos:** o que mais costuma dar errado em jogos idle arcade e o que eu devo testar primeiro.
