## Projeto

**Farm Collect** (nome provisório) — jogo cozy/casual/incremental de fazenda, 3D low-poly isométrico, estilo "idle arcade"
(coletar → empilhar → vender → desbloquear → automatizar). Alvo: Steam (inclui Steam Deck), depois Android e iOS.

Toda a especificação está em `docs/` — **ler o doc relevante antes de implementar**:
visão (01), game design (02), economia (03), arquitetura (04), dev mode (05), arte/áudio (06),
roadmap (07), plataformas (08), decisões/perguntas (09). Atualizar o doc quando uma decisão mudar
e registrar decisões novas no 09.

## Stack (decidido — ver docs/09)

- Godot 4.7.2 Standard, GDScript com tipagem estática, renderer Compatibility.
- Executáveis: `C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe` (editor) e
  `C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe` (headless/testes).
- Testes: GUT em `tests/` · Formatação/lint: `gdformat` e `gdlint` (gdtoolkit).
- Arte: Blender via MCP (scripts em `art/blender/scripts/`), personagens animados de pacotes CC0. Exportar `.glb`.

## Comandos

```bash
# (re)importar assets/traduções — necessário após clonar ou mudar locale/strings.csv
"C:/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --import
# testes headless (config em .gutconfig.json)
"C:/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd
# rodar o jogo
"C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe"
# abrir o editor
"C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe" -e
# formatação e lint (config do lint em gdlintrc)
gdformat src tests
gdlint src tests
```

`addons/gut` é código de terceiros (GUT 9.7.1, MIT) — não editar, não formatar.
Arquivos `*.translation` são gerados pelo import a partir de `locale/strings.csv` (ignorados no git).

## Regras de arquitetura

- **Todo valor de gameplay vem do `Stats`** (status + modificadores). Nunca ler `data/balance/*.json` direto no gameplay,
  nunca usar números mágicos. Status novo = entrada em `data/balance/stats.json`.
- Upgrades e passivas só registram modificadores com `source_id`; não têm lógica própria.
- Tudo que guarda itens é `ItemContainer`; mover itens é `TransferZone`/transferência entre containers.
- Lógica em classes `RefCounted` puras e testáveis; nós de cena só fazem visual/input.
- Eventos globais pelo `EventBus`; áudio/juice/conquistas escutam, gameplay não conhece quem escuta.
- Visual referenciado por cena wrapper (`.tscn`) — trocar arte = trocar o `.glb`.
- A fazenda é uma `Location`; a futura fábrica será outra. Não acoplar lógica à fazenda.
- Save versionado com migrações; nunca quebrar saves antigos.

## Convenções

- GDScript: `snake_case` (variáveis, funções, arquivos), `PascalCase` (`class_name`), `UPPER_SNAKE_CASE` (constantes),
  sinais no passado (`item_sold`), tipagem estática em tudo.
- **Nenhum texto visível hardcoded**: tudo via `tr("CHAVE")` em `locale/strings.csv` (pt_BR + en).
- Código, identificadores e IDs em inglês; docs e conversa em português.
- Ao alterar código testável, criar/atualizar testes na mesma tarefa.
- Rodar `gdformat` + `gdlint` nos arquivos tocados e os testes antes de considerar uma tarefa pronta.
- Nada de assets/nomes do Township. Todo asset de terceiros registrado em `CREDITS.md`.

## Colaboração

- Edições locais, builds, testes e instalações de ferramentas: fazer sem perguntar.
- **Commit, push e qualquer operação git destrutiva: só com aprovação explícita.**
- Trabalhar marco a marco seguindo `docs/07-roadmap.md`; o M2 é o ponto de validação da diversão.
