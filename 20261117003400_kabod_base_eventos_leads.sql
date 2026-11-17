-- Aplicada no projeto Supabase kabod-group (itrycrynlwdlaxrtbtfs) em 2026-11-17 (duas migrações, estado final abaixo).

create table public.equipe (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nome text not null check (char_length(nome) between 2 and 120),
  papel text not null default 'comercial' check (papel in ('admin','comercial')),
  criado_em timestamptz not null default now()
);

create table public.cta_eventos (
  id bigint generated always as identity primary key,
  criado_em timestamptz not null default now(),
  cta text not null check (cta in ('cotacao','cadastro','whatsapp','contato')),
  intencao text not null check (intencao in ('cotacao','cadastro','geral')),
  destino text not null default 'whatsapp' check (destino in ('whatsapp','email','pagina')),
  secao text check (char_length(secao) <= 40),
  pagina text check (char_length(pagina) <= 200),
  utm_source text check (char_length(utm_source) <= 200),
  utm_medium text check (char_length(utm_medium) <= 200),
  utm_campaign text check (char_length(utm_campaign) <= 200),
  utm_term text check (char_length(utm_term) <= 200),
  utm_content text check (char_length(utm_content) <= 200),
  gclid text check (char_length(gclid) <= 200),
  fbclid text check (char_length(fbclid) <= 200),
  referrer text check (char_length(referrer) <= 300),
  dispositivo text check (dispositivo in ('celular','tablet','desktop')),
  tema text check (tema in ('claro','escuro')),
  consentimento text not null default 'pendente' check (consentimento in ('all','essential','pendente'))
);
create index cta_eventos_criado_em_idx on public.cta_eventos (criado_em desc);
create index cta_eventos_campanha_idx on public.cta_eventos (utm_source, utm_campaign);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  tipo text not null check (tipo in ('contratante','fornecedor')),
  nome text not null check (char_length(nome) between 2 and 120),
  empresa text check (char_length(empresa) <= 160),
  cnpj text check (char_length(cnpj) <= 18),
  telefone text check (char_length(telefone) <= 30),
  email text check (char_length(email) <= 160),
  cidade text check (char_length(cidade) <= 80),
  uf text check (uf ~ '^[A-Z]{2}$'),
  equipamentos text check (char_length(equipamentos) <= 1000),
  mensagem text check (char_length(mensagem) <= 2000),
  origem jsonb not null default '{}'::jsonb,
  consentimento_lgpd boolean not null check (consentimento_lgpd),
  status text not null default 'novo' check (status in ('novo','em_atendimento','convertido','descartado')),
  check (telefone is not null or email is not null)
);
create index leads_criado_em_idx on public.leads (criado_em desc);
create index leads_status_idx on public.leads (status);

create or replace function public.tg_atualizado_em() returns trigger language plpgsql set search_path = ''
as $$ begin new.atualizado_em := now(); return new; end $$;
create trigger leads_atualizado_em before update on public.leads for each row execute function public.tg_atualizado_em();

create schema if not exists privado;
revoke all on schema privado from public, anon;
grant usage on schema privado to authenticated;
create or replace function privado.is_equipe() returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.equipe e where e.user_id = (select auth.uid())) $$;
revoke all on function privado.is_equipe() from public, anon;
grant execute on function privado.is_equipe() to authenticated;

alter table public.equipe enable row level security;
alter table public.cta_eventos enable row level security;
alter table public.leads enable row level security;
create policy "equipe vê equipe" on public.equipe for select to authenticated using ((select privado.is_equipe()));
create policy "equipe lê eventos" on public.cta_eventos for select to authenticated using ((select privado.is_equipe()));
create policy "equipe lê leads" on public.leads for select to authenticated using ((select privado.is_equipe()));
create policy "equipe atualiza leads" on public.leads for update to authenticated
  using ((select privado.is_equipe())) with check ((select privado.is_equipe()));
revoke all on public.equipe, public.cta_eventos, public.leads from anon;
grant select on public.equipe, public.cta_eventos, public.leads to authenticated;
grant update (status, mensagem) on public.leads to authenticated;

create or replace function public.registrar_evento(p jsonb) returns void language plpgsql security definer set search_path = ''
as $$
declare consent text := coalesce(p->>'consentimento','pendente');
begin
  insert into public.cta_eventos (cta, intencao, destino, secao, pagina, utm_source, utm_medium, utm_campaign,
    utm_term, utm_content, gclid, fbclid, referrer, dispositivo, tema, consentimento)
  values (p->>'cta', coalesce(p->>'intencao','geral'), coalesce(p->>'destino','whatsapp'),
    left(p->>'secao',40), left(p->>'pagina',200), left(p->>'utm_source',200), left(p->>'utm_medium',200),
    left(p->>'utm_campaign',200), left(p->>'utm_term',200), left(p->>'utm_content',200),
    case when consent = 'all' then left(p->>'gclid',200) end,
    case when consent = 'all' then left(p->>'fbclid',200) end,
    left(p->>'referrer',300), p->>'dispositivo', p->>'tema', consent);
end $$;

create or replace function public.registrar_lead(p jsonb) returns uuid language plpgsql security definer set search_path = ''
as $$
declare novo uuid;
begin
  if coalesce((p->>'consentimento_lgpd')::boolean, false) is not true then
    raise exception 'consentimento_lgpd obrigatório';
  end if;
  insert into public.leads (tipo, nome, empresa, cnpj, telefone, email, cidade, uf, equipamentos, mensagem, origem, consentimento_lgpd)
  values (p->>'tipo', trim(p->>'nome'), nullif(trim(p->>'empresa'),''), nullif(trim(p->>'cnpj'),''),
          nullif(trim(p->>'telefone'),''), nullif(lower(trim(p->>'email')),''), nullif(trim(p->>'cidade'),''),
          nullif(upper(trim(p->>'uf')),''), nullif(trim(p->>'equipamentos'),''), nullif(trim(p->>'mensagem'),''),
          coalesce(p->'origem','{}'::jsonb), true)
  returning id into novo;
  return novo;
end $$;
revoke all on function public.registrar_evento(jsonb), public.registrar_lead(jsonb) from public;
grant execute on function public.registrar_evento(jsonb), public.registrar_lead(jsonb) to anon, authenticated;
