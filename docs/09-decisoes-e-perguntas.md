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
| D13 | 2026-10-05 | **Campo a leste e Pasto a oeste** da área inicial (não ao norte) | Todo balcão precisa ficar na estrada para os clientes chegarem |
| D14 | 2026-10-05 | **Mesa de Upgrades entra no M5**, junto com o menu | Sem o menu seria um pad que não faz nada |
| D15 | 2026-10-05 | **Pad que surge sob o jogador só cobra depois de sair e entrar de novo** | Pads em sequência no mesmo lugar não podem gastar dinheiro sem o jogador querer |
| D17 | 2026-10-05 | **Árvore de passivas paga com estrelas** (1 estrela por nível da fazenda; XP = valor vendido) | Resposta à Q4; separa progressão de longo prazo do dinheiro do dia a dia |
| D18 | 2026-10-05 | **Ramos Automação/Descanso e upgrade Treinamento ficam para o M6** | Só fazem efeito com ajudantes e ganhos offline; comprar nó sem efeito seria ruim |
| D19 | 2026-10-05 | **Efeitos de upgrades/passivas são dados** (`stat`, `type`, `value`); por nível, flat/percent somam e multiplicadores compõem | Novo upgrade ou nó = só JSON; aparecem no breakdown do dev mode pela origem |
| D20 | 2026-10-05 | **Ajudantes em camada física própria, movidos sem colisão** | Nunca empurram/bloqueiam o jogador; zonas adicionam a camada à máscara |
| D21 | 2026-10-05 | **Máquinas de bônus são desbloqueios com `effects`** (irrigação, ordenhadeira) | Mesmo mecanismo de upgrades/passivas, zero código novo por máquina |
| D22 | 2026-10-05 | **Doca de carga como faixa ao norte; caminhão espera o pedido sem prazo** | Mantém o jogador dentro da cerca; "sem punição" do doc 02 |
| D23 | 2026-10-05 | **Offline conta só vendas feitas sem o jogador no caixa**; Automação/Descanso exigem o 1º ajudante | Sem automação não há renda offline (Q5 resolvida) |
| D24 | 2026-10-05 | **Direção de arte = pacotes Kenney (CC0)**: Mini Characters, Cube Pets, Food Kit, Mini Forest/Dungeon/Arena (substitui D9) | Estilo minimalista/poly pedido pelo usuário; personagens e animais já vêm animados. Modelos realistas da Quaternius foram descartados |
| D25 | 2026-10-05 | **Um material por pacote Kenney** (cada pacote tem a sua `colormap.png`), mais `palette.tres` para o que modelamos | Mantém poucos materiais sem editar texturas de terceiros |
| D26 | 2026-10-05 | **Animação de personagem por velocidade real** (idle/walk/sprint) com variante "-carry" montada em código | Os pacotes não trazem andar carregando; combinamos pernas do andar + braços do `holding-both` |
| D27 | 2026-10-05 | **KayKit (CC0) para construções e cenário** (mercados como balcões, moinho, poço, casas, andaime), Kenney para personagens/animais/itens | Mais personalidade nos prédios, mantendo os personagens minimalistas e já animados. KayKit Adventurers descartados por ora (sem animação embutida) |
| D28 | 2026-10-05 | **Velocidade de movimento com teto de 2× a base** (botas +5%/nível até o 20; teto no próprio status, vale para o total) | Bug reportado: gastar muito dinheiro deixava o personagem rápido demais para controlar |
| D29 | 2026-10-05 | **Cercados sempre com portão e nenhum pad dentro de cerca fechada** (teste de layout) | Bug reportado: jogador preso ao desbloquear o curral estando dentro da área |
| D30 | 2026-10-05 | **Marcador "próximo objetivo" depois do tutorial**: aponta o pad disponível mais barato | Automação e novas áreas não eram descobertas |
| D31 | 2026-10-05 | **Primeiro ajudante (Caixa) logo após o 2º balcão** (antes: após o 3º) e a árvore explica por que um ramo está travado | Os ramos Automação/Descanso pareciam impossíveis de liberar |
| D16 | 2026-10-05 | **Plantações e curral usam `producers.json`** (unidades = canteiros/animais) e desbloqueios dão unidades extras | Um único modelo para "mais produção" em qualquer produtor |

## Perguntas em aberto

| # | Pergunta | Opções | Precisa até |
|---|---|---|---|
| Q1 | Nome final do jogo? | "Farm Collect" é provisório | M9 (página da Steam antes, idealmente M7) |
| Q2 | Monetização? | Premium / Steam pago + mobile com anúncios / F2P + IAP (ver doc 08) | M8 |
| Q6 | Prestígio na v1? | Não (recomendado, entra depois da fábrica) / sim | M8 |
| Q8 | Personagem do jogador: fixo ou escolhível (cor/gênero)? | Fixo na v1 / customização simples | M7 |
