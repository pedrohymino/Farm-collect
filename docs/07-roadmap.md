# 07 — Roadmap de Desenvolvimento

Cada marco termina **jogável** e com critérios de aceite verificáveis. Complexidade: P (pequeno), M (médio), G (grande).
Ordem pensada para validar a diversão o mais cedo possível (M2) antes de investir em arte (M7).

---

## M0 — Setup do projeto · P · ✅ concluído (2026-10-05)
- [x] Projeto Godot 4.7 com renderer Compatibility, estrutura de pastas do doc 04.
- [x] `.gitignore` (`.godot/`, traduções geradas, builds), `.gitattributes` (LF, binários), `.editorconfig`.
      Arquivos `.import` e `.uid` **são** versionados (guardam configurações de import e IDs).
- [x] Addon GUT 9.7.1 instalado; testes de fumaça rodando headless (4/4).
- [x] gdtoolkit 4.5 com `gdformat`/`gdlint` (`gdlintrc`).
- [x] `locale/strings.csv` com pt_BR e en, idioma padrão do sistema, fallback en.
- [x] Autoloads vazios registrados (EventBus, ContentDB, Stats, GameState, Economy, SaveManager, DevMode).
- [x] `CLAUDE.md` do projeto e `README.md`.
- [x] Tela: base 1080×1920 (retrato), janela de PC 1600×900, stretch `canvas_items`/`expand`, mobile travado em retrato.

**Aceite:** o projeto abre no editor sem erros, `main.tscn` roda (tela vazia), testes rodam via linha de comando.

## M1 — Fundação de sistemas · M · ✅ concluído (2026-10-05)
- [x] `StatRegistry` (lógica pura) + `Stats` (autoload) + `StatDef` + `Modifier` (fórmula, cache, sinal, breakdown, camada dev,
      status com escopo, recarga de definições mantendo modificadores).
- [x] `BalanceData` + `ContentDB` carregando e validando `data/balance/*.json` (stats, items, progression).
      `.tres` de conteúdo entram no M2, junto com os visuais.
- [x] `ItemContainer` com capacidade ao vivo (Callable/status), filtro de tipos, `transfer_one`, serialização.
- [x] `Wallet` + `Economy` (ganhar/gastar, nunca negativo, eventos) + `NumberFormat` (1.2K, 3.4M, 1aa…; sempre arredonda para baixo).
- [x] `SaveStore` (escrita atômica, `.bak`, fallback, quarentena de save corrompido) + `SaveMigrator` + `GameData` + `GameState` + `SaveManager`
      (autosave 30 s, salvar ao fechar/pausar, inativo em testes).
- [x] 79 testes (unitários + integração dos autoloads) verdes; save verificado de ponta a ponta rodando o jogo.

**Aceite:** testes verdes cobrindo fórmula, containers, economia, formatação e save (ida e volta + migração fictícia v0→v1).

## M2 — Primeiro loop jogável (graybox) · G · ✅ implementado (2026-10-05) — aguardando validação de diversão
- [x] Cena da fazenda área A1 (`src/gameplay/locations/farm/farm.tscn`): chão, quintal, cercas (`FenceLine`), estrada, árvores.
- [x] Jogador (`Player`) com movimento relativo à câmera (teclado/controle), câmera isométrica seguindo (`FollowCamera`),
      retrato e paisagem (o lado estreito da tela fica constante).
