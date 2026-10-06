# 06 — Arte e Áudio

## 1. Direção de arte

- **Estilo:** 3D low-poly, cores chapadas e saturadas, formas arredondadas e "fofas", proporções de brinquedo.
  Referência: os anúncios do Township (sem copiar nenhum asset).
- **Sem texturas detalhadas:** uma única **textura-paleta** (`assets/textures/palette.png`, 256×256, quadrados de cor).
  Cada modelo mapeia suas faces para quadrados da paleta → **um material para quase tudo**, ótimo para desempenho.
- **Luz:** 1 luz direcional quente + luz ambiente clara; sombras suaves. Leve "rim" ou contorno opcional depois.
- **Câmera:** isométrica em perspectiva (FOV ~35°, −50° de inclinação, 45° de rotação).
- **Escala:** 1 unidade = 1 metro. Personagem ~1.7 m. Galinha ~0.4 m. Ovo ~0.08 m (exagerado para ~0.15 m para leitura).

### Paleta inicial (ajustável)

| Uso | Cor |
|---|---|
| Grama | `#7CC456` / `#5FA83F` |
| Terra/caminho | `#E3A65C` / `#C98545` |
| Madeira (cerca, balcão) | `#B5713A` / `#8A5129` |
| Asfalto | `#5E6670` |
| Destaque UI (ciano das zonas) | `#3FD3F2` |
| Dinheiro | `#3DBA4E` |
| Vermelho (caminhão, balcão) | `#E5483B` |
| Amarelo (caminhão, ovos-caixa) | `#F7C531` |
| Branco (ovo) | `#F6F1E4` |

## 2. Orçamento de polígonos

| Tipo | Triângulos |
|---|---|
| Personagem (jogador/NPC) | 1.500 – 3.000 |
| Animal | 500 – 1.500 |
| Item (ovo, trigo, leite) | 30 – 200 |
| Construções/props | 100 – 1.000 |
| Terreno por área | < 2.000 |

## 3. Fontes de modelos

> **Atualização (decisão D24):** a arte usa os pacotes **Kenney (CC0)**. A tabela abaixo é o plano original; vale o que está em
> `CREDITS.md`. Fluxo: baixar o pacote em `art/downloads/` (fora do git) → `python tools/sync_models.py` → importar no Godot →
> `python tools/sync_models.py` → importar de novo. Ferramentas de apoio: `tools/showcase_models.gd` (vitrine para julgar escala),
> `tools/inspect_models.gd` e `tools/inspect_animations.gd`. Escalas usadas: personagens ×2 (~1,4 m), vaca ×0,7, galinha ×0,5.


| Fonte | Para quê | Licença |
|---|---|---|
| **Procedural no Godot** (primitivas) | Placeholders de M2 (graybox) | — |
| **Blender via MCP** (scripts em `art/blender/scripts/`) | Itens, props, construções, máquinas, animais estilizados | Nosso |
| **Quaternius** (quaternius.com) | Personagens humanos rigados e animados, possivelmente animais | CC0 (confirmar no download) |
| **Kenney** (kenney.nl) | Props de natureza, cercas, veículos, se ajudar | CC0 (confirmar no download) |

Animação de personagem humano (andar, idle, carregar) é a parte mais difícil de gerar → usar pacote CC0.
Todo asset de terceiros é registrado em `CREDITS.md` com origem e licença, mesmo sendo CC0.

### Pipeline
0. **Kit:** `art/blender/scripts/lowpoly_kit.py` (primitivas com UV apontando para um quadrado da paleta; cada modelo vira 1 malha + 1 material)
   e `models.py` (um `build_*` por modelo). Rodar no Blender: `build_all()` exporta todos os `.glb`. O `.glb` sai **sem imagem**; o Godot aplica
   `assets/materials/palette.tres` (configurado em `_subresources` de cada `.glb.import`). Novo modelo = nova função + linha em `MODELS`
   + copiar o bloco `_subresources` de outro `.glb.import`.
1. Modelo criado no Blender (script ou à mão) ou importado de pacote.
2. Ajuste: escala em metros, origem na base, UV para a paleta, nome padronizado.
3. Exporta `.glb` em `assets/models/<categoria>/<nome>.glb` (ex.: `animals/chicken.glb`).
4. No Godot, cena wrapper `<nome>.tscn` que instancia o `.glb` → gameplay referencia só a cena wrapper.
   **Trocar a arte = trocar o `.glb`**, a lógica não muda.

## 4. Lista de assets v1

| Asset | Categoria | Animação | Marco |
|---|---|---|---|
| Fazendeira (jogadora) | personagem | idle, andar, andar carregando | M7 (placeholder antes) |
| Clientes (3–4 variações de cor) | personagem | idle, andar, feliz | M7 |
| Ajudante (macacão azul + boné) | personagem | idle, andar, andar carregando | M7 |
| Galinha | animal | idle (bicar), botar ovo (squash) | M7 |
| Vaca | animal | idle (mastigar) | M7 |
| Ovo, trigo (feixe), garrafa de leite | item | — | M2/M7 |
| Nota de dinheiro (pilha) | item | — | M2 |
| Galinheiro, curral, canteiro (3 estágios de crescimento) | construção | — | M4/M7 |
| Balcão de venda + caixa registradora | construção | — | M2/M7 |
| Mesa de upgrades | construção | — | M5 |
| Cerca (segmento + portão), arbustos, árvores, fardos de feno, pedras | props | — | M4/M7 |
| Estrada, caminhão de pedido | veículo | entrar/sair | M6 |
| Esteira coletora, ordenhadeira, irrigação | máquina | loop | M6 |
| Pad de desbloqueio, zonas (decal ciano tracejado) | UI no mundo | pulso | M2 |
| Placa "Terreno à venda" | prop | — | M6 |

## 5. Efeitos visuais (juice)

- Item voando em arco (Tween + curva) até a pilha/balcão.
- "Pop" de escala (squash & stretch) em coleta, venda e desbloqueio.
- Partículas leves: confete no desbloqueio, brilho na pilha de dinheiro, poeira ao correr.
- Números flutuantes (+$12) e emojis sobre clientes.
- Anel de progresso no pad, setas guia pulsando.
- Contador de dinheiro que "rola" até o valor novo.

## 6. UI

- Estilo "chunky": botões grandes, cantos bem arredondados, contorno escuro, sombra embaixo.
- Fonte arredondada e grossa, com licença OFL (ex.: Fredoka ou Lilita One, Google Fonts).
- Ícones próprios em estilo plano (os mesmos ícones de item no HUD, pads e menus).
- HUD mínimo: dinheiro (topo), estrelas e nível (topo), botão da árvore de passivas, botão de configurações.

## 7. Áudio

| Som | Momento |
|---|---|
| "Pop" curto, pitch sobe em sequência | Coletar item (reinicia o pitch após pausa) |
| "Tum" macio | Entregar no balcão |
| Caixa registradora "cha-ching" | Venda |
| Notas/moedas | Coletar dinheiro |
| Som crescente | Pad drenando |
| Fanfarra curta | Desbloqueio, subir de nível |
| Cacarejar, mugido (ocasional, baixo) | Ambiente |
| Música | Loop acústico/cozy, calmo, sem cansar (volume baixo por padrão) |

Fontes: Kenney Audio (CC0), freesound.org (apenas CC0), geração com jsfxr para sons simples.
Música: compor/encomendar ou usar faixa com licença comercial clara (registrar em `CREDITS.md`).
