# Créditos e licenças

Todo asset ou código de terceiros usado no projeto, com origem e licença.

## Código

| O quê | Origem | Licença | Uso |
|---|---|---|---|
| GUT 9.7.1 (Godot Unit Test) | https://github.com/bitwes/Gut | MIT | Só desenvolvimento (testes); fica fora do build final |

## Áudio

| Arquivo | Origem | Licença |
|---|---|---|
| `assets/audio/sfx/*.wav` | Sintetizados por nós com `art/audio/generate_sfx.py` (placeholders) | Próprio |
| `assets/audio/music/farm_loop.wav` | Sintetizada por nós com `art/audio/generate_music.py` (placeholder) | Próprio |

## Texturas

| Arquivo | Origem | Licença |
|---|---|---|
| `assets/textures/palette.png` | Gerada por `art/textures/generate_palette.py` | Próprio |

## Fontes

| Arquivo | Origem | Licença |
|---|---|---|
| `assets/fonts/Fredoka.ttf` | Fredoka — The Fredoka Project Authors, via github.com/google/fonts | SIL OFL 1.1 (`assets/fonts/Fredoka-OFL.txt`) |

## Modelos 3D

Todos os pacotes do Kenney (kenney.nl) são **CC0 1.0** (domínio público): uso comercial livre, sem atribuição obrigatória.
Os arquivos usados ficam em `assets/models/kenney/<pacote>/`, cada um com o `License.txt` original.

| Pacote | Link | Usado para |
|---|---|---|
| Mini Characters | https://kenney.nl/assets/mini-characters | Fazendeira, clientes e ajudantes (12 personagens com animações) |
| Cube Pets | https://kenney.nl/assets/cube-pets | Galinha e vaca (com animações idle/walk/eat) |
| Food Kit | https://kenney.nl/assets/food-kit | Ovo e caixa de leite |
| Mini Forest | https://kenney.nl/assets/mini-forest | Árvores, cerca, tenda do galinheiro, abrigo do curral |
| Mini Dungeon | https://kenney.nl/assets/mini-dungeon | Mesa do balcão (e peças futuras: baú, moeda, barril) |
| Mini Arena | https://kenney.nl/assets/mini-arena | Estandarte da Mesa de Upgrades |

### KayKit (Kay Lousberg, www.kaylousberg.com) — CC0 1.0

Pacotes gratuitos do KayKit, licença CC0 (uso comercial livre; dar crédito é bem-vindo, não obrigatório). Arquivos usados em
`assets/models/kaykit/<pacote>/`, cada um com o `License.txt` original.

| Pacote | Usado para |
|---|---|
| Medieval Hexagon Pack 1.0 | Mercados (balcões nas 3 cores), moinho, poço, casas, andaime da fábrica, carrinho, sacos, caixotes, barris, baldes, bandeira, pedras |
| Forest Nature Pack 1.0 | Arbustos e pedras de enfeite |

Modelados por nós no Blender (`art/blender/scripts/`, paleta própria): `assets/models/items/wheat.glb` e
`assets/models/props/truck.glb`. As demais cenas em `assets/models/**/*.tscn` são wrappers que instanciam os modelos acima
(ou placeholders de primitivas do Godot: aspersor, ordenhadeira, placa da fábrica).
