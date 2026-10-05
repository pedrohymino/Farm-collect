# 08 — Plataformas e Lançamento

## Visão geral

| Plataforma | Custo | Requisitos | Integração no Godot |
|---|---|---|---|
| **Steam** (PC + Steam Deck) | US$ 100 por jogo (Steam Direct) | Conta Steamworks, dados fiscais/bancários | GodotSteam (GDExtension) — conquistas, cloud save, overlay |
| **Android** (Google Play) | US$ 25 (uma vez) | Conta Play Console, keystore de assinatura, teste fechado obrigatório para contas novas | Export Android nativo do Godot (AAB) |
| **iOS** (App Store) | US$ 99/ano | **Mac com Xcode** (ou Mac na nuvem / runner macOS de CI), Apple Developer | Export iOS do Godot → projeto Xcode |

Ordem: Steam → Android → iOS. Desenvolver e testar no PC o tempo todo; testar em celular real a partir do M6.

## Steam
- Steam Deck: controle completo (nada exige mouse), texto legível em 1280×800, alvo "Deck Verified".
- Conquistas sugeridas: primeira venda, primeira vaca, primeiro ajudante, $1M ganhos, árvore completa, fazenda completa.
- Steam Cloud para `user://saves/`.
- Página "Em breve" o quanto antes para juntar wishlists.
- Confirmar compatibilidade do GodotSteam com Godot 4.7 no momento do M9.

## Mobile
- **Orientação:** retrato (decisão D11), travado em retrato no mobile. PC/Steam em paisagem.
  A câmera e o HUD se adaptam à proporção (doc 04, seção 10).
- Joystick virtual flutuante; botões ≥ 48 dp; respeitar áreas seguras (notch).
- Pausa e save ao ir para segundo plano.
- Política de privacidade obrigatória (mesmo sem coletar dados) e classificação etária nas lojas.
- Se houver anúncios/IAP: plugins de AdMob/compras para Godot, consentimento GDPR/LGPD, ATT no iOS.

## Monetização (a decidir — doc 09)

| Modelo | Prós | Contras |
|---|---|---|
| **Premium** (pago, ex.: US$ 4,99) em todas | Simples, sem plugins de anúncio, combina com Steam | Mobile pago vende pouco |
| **Steam pago + mobile grátis com anúncios recompensados** | Padrão do gênero no mobile; anúncio opcional ("dobrar ganho offline") é bem aceito | Mais trabalho (SDKs, consentimento), economia precisa considerar os bônus |
| **Grátis + IAP** (remover anúncios, pacote inicial) | Maior potencial no mobile | Mais design de economia e mais suporte |

Recomendação inicial: **Steam pago + mobile grátis com anúncios recompensados opcionais e IAP "remover anúncios"**.
A arquitetura já deixa os pontos de bônus (ganho offline, multiplicador temporário) como eventos, então anúncios entram depois sem mexer na economia base.

## Material de loja
- Ícone, capsules da Steam (vários tamanhos), 5+ screenshots por plataforma, trailer de 30–60 s.
- O trailer pode ser exatamente o "anúncio do Township que é verdade": gravado direto do jogo.

## Cuidados legais
- Não usar nome, logo, personagens ou assets do Township/Playrix, nem frases dos anúncios deles.
- Todos os assets de terceiros com licença que permite uso comercial, registrados em `CREDITS.md`.
- Verificar disponibilidade do nome final (lojas, marca, domínio) antes de anunciar.
