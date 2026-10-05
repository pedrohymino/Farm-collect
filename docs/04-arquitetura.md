# 04 — Arquitetura Técnica

**Engine:** Godot 4.7.2 (Standard) · **Linguagem:** GDScript com tipagem estática ·
**Renderer:** Compatibility (OpenGL) · **Testes:** GUT · **Formatação/lint:** gdtoolkit (`gdformat`, `gdlint`)

Executável local: `C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe`
(console: `Godot_v4.7.2-stable_win64_console.exe`, usado para testes headless).

## 1. Princípios

1. **Dados separados de lógica.** Números em `data/balance/*.json`; identidade/visual em Resources `.tres`.
2. **Todo número de gameplay passa pelo `Stats`.** Código nunca lê o JSON direto nem usa constante mágica.
   Isso dá dev mode, upgrades e passivas "de graça" para qualquer coisa nova.
3. **Tudo que guarda itens é um `ItemContainer`.** Jogador, pilha do produtor, balcão, ajudante, caminhão,
   (futuro) máquina da fábrica. Transferir é sempre "container A → container B a uma taxa".
4. **Lógica pura testável, cena só desenha.** Regras em classes `RefCounted` sem nós (testáveis headless);
   nós `Node3D` só conectam lógica com visual/input.
5. **Comunicação desacoplada via `EventBus`.** Áudio, juice, conquistas e analytics escutam eventos;
   gameplay não conhece quem escuta.
6. **Localidades genéricas.** A fazenda é uma `Location`; a fábrica será outra.

## 2. Estrutura de pastas

```
project.godot
addons/
  gut/                      # testes
  godotsteam/               # (M9) integração Steam
assets/
  models/<categoria>/*.glb  # exportados do Blender ou de pacotes CC0
  textures/palette.png      # textura-paleta única
  audio/sfx/  audio/music/
  fonts/
art/                        # fontes de arte, ignorado pelo Godot (.gdignore)
  blender/*.blend
  blender/scripts/*.py      # scripts que geram/exportam modelos (reprodutível via Blender MCP)
data/
  balance/*.json            # números (ver doc 03)
  content/items/*.tres      # ItemDef
  content/producers/*.tres  # ProducerDef
  content/upgrades/*.tres   # UpgradeDef (ícone, nome; números vêm do JSON)
  content/passives/*.tres
locale/
  strings.csv               # chaves → pt_BR, en
src/
  core/                     # autoloads e sistemas puros
    event_bus.gd            # autoload
    game_state.gd           # autoload (guarda o GameData vivo)
    save_manager.gd         # autoload
    content_db.gd           # autoload
    economy.gd              # autoload
    balance_data.gd         # carrega/valida data/balance/*.json
    game_data.gd            # tudo que vai para o save
    wallet.gd               # moedas
    number_format.gd
    save/ save_store.gd, save_migrator.gd
    stats/ stat_system.gd (autoload), stat_registry.gd (lógica pura), stat_def.gd, modifier.gd
    items/ item_container.gd
    progression/ unlock_system.gd, upgrade_system.gd, passive_tree.gd, farm_level.gd, offline_earnings.gd
  gameplay/
    player/ player.tscn, player.gd, stack_visual.gd
    camera/ follow_camera.gd
    stations/ producer.gd, crop_field.gd, pickup_zone.gd, drop_zone.gd, counter.gd,
              cashier_spot.gd, money_pile.gd, unlock_pad.gd, upgrade_board.gd, truck_bay.gd
    npcs/ customer.gd, worker.gd, truck.gd
    locations/ location.gd, farm/farm.tscn
    fx/ juice.gd, fly_to.gd, popups
  ui/
    hud/  upgrade_menu/  passive_tree/  offline_popup/  settings/  touch_joystick/
  dev/
    dev_mode.gd (autoload), dev_panel.tscn
  main.tscn / main.gd
tests/
  unit/  integration/
docs/
```

## 3. Sistema de status e modificadores

```gdscript
# Conceito (assinaturas, não implementação final)
class_name StatSystem  # autoload "Stats"
func get_value(stat_id: StringName) -> float
func get_scoped(stat_id: StringName, scope: StringName) -> float   # global × específico (ex.: production.rate × production.rate.egg)
func add_modifier(mod: Modifier) -> void
func remove_modifiers_from(source_id: StringName) -> void
func set_dev_override(stat_id: StringName, multiplier: float, absolute: Variant = null) -> void
func breakdown(stat_id: StringName) -> Dictionary                    # para o painel dev
signal stat_changed(stat_id: StringName, value: float)
```

