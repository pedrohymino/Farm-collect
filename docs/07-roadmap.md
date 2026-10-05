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

## M4 — Desbloqueios e expansão · G
- [ ] `UnlockSystem` + `unlocks.json` + pads com drenagem de dinheiro e progresso parcial.
- [ ] Grupos `unlock:<id>` ativando com animação; panorâmica de câmera em área nova.
- [ ] Áreas A2 (trigo — colheita ao passar) e A3 (curral, leite) com seus balcões.
- [ ] Seta guia de onboarding nos primeiros passos.

**Aceite:** é possível ir do início até a primeira vaca só jogando, seguindo a sequência da tabela 6 do doc 03,
e o save reconstrói a fazenda corretamente.

## M5 — Upgrades, nível e passivas · M
- [ ] Mesa de Upgrades + menu (níveis, custo exponencial, efeito do próximo nível).
- [ ] XP da fazenda, nível, estrelas, banner de subir de nível.
- [ ] Árvore de passivas (UI em grafo, vizinhança, nós-chave como Ímã).

**Aceite:** comprar upgrade/passiva muda os status certos (verificável no breakdown do dev mode); testes de custo e vizinhança verdes.

## M6 — Automação e caminhões · G
- [ ] Ajudantes: caixa, carregador, coletor de dinheiro.
- [ ] Máquinas de fazenda: esteira de ovos, ordenhadeira, irrigação.
- [ ] Área A4: caminhões com pedidos.
- [ ] Ganhos offline (renda automatizada medida, teto, eficiência, proteção de relógio).
- [ ] Placa "Terreno à venda" (teaser da fábrica).

**Aceite:** com caixas + carregadores a fazenda gera dinheiro sem o jogador; fechar e reabrir o jogo mostra ganho offline coerente.

## M7 — Arte, animação e áudio · G
- [ ] Textura-paleta e material único.
- [ ] Modelos finais (Blender MCP + pacotes CC0) substituindo placeholders.
- [ ] Personagens animados (jogador, clientes, ajudantes) e animais.
- [ ] VFX completos, SFX, música, vibração no mobile.
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