- [x] Galinheiro (`Producer` + `coop.tscn`) com 2 galinhas, `ProductionCycle` por galinha, pilha de saída com capacidade.
- [x] Zona de coleta (`TransferZone`) → pilha nas mãos (`StackVisual`) com balanço; "MÁX" quando cheia; tipos misturados.
- [x] Balcão (`Counter` + `counter.tscn`): zona de entrega (só puxa o tipo certo), estoque, ponto VENDER, fila, pilha de dinheiro.
- [x] Clientes (`Customer` + `CustomerSpawner`): chegam, fazem fila, compram, saem felizes/tristes (paciência).
- [x] HUD com dinheiro (contador rolando + pulso).
- [x] Juice: itens voando em arco, pop de escala, "+$X" flutuante, notas voando ao coletar, sons gerados (`AudioDirector` via EventBus).
- [x] Save/carregar do estado da fazenda (`Location` + grupo `persistent_station`).
- [x] Lógica pura testada: `ProductionCycle`, `YieldRoller`, `TransferTicker`, `CounterService`, `SaleRules`, `MoneyStash`, `IsoInput`;
      teste de integração do loop completo na cena real. Demo automática em `tools/demo/` para gravar o loop.

**Aceite:** dá para jogar o loop coletar → entregar → vender → pegar dinheiro por 5 minutos e **já é gostoso**.
Este é o principal ponto de validação do projeto: se não estiver divertido aqui, ajustamos antes de seguir.

## M3 — Dev mode v1 · M · ✅ concluído (2026-10-05)
- [x] Painel (`src/dev/`) aberto com F1 / ` ou 5 toques no canto superior esquerdo; só em debug ou feature tag `dev`.
- [x] Aba Status: todos os status, favoritos primeiro, busca, multiplicador, valor fixo, base, reset, "aplicar na base", breakdown.
- [x] Abas Economia (somar/definir dinheiro e estrelas), Tempo (velocidade 0.1×–10×, pausa),
      Mundo (encher/esvaziar pilhas, gerar cliente, FPS/draw calls, alternar retrato/paisagem).
- [x] Aba Save e balanço: salvar, recarregar, resetar save, copiar/colar save, presets nomeados,
      recarregar JSON do disco, gravar bases no `stats.json` (só pelo executável do editor, com confirmação e diff).
- [x] Sessão de tuning persistida em `user://dev/session.json` (fora do save do jogador); selo "DEV ×N" com overrides ativos.
- [x] `BalanceWriter` reproduz o formato do `stats.json` byte a byte (diffs pequenos). Mapa de entrada reproduzível em `tools/setup_input_map.gd`.
- [x] Testes: `BalanceWriter`, `DevSessionStore`, `SaveStore.delete_all` e integração do painel com o `Stats` real (149 verdes).

**Aceite:** alterar `player.carry_capacity` e `production.yield` ao vivo muda o jogo imediatamente;
um valor ajustado pode ser gravado no JSON e persiste ao reabrir.

## M4 — Desbloqueios e expansão · G · ✅ concluído (2026-10-05)
- [x] `UnlockRules` (lógica pura) + autoload `Unlocks` + `data/balance/unlocks.json` (custo, requisitos, unidades extras), validado
      (requisitos existentes, sem ciclos, unidades dentro do máximo).
- [x] `UnlockPad`: drena o dinheiro em ~1,5 s, guarda pagamento parcial, notas voando, confete; um pad que surge sob o jogador
      exige sair e entrar de novo (não gasta sem querer).
- [x] `Location` aplica desbloqueios: grupos `unlock:<id>` aparecem com "pop", `lock:<id>` (cercas no caminho) somem;
      câmera dá uma olhada nas áreas novas (`FollowCamera.focus_on`).
- [x] Área A2 Campo (leste): plantação de trigo (`CropField`, colhida ao passar por cima) + balcão de trigo.
      Área A3 Pasto (oeste): curral com vacas (leite) + balcão de leite. Galinhas extras e canteiros extras por desbloqueio.
- [x] Onboarding (`GuideArrow`): seta no chão + marcador sobre o próximo objetivo nos 5 primeiros passos; progresso salvo.
- [x] Dev mode: aba Progressão (desbloquear próximo/tudo, resetar, pular onboarding) + "amadurecer plantações".
- [x] Testes: `UnlockRules`, autoload `Unlocks`, integração na fazenda (pad, pagamento parcial, cercas, colheita, curral,
      reconstrução pelo save) e onboarding — 179 verdes.

