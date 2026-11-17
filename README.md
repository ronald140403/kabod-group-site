# KABOD GROUP · site institucional

Home em HTML único (CSS e JS embutidos), modo claro e escuro, hospedada na Vercel em **https://www.kabodgroup.com.br**.

## Estrutura
- `index.html`: página inicial
- `assets/`: logos (versões 1, 2 e 3), favicon, foto real da obra, imagem de compartilhamento 1200×630
- `vercel.json`: redirecionamento `kabodgroup.com.br` → `www`, cabeçalhos de segurança e cache
- `robots.txt`, `sitemap.xml`

## Botões
Todos os CTAs abrem o WhatsApp (31) 99998-0900 com mensagem por intenção (`data-wa`):
`cotacao` (preciso de máquinas), `cadastro` (tenho máquinas) e `geral`. A origem de campanha (UTM, gclid, fbclid) vai no fim da mensagem.

## Banco de dados (Supabase · projeto `kabod-group`, região São Paulo)
- `cta_eventos`: cada clique em CTA (botão, intenção, seção, UTM, dispositivo, tema). Sem nome, telefone ou IP.
  `gclid`/`fbclid` só são gravados com consentimento "Aceitar".
- `leads`: pronto para os formulários das páginas *Solicite uma máquina* e *Seja um fornecedor* (exige consentimento LGPD).
- `equipe`: quem pode ler os dados (login no Supabase Auth).
- O navegador só grava pelas funções `registrar_evento` e `registrar_lead`. Não há leitura pública.
- Chave usada no site: publicável (`sb_publishable_…`), segura no navegador. A chave secreta nunca entra no repositório.

## Campanhas
Preencher `KABOD_TAGS` (GTM, Meta Pixel, Google Ads) no fim do `index.html`. Os pixels só carregam após "Aceitar" no aviso de cookies.

## Pendências
- Política de privacidade: por decisão do cliente, só o aviso de cookies (aceitar ou apenas essenciais).
- Páginas internas: Solicite uma máquina, Seja um fornecedor, Quem somos, Locação, Intermediação, Contato.
- Fotos de banco (Unsplash) carregadas do CDN do Unsplash; substituir por fotos próprias da frota.
