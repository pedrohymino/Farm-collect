# 02 — Game Design

Valores numéricos aqui são ilustrativos; os números oficiais vivem em
[03-economia-e-balanceamento.md](03-economia-e-balanceamento.md) e no código em `data/balance/*.json`.

## 1. Loop principal (segundos)

```
 Produtor gera item ──► Pilha de saída do produtor
                              │  (jogador pisa na zona de coleta)
                              ▼
                     Pilha nas costas do jogador  (limite = capacidade de carga)
                              │  (jogador pisa na zona de entrega do balcão)
                              ▼
                     Estoque do balcão
                              │  (cliente compra; jogador no "caixa" atende)
                              ▼
                     Pilha de dinheiro do balcão
                              │  (jogador pisa na pilha)
                              ▼
                     Carteira  ──►  pads de desbloqueio / upgrades / passivas
```

## 2. Loop de meta (minutos/horas)

1. Ganhar dinheiro → desbloquear produtores, balcões e áreas (pads no chão).
2. Desbloquear a **Mesa de Upgrades** → melhorar status com dinheiro (níveis infinitos, custo exponencial).
3. Ganhar **XP da fazenda** vendendo → subir de nível → ganhar **Estrelas** → gastar na **Árvore de Passivas**.
4. Contratar **ajudantes** e comprar **máquinas** → a fazenda passa a rodar sozinha (idle).
5. Voltar depois → **ganhos offline**.
6. (Futuro) Abrir a **Fábrica** → nova camada de economia.

## 3. Controles

| Plataforma | Mover | Outros |
|---|---|---|
| PC | WASD / setas | Mouse em menus, `Esc` pausa |
| Controle / Steam Deck | Analógico esquerdo | Botões para menus |
| Mobile | Joystick virtual flutuante (onde o dedo toca) | Toque em menus |

Não existe botão de "coletar" ou "vender". **Tudo é por proximidade**: pisar na zona inicia a transferência
item a item em uma taxa (itens/s). Sair da zona para.

## 4. Entidades do mundo

### Jogador
- Anda, carrega uma **pilha vertical** de itens nas costas/mãos (balança ao andar).
- Pode carregar **tipos misturados** (decisão D12): cada item mantém sua posição na pilha e,
  ao entregar, cada balcão puxa só os itens do seu tipo (a pilha "se reorganiza" com animação).
- Status: velocidade, capacidade de carga, taxa de coleta, taxa de entrega.

### Produtores
| Produtor | Item | Como produz | Observação |
|---|---|---|---|
| Plantação de trigo | Trigo | Canteiros crescem; o jogador **colhe ao passar por cima** de canteiros maduros | Rebrota depois de X s |
| Galinheiro | Ovo | Cada galinha bota 1 ovo a cada X s numa pilha de saída | Comprar mais galinhas = mais produção |
| Curral | Leite | Cada vaca produz 1 leite a cada X s | Mais lento, mais valioso |

- A pilha de saída tem **capacidade máxima**. Cheia → produção pausa (incentiva coletar e evita acúmulo infinito).
- Produção afetada por: taxa (velocidade), rendimento (itens por ciclo — o "farm item multiplier"),
  chance de colheita dupla.

### Balcões de venda
- Um balcão por tipo de item (balcão de ovo, de trigo, de leite).
- Tem **zona de entrega** (jogador despeja itens daquele tipo), **estoque** com capacidade,
  **ponto de caixa** ("SELL") e **pilha de dinheiro**.
- Clientes fazem fila. Cada cliente quer N itens. Se tem estoque e **alguém está no caixa**, a venda acontece:
  itens somem do estoque, cliente sai feliz (emoji 😊), dinheiro aparece na pilha.
- Até contratar um **Caixa** (ajudante), o jogador precisa estar no ponto "SELL" para vender.

### Clientes
- Nascem na entrada, andam até a fila do balcão escolhido, esperam, compram, vão embora.
- Taxa de chegada, quantidade por compra e gorjeta (chance) são status.
- Sem estoque, o cliente espera um tempo (paciência) e vai embora triste (sem punição além de perder a venda).

### Caminhões de pedido (meio do jogo)
- Estacionam numa vaga e pedem uma carga grande de itens específicos (ex.: 🥚 ×20, 🥛 ×5).
- O jogador (ou ajudante) entrega na caçamba. Ao completar: pagamento grande + bônus.
- Prazo generoso, sem punição — se demorar, o caminhão vai embora e outro vem depois.

### Pads de desbloqueio
- Quadrado no chão com ícone + preço. Pisar em cima **drena dinheiro** da carteira para o pad
  em animação (notas voando), sempre levando ~1–2 s independentemente do preço.
- Pagamento parcial é guardado (pode sair e voltar).
- Ao completar: o objeto surge com animação ("pop" + confete), câmera dá uma rápida
  panorâmica se o desbloqueio abriu área nova, e os próximos pads aparecem.

### Ajudantes (automação)
| Ajudante | Função |
|---|---|
| Caixa | Fica no ponto SELL de um balcão — vendas acontecem sem o jogador |
| Carregador | Leva itens de um produtor para o balcão correspondente, em loop |
| Coletor de dinheiro (tardio) | Recolhe as pilhas de dinheiro dos balcões e leva ao "cofre" |

Ajudantes têm velocidade e capacidade próprias (status com upgrades/passivas).

