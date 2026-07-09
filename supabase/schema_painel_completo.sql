-- ============================================================
-- Painel completo (setores, praças, PAX, dias fechados, folgas,
-- ausências, extras, reservas, escala manual)
-- Rodar apenas esta seção se as tabelas "restaurantes" e
-- "funcionarios" (de schema.sql) já existirem.
-- Substitui a antiga tabela "escalas" (dia_semana/horário genérico),
-- que não corresponde ao modelo real do painel.
-- ============================================================

drop table if exists public.escalas cascade;

-- Se a tabela restaurantes já existia sem a coluna cidade (criada antes desta
-- atualização do schema), esta linha adiciona a coluna sem apagar dados.
alter table public.restaurantes add column if not exists cidade text;

create table if not exists public.setores (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  chave text not null,
  nome text not null,
  emoji text,
  cor text,
  min_funcionarios int not null default 1,
  ordem int not null default 0,
  created_at timestamptz not null default now(),
  unique (restaurante_id, chave)
);

alter table public.setores enable row level security;

create policy "Donos podem ver setores do seu restaurante"
  on public.setores for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = setores.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar setores no seu restaurante"
  on public.setores for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = setores.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar setores do seu restaurante"
  on public.setores for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = setores.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover setores do seu restaurante"
  on public.setores for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = setores.restaurante_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.pracas (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  nome text not null,
  mesas int not null default 0,
  lugares int not null default 0,
  fim_semana boolean not null default false,
  ordem int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.pracas enable row level security;

create policy "Donos podem ver pracas do seu restaurante"
  on public.pracas for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = pracas.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar pracas no seu restaurante"
  on public.pracas for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = pracas.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar pracas do seu restaurante"
  on public.pracas for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = pracas.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover pracas do seu restaurante"
  on public.pracas for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = pracas.restaurante_id and r.owner_id = auth.uid()
    )
  );

-- Colunas novas em funcionarios: setor do funcionário e praça preferencial
-- (praça preferencial fica nula para restaurantes cadastrados pelo onboarding;
-- só é usada pelo script de migração do Bottega Bernacca).
alter table public.funcionarios
  add column if not exists setor_id uuid references public.setores (id) on delete set null,
  add column if not exists praca_preferencial_id uuid references public.pracas (id) on delete set null;

create table if not exists public.pax_esperado (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  dia_semana text not null,
  turno text not null check (turno in ('almoco', 'jantar')),
  quantidade int not null default 0,
  unique (restaurante_id, dia_semana, turno)
);

alter table public.pax_esperado enable row level security;

create policy "Donos podem ver pax_esperado do seu restaurante"
  on public.pax_esperado for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = pax_esperado.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar pax_esperado no seu restaurante"
  on public.pax_esperado for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = pax_esperado.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar pax_esperado do seu restaurante"
  on public.pax_esperado for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = pax_esperado.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover pax_esperado do seu restaurante"
  on public.pax_esperado for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = pax_esperado.restaurante_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.dias_fechados (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  dia_semana text not null,
  turno text not null
);

alter table public.dias_fechados enable row level security;

create policy "Donos podem ver dias_fechados do seu restaurante"
  on public.dias_fechados for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = dias_fechados.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar dias_fechados no seu restaurante"
  on public.dias_fechados for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = dias_fechados.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar dias_fechados do seu restaurante"
  on public.dias_fechados for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = dias_fechados.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover dias_fechados do seu restaurante"
  on public.dias_fechados for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = dias_fechados.restaurante_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.folgas (
  id uuid primary key default gen_random_uuid(),
  funcionario_id uuid not null references public.funcionarios (id) on delete cascade,
  data date not null,
  created_at timestamptz not null default now(),
  unique (funcionario_id, data)
);

alter table public.folgas enable row level security;

create policy "Donos podem ver folgas do seu restaurante"
  on public.folgas for select
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = folgas.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar folgas do seu restaurante"
  on public.folgas for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = folgas.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover folgas do seu restaurante"
  on public.folgas for delete
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = folgas.funcionario_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.folgas_vendidas (
  id uuid primary key default gen_random_uuid(),
  funcionario_id uuid not null references public.funcionarios (id) on delete cascade,
  data date not null,
  created_at timestamptz not null default now(),
  unique (funcionario_id, data)
);

alter table public.folgas_vendidas enable row level security;

create policy "Donos podem ver folgas_vendidas do seu restaurante"
  on public.folgas_vendidas for select
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = folgas_vendidas.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar folgas_vendidas do seu restaurante"
  on public.folgas_vendidas for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = folgas_vendidas.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover folgas_vendidas do seu restaurante"
  on public.folgas_vendidas for delete
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = folgas_vendidas.funcionario_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.ausencias (
  id uuid primary key default gen_random_uuid(),
  funcionario_id uuid not null references public.funcionarios (id) on delete cascade,
  data date not null,
  motivo text,
  created_at timestamptz not null default now()
);

alter table public.ausencias enable row level security;

create policy "Donos podem ver ausencias do seu restaurante"
  on public.ausencias for select
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = ausencias.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar ausencias do seu restaurante"
  on public.ausencias for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = ausencias.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar ausencias do seu restaurante"
  on public.ausencias for update
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = ausencias.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover ausencias do seu restaurante"
  on public.ausencias for delete
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = ausencias.funcionario_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.extras (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  alvo text not null,
  data date not null,
  nome text not null,
  created_at timestamptz not null default now()
);

alter table public.extras enable row level security;

create policy "Donos podem ver extras do seu restaurante"
  on public.extras for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = extras.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar extras no seu restaurante"
  on public.extras for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = extras.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover extras do seu restaurante"
  on public.extras for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = extras.restaurante_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.reservas (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  data date not null,
  turno text not null,
  quantidade int not null default 0,
  unique (restaurante_id, data, turno)
);

alter table public.reservas enable row level security;

create policy "Donos podem ver reservas do seu restaurante"
  on public.reservas for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = reservas.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar reservas no seu restaurante"
  on public.reservas for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = reservas.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar reservas do seu restaurante"
  on public.reservas for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = reservas.restaurante_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.escala_manual (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  data date not null,
  distribuicao jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (restaurante_id, data)
);

alter table public.escala_manual enable row level security;

create policy "Donos podem ver escala_manual do seu restaurante"
  on public.escala_manual for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = escala_manual.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar escala_manual no seu restaurante"
  on public.escala_manual for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = escala_manual.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar escala_manual do seu restaurante"
  on public.escala_manual for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = escala_manual.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover escala_manual do seu restaurante"
  on public.escala_manual for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = escala_manual.restaurante_id and r.owner_id = auth.uid()
    )
  );
