# Farm Collect (nome provisório)

Jogo cozy, casual e incremental de fazenda em 3D low-poly isométrico, no estilo "idle arcade":
coletar, empilhar, vender, desbloquear e automatizar. Feito em Godot 4.7.

**Status:** M0–M3 prontos (setup, sistemas, primeiro loop jogável, dev mode) — próximo: M4 (desbloqueios e expansão).

Dev mode: **F1** (ou `'`) abre o painel de ajuste ao vivo; no celular, 5 toques rápidos no canto superior esquerdo.

Controles: WASD / setas / analógico. Pise nas zonas ciano: coletar ovos → entregar no balcão → ficar no "VENDER" → pegar o dinheiro.

## Rodando

```bash
"C:/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --import
"C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe"
```

Demo automática (o jogador joga sozinho, útil para gravar): `"C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe" res://tools/demo/autoplay_demo.tscn`

Testes: `"C:/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd`

## Documentação

| Doc | Conteúdo |
|---|---|
| [01 — Visão](docs/01-visao.md) | Pitch, pilares, público, escopo |
| [02 — Game Design](docs/02-game-design.md) | Loops, entidades, progressão, upgrades, passivas, fábrica futura |
| [03 — Economia e Balanceamento](docs/03-economia-e-balanceamento.md) | Status, fórmulas, custos, sequência de desbloqueios, ritmo |
| [04 — Arquitetura](docs/04-arquitetura.md) | Estrutura do projeto Godot, sistemas, save, desempenho |
| [05 — Dev Mode](docs/05-dev-mode.md) | Painel de ajuste ao vivo |
| [06 — Arte e Áudio](docs/06-arte-e-audio.md) | Direção de arte, pipeline, lista de assets, sons |
| [07 — Roadmap](docs/07-roadmap.md) | Marcos M0–M9 com critérios de aceite |
| [08 — Plataformas e Lançamento](docs/08-plataformas-e-lancamento.md) | Steam, Android, iOS, monetização |
| [09 — Decisões e Perguntas](docs/09-decisoes-e-perguntas.md) | Registro de decisões e pendências |

## Requisitos
- Godot 4.7.2 Standard — `C:\Program Files\Godot\`
- Python + `pip install gdtoolkit` (formatação e lint de GDScript)
- Blender (opcional, para arte via MCP)