### Máquinas de fazenda (automação, não processamento)
- **Esteira coletora de ovos**: leva os ovos do galinheiro direto para o estoque do balcão.
- **Ordenhadeira**: aumenta a velocidade de produção do curral.
- **Irrigação**: trigo cresce mais rápido.

> Processar um item em outro (ovo → caixa de ovos) é coisa da **Fábrica** (futuro), não da fazenda.

## 5. Progressão da fazenda (v1)

A fazenda é dividida em **áreas** separadas por cercas/arbustos. Comprar a expansão abre a cerca.

| Área | Conteúdo | Libera |
|---|---|---|
| A1 — Início | Galinheiro (2 galinhas), balcão de ovos | Galinhas extras, Mesa de Upgrades |
| A2 — Campo (leste) | Plantação de trigo, balcão de trigo | Canteiros extras, irrigação |
| A3 — Pasto (oeste) | Curral + vacas, balcão de leite | Caixa, carregador, ordenhadeira |
| A4 — Estrada | Vaga de caminhões | Pedidos de caminhão, coletor de dinheiro |
| A5 — "Terreno à venda" | Placa misteriosa | Teaser da Fábrica (futuro) |

Sequência e preços dos pads: ver [03-economia-e-balanceamento.md](03-economia-e-balanceamento.md#6-sequência-de-desbloqueios-v1).

## 6. Upgrades (Mesa de Upgrades, paga com dinheiro)

Níveis infinitos, custo exponencial. Menu aberto ao pisar na mesa.

| Upgrade | Efeito por nível |
|---|---|
| Botas | + velocidade do jogador |
| Mochila | + capacidade de carga |
| Mãos rápidas | + taxa de coleta/entrega |
| Preço justo | + preço de venda global |
| Fazenda fértil | + velocidade de produção global |
| Propaganda | + taxa de chegada de clientes |
| Treinamento *(M6)* | + velocidade e capacidade dos ajudantes (após o primeiro ajudante) |

## 7. Árvore de Passivas (paga com Estrelas)

- Estrelas vêm de **subir de nível da fazenda** (XP = valor vendido).
- Árvore em grafo com 5 ramos saindo de um nó central. Cada nó exige um nó vizinho já comprado.
- Nós "normais" (+%) e nós "chave" (efeitos especiais) no fim dos ramos.

| Ramo | Exemplos de nós | Nó-chave |
|---|---|---|
| Fazendeiro | +velocidade, +carga, +taxa de coleta | **Ímã**: coleta itens a 2 m sem pisar na zona |
| Produção | +taxa, +rendimento, +chance de colheita dupla | **Super safra**: 1% de chance de ×10 itens |
| Comércio | +preço, +gorjeta, clientes compram mais | **Cliente VIP**: clientes ocasionais pagam ×5 |
| Automação *(M6)* | +velocidade/capacidade dos ajudantes, +velocidade das máquinas | **Turno extra**: ajudantes nunca descansam |
| Descanso *(M6)* | +tempo máximo offline, +eficiência offline | **Fazenda que não dorme**: offline a 100% |

## 8. Ganhos offline

Ao voltar: "Enquanto você estava fora, sua fazenda rendeu $X" com botão de coletar.
Calculado pela taxa média de renda automatizada × tempo fora (com teto e eficiência). Fórmula no doc de economia.

## 9. Juice (como cada ação vira dopamina)

| Ação | Feedback |
|---|---|
| Coletar item | Item voa em arco até o topo da pilha, "pop" de escala, som com pitch subindo em sequência |
| Pilha cheia | Pilha pisca, texto "MAX" sobre o jogador |
| Entregar | Itens voam em fila para o balcão |
| Venda | Emoji feliz no cliente, notas brotam na pilha de dinheiro |
| Coletar dinheiro | Notas voam para o contador do HUD, contador "rola" e pulsa |
| Pad de desbloqueio | Notas voando para o pad, anel de progresso enchendo, som crescente |
| Desbloqueio | Objeto surge com "squash & stretch", confete, som de recompensa, panorâmica de câmera |
| Subir de nível | Banner "Nível X!", estrela voando para o botão da árvore |
| Mobile | Vibração leve em coleta/venda, mais forte em desbloqueio |

Ver lista completa de efeitos e sons em [06-arte-e-audio.md](06-arte-e-audio.md).

## 10. Onboarding

Sem tutorial com texto longo. Uma **seta guia** no chão aponta a próxima ação nos primeiros minutos
(coletar ovos → balcão → SELL → pegar dinheiro → primeiro pad). Some quando o jogador já fez cada ação.

## 11. Futuro: Fábrica (projeto, não implementar na v1)

- Nova localidade acessada por uma estrada/portão na área A5 (ou viagem rápida).
- Na fazenda surge a **Doca de Envio**: o jogador configura, por item, a porcentagem que vai para a
  fábrica (o resto segue para os balcões). Caminhões transportam automaticamente.
- Na fábrica: **máquinas de processamento** com receita (entrada → saída, tempo), ex.:
  6 ovos → 1 caixa de ovos; 3 leites → 1 queijo; 4 trigos → 1 pão.
- Produtos processados vendem bem mais caro, em balcões/caminhões próprios da fábrica.
- Mesmo loop (andar, empilhar, entregar) — o jogador já sabe jogar.

Como a arquitetura já suporta isso: ver [04-arquitetura.md](04-arquitetura.md#9-preparação-para-a-fábrica).
