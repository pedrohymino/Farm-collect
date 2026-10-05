# 09 — Decisões e Perguntas em Aberto

## Decisões tomadas

| # | Data | Decisão | Motivo |
|---|---|---|---|
| D1 | 2026-10-05 | **Godot 4.7.2 (Standard) + GDScript** | Leve, gratuito, exporta para Steam/Android/iOS, export mobile da versão Standard é mais simples que .NET |
| D2 | 2026-10-05 | **3D low-poly com câmera isométrica** | Fiel aos anúncios de referência; modelos simples, leves e fáceis de produzir |
| D3 | 2026-10-05 | **Números de balanceamento em JSON** (`data/balance/`), identidade/visual em `.tres` | Fácil de editar, de comparar em diffs, de gerar por planilha e de gravar pelo dev mode |
| D4 | 2026-10-05 | **Renderer Compatibility** | Maior compatibilidade com celulares, o mais leve, permite build Web; o estilo low-poly chapado não precisa de Forward+ |
| D5 | 2026-10-05 | **Sistema de status + modificadores** como única fonte dos valores de gameplay | Upgrades, passivas e dev mode funcionam igual para tudo e para o que vier depois |
| D6 | 2026-10-05 | **Textura-paleta única** para os modelos | Um material para quase tudo → menos draw calls, visual coeso |
| D7 | 2026-10-05 | **pt_BR + en** desde o início, todo texto via `tr()` | Adicionar idiomas depois fica trivial |
| D8 | 2026-10-05 | **GUT** para testes, **gdtoolkit** para formatação/lint | Maduros, rodam headless no terminal |
| D9 | 2026-10-05 | **Personagens animados de pacote CC0** (Quaternius); resto via Blender MCP | Animação humana é o ponto mais difícil de gerar com qualidade |
| D10 | 2026-10-05 | **Fábrica fica para depois da v1**, mas a arquitetura já a prevê | Foco em validar o loop da fazenda primeiro |
| D11 | 2026-10-05 | **Mobile em retrato (portrait)**; PC/Steam em paisagem | Padrão do gênero e dos anúncios de referência; câmera e HUD se adaptam à proporção |
| D12 | 2026-10-05 | **Jogador carrega tipos de item misturados** na pilha | Menos atrito; cada balcão só puxa os itens do seu tipo |

## Perguntas em aberto

| # | Pergunta | Opções | Precisa até |
|---|---|---|---|
| Q1 | Nome final do jogo? | "Farm Collect" é provisório | M9 (página da Steam antes, idealmente M7) |
| Q2 | Monetização? | Premium / Steam pago + mobile com anúncios / F2P + IAP (ver doc 08) | M8 |
| Q4 | Moeda da árvore de passivas? | Estrelas por nível (recomendado) / dinheiro / outra moeda | M5 |
| Q5 | Ganho offline só com automação? | Sim (recomendado) / sempre um pouco | M6 |
| Q6 | Prestígio na v1? | Não (recomendado, entra depois da fábrica) / sim | M8 |
| Q8 | Personagem do jogador: fixo ou escolhível (cor/gênero)? | Fixo na v1 / customização simples | M7 |