- `StatDef` (vindo de `stats.json`): `id`, `base`, `min`, `max`, `is_integer`.
- `Modifier`: `stat_id`, `type` (FLAT | PERCENT | MULTIPLIER), `value`, `source_id`
  (ex.: `upgrade:boots`, `passive:farmer_3`, `dev`).
- Fórmula em [03-economia](03-economia-e-balanceamento.md#2-fórmula-de-status).
- Valores **em cache**; invalidados quando um modificador daquele status muda; `stat_changed` emitido.
- Quem consome (ex.: `Player`) lê `Stats.get_value()` no uso ou escuta `stat_changed`. Nunca guarda cópia própria do valor.
- Upgrades e passivas **não têm lógica própria**: comprar = registrar modificadores com seu `source_id`.
  Recarregar o save = reaplicar modificadores a partir dos níveis salvos.

## 4. Itens e containers

- `ItemDef` (Resource): `id`, `name_key`, `icon`, `mesh_scene`, `stage` (RAW | PROCESSED), `stack_height`.
  Preço e tempos vêm de `items.json`.
- `ItemContainer` (RefCounted): lista ordenada de itens (ordem importa para a pilha visual),
  `capacity_stat` (status que define o limite), `accepts` (filtro de tipos ou qualquer).
  Métodos: `can_accept(item)`, `push(item)`, `pop_matching(filter)`, `count(item)`, `is_full()`. Sinais `item_added/removed`.
- `TransferZone` (Area3D): quando um portador entra, transfere de A para B na taxa dada por um status
  (`player.pickup_rate`, etc.). Usada por coleta, entrega, caminhão e (futuro) doca de envio.
- **Visual separado da lógica:** `StackVisual` (pilha do jogador, nós individuais até ~60 itens visíveis, balanço)
  e `PileVisual` (pilhas grandes de produtores/dinheiro usando `MultiMeshInstance3D` para desempenho).

## 5. Estações e NPCs

| Nó | Responsabilidade |
|---|---|
| `Producer` | Timer por animal/canteiro → empurra itens no container de saída se houver espaço |
| `CropField` | Canteiros com estado (crescendo/maduro); colhidos ao jogador passar (área por canteiro) |
| `Counter` | Estoque (`ItemContainer`), fila de clientes, `CashierSpot`, `MoneyPile` |
| `MoneyPile` | Valor acumulado; visual em notas empilhadas; jogador coleta tudo ao pisar |
| `UnlockPad` | Lê `UnlockDef`; drena dinheiro; ao completar chama `UnlockSystem.complete(id)` |
| `UpgradeBoard` | Abre o menu de upgrades ao pisar |
| `Customer` | Máquina de estados: chegar → fila → esperar → comprar → sair |
| `Worker` | Máquina de estados com tarefa configurável (carregar A→B, ficar no caixa) |
| `Truck` | Pedido gerado, `ItemContainer` caçamba, paga ao completar |

Navegação de NPCs: caminhos simples com `Path3D`/waypoints por área (mais leve e previsível que navmesh).
Se ficar limitado, migrar para `NavigationRegion3D`.

## 6. Desbloqueios e mundo

- `unlocks.json` define cada desbloqueio: `id`, `cost`, `requires[]`, `area`.
- Na cena da fazenda, nós que pertencem a um desbloqueio ficam no grupo `unlock:<id>` e começam desativados.
  Ao completar: ativa com animação de "pop". Pads aparecem quando os pré-requisitos estão completos.
- Estado salvo: conjunto de IDs desbloqueados + progresso parcial de cada pad.
- Isso permite reconstruir a fazenda inteira só a partir do save.

## 7. Autoloads

| Autoload | Papel |
|---|---|
| `EventBus` | Sinais globais: `item_collected`, `item_sold`, `money_collected`, `unlock_completed`, `level_up`, … |
| `ContentDB` | Carrega `.tres` e `data/balance/*.json`, valida IDs na inicialização (falha cedo e com mensagem clara) |
| `Stats` | Sistema de status |
| `GameState` | Moedas, níveis de upgrade, nós de passiva, desbloqueios, XP — dados de runtime |
| `Economy` | Gastar/ganhar com validação (nunca negativo), formatação |
| `SaveManager` | Persistência |
| `DevMode` | Painel e overrides (desativado em release) |

## 8. Save

- Arquivo `user://saves/slot_0.json` com `schema_version`.
- Escrita **atômica**: grava `slot_0.tmp` → renomeia; mantém `slot_0.bak` do save anterior.
- Autosave a cada 30 s, ao desbloquear algo, ao pausar e ao sair/ir para segundo plano
  (`NOTIFICATION_APPLICATION_PAUSED` no mobile, `NOTIFICATION_WM_CLOSE_REQUEST` no PC).
- **Migrações:** lista ordenada de funções `migrate_vN_to_vN+1(data)`. Saves antigos sempre carregam.
- Save corrompido → tenta `.bak` → se falhar, avisa o jogador e começa novo jogo (nunca crasha).
- Configurações (volume, idioma, vibração) em arquivo separado `user://settings.cfg`.
- Steam Cloud (M9) sincroniza a pasta `user://saves/`.

### Notas de implementação (M1)
- Payload: `{"schema_version": N, "saved_at_unix": t, "data": GameData.to_dict()}`.
- `SaveManager` só lê/grava depois de `load_game()` (chamado por `main.gd`), para testes e ferramentas nunca tocarem no save do jogador.
- Save ilegível ou de versão mais nova → movido para `slot_0.corrupt-<unix>.json` (nunca apagado) e começa jogo novo.
- **Export:** os JSON de `data/balance/` precisam estar no filtro de arquivos não-recurso do export preset (M9).

## 9. Preparação para a Fábrica

O que a v1 já entrega para a fábrica entrar sem reescrever:

| Já existe na v1 | Uso futuro na fábrica |
|---|---|
| `Location` genérica com ID; `GameState` guarda estado por localidade | `factory` vira a segunda localidade |
| `ItemDef.stage` (RAW / PROCESSED) | Produtos processados |
| `ItemContainer` + `TransferZone` | Entrada/saída das máquinas de processamento |
| Status com escopo (`production.rate.<item>`) | `machine.speed.<receita>` |
| Placa "Terreno à venda" (A5) | Entrada da fábrica |

O que será criado depois: `RecipeDef` (entradas → saídas, tempo), estação `Processor`,
`ShippingDock` com divisão por item (% fábrica / % balcões) e `ShippingTruck` entre localidades.

## 10. Câmera, input e telas

- Câmera perspectiva, FOV ~35°, inclinação −50°, rotação 45° (visão isométrica dos anúncios), segue o jogador com suavização.
- **Mobile é retrato, PC é paisagem** (decisão D11). Resolução base 1080×1920, stretch `canvas_items` com aspecto `expand`;
  no mobile a orientação fica travada em retrato, no PC a janela abre em paisagem e pode ser redimensionada.
- Zoom ajustado pela proporção da tela: retrato (mobile) aproxima, paisagem (PC) mostra mais área.
- Durante o desenvolvimento, testar sempre nas duas proporções (dev mode terá atalho para alternar o tamanho da janela).
- UI com âncoras e `Container`s; HUD funciona em 16:9, 16:10 (Steam Deck) e 9:19.5 (celular).
- Input via `InputMap` (`move_left/right/up/down`) + joystick virtual em telas de toque. O jogador lê só um vetor de movimento.

## 11. Desempenho (orçamento)

| Item | Meta |
|---|---|
| FPS | 60 em Android intermediário; 60+ no Steam Deck |
| Draw calls | < 150 |
| Materiais | 1 material principal (textura-paleta) compartilhado por quase tudo |
| Pilhas grandes | `MultiMeshInstance3D` |
| Sombras | 1 luz direcional, sombra de baixa resolução ou "blob shadow" falsa sob personagens |
| Build | Alvo < 80 MB no PC, < 60 MB no mobile |

## 12. Internacionalização

- Todo texto visível vem de `locale/strings.csv` via `tr("CHAVE")`. Nada de texto fixo em cena ou script.
- Idiomas iniciais: português (pt_BR) e inglês (en). A Steam se beneficia muito de mais idiomas depois.

## 13. Qualidade

- **GDScript:** tipagem estática em tudo, `snake_case` para variáveis/funções, `PascalCase` para `class_name`,
  sinais no passado (`item_sold`), constantes em `UPPER_SNAKE_CASE`, sem números mágicos.
- **Formatação/lint:** `gdformat` e `gdlint` em todo arquivo tocado.
- **Testes (GUT, headless):** fórmula de status e modificadores, curvas de custo, `ItemContainer`/transferências,
  desbloqueios e pré-requisitos, árvore de passivas, save (ida e volta + migrações), ganhos offline,
  formatação de números. A sensação de jogo (feel) é validada jogando.
- Comando de teste:
  `"C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