**Aceite:** é possível ir do início até a primeira vaca só jogando, seguindo a sequência da tabela 6 do doc 03,
e o save reconstrói a fazenda corretamente.

## M5 — Upgrades, nível e passivas · M · ✅ concluído (2026-10-05)
- [x] `EffectSpec` (efeitos de dados → modificadores), `UpgradeRules`, `PassiveRules`, `FarmLevelRules` (lógica pura) + autoload `Progression`
      (compra, reaplica tudo ao carregar o save, XP das vendas, nível → estrelas).
- [x] `data/balance/upgrades.json` (6 upgrades, custo exponencial, nível máximo opcional) e `passives.json`
      (3 ramos × 5 nós: Fazendeiro, Produção, Comércio; nós-chave Ímã, Super safra, Clientes VIP).
- [x] Mesa de Upgrades (desbloqueio `upgrade_board`, $40) + menu inferior (`UpgradeMenu`) com nível, efeito e preço.
- [x] HUD: nível + barra de XP, estrelas, botão "Passivas", banner "Nível X!". Árvore radial (`PassiveTreeScreen`) com estados
      comprado/disponível/bloqueado e painel de detalhe.
- [x] Efeitos dos nós-chave no jogo: Ímã (coleta a distância em pilhas e plantações), Super safra (×10), Cliente VIP (×5).
- [x] Dev mode: +XP, subir de nível, resetar upgrades e passivas; recarregar balanço recarrega desbloqueios e progressão.
- [x] Testes: regras puras, autoload, UI (menu e árvore) e efeitos na fazenda — 226 verdes.

**Aceite:** comprar upgrade/passiva muda os status certos (verificável no breakdown do dev mode); testes de custo e vizinhança verdes.

## M6 — Automação e caminhões · G · ✅ concluído (2026-10-05)
- [x] Ajudantes (`Worker` + `WorkerBrain` puro): caixa (3 balcões), carregador (galinheiro → balcão), coletor de dinheiro
      (percorre as pilhas e leva ao caixa). Camada física própria: não bloqueiam o jogador, as zonas os detectam.
- [x] Desbloqueios com efeitos de status (`unlocks.json` → `effects`): irrigação (+40% trigo), ordenhadeira (+50% leite);
      esteira de ovos (`Conveyor`, itens andando na esteira, vazão `machine.conveyor_rate × machine.speed`); vacas #3 e #4.
- [x] Doca de carga (norte) + pedidos de caminhão (`TruckBay` + `TruckOrderRules`): pedido cresce com o nível, paga com bônus
      (`truck.bonus`), pedido aberto é salvo.
- [x] Ganhos offline (autoload `Offline` + `IncomeMeter` + `OfflineRules`): só renda automática (venda sem o jogador no caixa),
      teto em horas, eficiência, proteção contra relógio voltando; popup "Bem-vindo de volta".
- [x] Placa "Em breve: Fábrica" (aparece com o coletor de dinheiro).
- [x] Ramos Automação e Descanso da árvore + upgrade Treinamento, liberados só depois do primeiro ajudante (`requires_unlock`).
- [x] Dev mode: caminhão agora, simular 1h/8h offline.
- [x] Testes: regras puras + integração na fazenda (caixa, carregador, esteira, efeitos, caminhão, coletor, offline) — 253 verdes.

**Aceite:** com caixas + carregadores a fazenda gera dinheiro sem o jogador; fechar e reabrir o jogo mostra ganho offline coerente.

## M7 — Arte, animação e áudio · G · 🔶 em andamento
- [x] Textura-paleta (`assets/textures/palette.png`, gerada por `art/textures/generate_palette.py`, 64 cores).
- [x] Barramentos de áudio Music/SFX (`default_bus_layout.tres`), música cozy em loop (placeholder sintetizado).
- [x] Vibração no celular (`Haptics`), poeira ao correr (`DustTrail`), brilho nas pilhas de dinheiro (`Sparkle`).
- [x] **Direção de arte: Kenney (CC0)** — Mini Characters, Cube Pets, Food Kit, Mini Forest/Dungeon/Arena (decisão D24).
      `tools/sync_models.py` copia só o que o jogo usa, cria um material compartilhado por pacote (`assets/materials/kenney_*.tres`)
      e aponta o import de cada `.glb` para ele (nearest, sem compressão com perda).
- [x] Personagens (jogador, 3 tipos de ajudante, 8 clientes) com animação por velocidade (idle/walk/sprint) e versão "carregando"
      (pernas do andar + braços do `holding-both`): `CharacterModel`, `LocomotionRules`, `CarryPose`.
- [x] Animais (galinha, vaca) com idle/walk/eat; galinheiro = tenda; curral = abrigo de telhado azul; balcão = mesa; árvores; cerca
      em um único MultiMesh (`FenceLine`).
- [x] Ovo e leite do Food Kit. Trigo e caminhão continuam modelados por nós (`art/blender/scripts/models.py`).
- [x] Fonte Fredoka (OFL) em todo o jogo.
- [x] **KayKit (CC0)** para construções e cenário: mercados nas 3 cores como balcões (pilha de itens na frente da loja), moinho, poço,
      casas, andaime como teaser da fábrica, poço da irrigação, estação de ordenha, arbustos, pedras e caixotes. Personagens ~1,05 m.
- [ ] Ainda provisórios: canteiros do trigo, esteira, estrada/chão liso (tiles hexagonais do KayKit são uma opção), caminhão e trigo (nossos).
- [ ] Modelos finais (Blender MCP + pacotes CC0) substituindo placeholders.
- [ ] Personagens animados (jogador, clientes, ajudantes) e animais.
- [ ] VFX restantes; SFX e música finais (substituir os sintetizados).
- [ ] UI final (fonte, ícones, botões).
- [ ] `CREDITS.md`.

**Aceite:** o jogo se parece com os anúncios de referência; 60 FPS mantidos no PC de teste.

## M8 — Polimento e meta · M
- [ ] Menu principal, pausa, configurações (volume, idioma, vibração, qualidade gráfica).
- [ ] Revisão de balanceamento contra as metas de ritmo (doc 03, seção 7).
- [ ] Robustez de save (corrompido, sem espaço, relógio alterado).
- [ ] Testes de jogo com outras pessoas.

**Aceite:** sessão nova até a fazenda completa sem travas, bugs bloqueantes ou momentos "sem objetivo".

## M9 — Plataformas e lançamento · G
- [ ] Export presets com `*.json` no filtro de recursos não-Godot ("Filters to export non-resource files"),
      senão `data/balance/` fica fora do build. Testar um build exportado, não só o editor.
- [ ] Steam: GodotSteam, conquistas, Steam Cloud, controle completo, Steam Deck (1280×800).
- [ ] Android: joystick de toque, layout retrato, AAB assinado, teste em aparelho real.
- [ ] iOS: export via Xcode (exige Mac), teste em aparelho.
- [ ] Monetização conforme decisão (doc 09).
- [ ] Página da loja: capsules, screenshots, trailer (gravado do próprio jogo — nosso "anúncio" honesto).

**Aceite:** builds aprovados e instaláveis nas três lojas (ou acesso antecipado na Steam).

---

## Depois da v1
- **Fábrica** (doc 02, seção 11; doc 04, seção 9).
- Prestígio, mais itens/animais, eventos sazonais, mais idiomas.
- Build Web para demo/anúncio jogável.

## Fluxo de trabalho por marco
1. Ler o doc do marco e quebrar em tarefas.
2. Lógica pura com teste primeiro (TDD) → implementar → testes verdes.
3. Cena/visual → jogar e ajustar com dev mode.
4. `gdformat` + `gdlint` + testes.
5. Revisão de código.
6. Commit/push **só com aprovação do usuário**.
