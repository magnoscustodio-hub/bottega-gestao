-- Execute no SQL Editor do Supabase para criar a tabela usada pelo cadastro de restaurante.

create table if not exists public.restaurantes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  nome text not null,
  telefone text,
  endereco text,
  cidade text,
  logo_url text,
  created_at timestamptz not null default now()
);

alter table public.restaurantes enable row level security;

create policy "Donos podem ver seu restaurante"
  on public.restaurantes for select
  using (auth.uid() = owner_id);

create policy "Donos podem cadastrar seu restaurante"
  on public.restaurantes for insert
  with check (auth.uid() = owner_id);

create policy "Donos podem atualizar seu restaurante"
  on public.restaurantes for update
  using (auth.uid() = owner_id);

-- ============================================================
-- Funcionários (rodar apenas esta seção se a tabela restaurantes
-- acima já foi criada anteriormente)
-- ============================================================

create table if not exists public.funcionarios (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  nome text not null,
  cargo text,
  created_at timestamptz not null default now()
);

alter table public.funcionarios enable row level security;

create policy "Donos podem ver funcionarios do seu restaurante"
  on public.funcionarios for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = funcionarios.restaurante_id
        and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar funcionarios no seu restaurante"
  on public.funcionarios for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = funcionarios.restaurante_id
        and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar funcionarios do seu restaurante"
  on public.funcionarios for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = funcionarios.restaurante_id
        and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover funcionarios do seu restaurante"
  on public.funcionarios for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = funcionarios.restaurante_id
        and r.owner_id = auth.uid()
    )
  );

-- ============================================================
-- Painel completo (setores, praças, PAX, dias fechados, folgas,
-- ausências, extras, reservas, escala manual)
-- Rodar apenas esta seção se as tabelas acima já existirem.
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

create table if not exists public.horarios_especiais (
  id uuid primary key default gen_random_uuid(),
  funcionario_id uuid not null references public.funcionarios (id) on delete cascade,
  dias text[] not null,
  hora text not null,
  created_at timestamptz not null default now(),
  unique (funcionario_id)
);

alter table public.horarios_especiais enable row level security;

create policy "Donos podem ver horarios_especiais do seu restaurante"
  on public.horarios_especiais for select
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_especiais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar horarios_especiais do seu restaurante"
  on public.horarios_especiais for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_especiais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar horarios_especiais do seu restaurante"
  on public.horarios_especiais for update
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_especiais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover horarios_especiais do seu restaurante"
  on public.horarios_especiais for delete
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_especiais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create table if not exists public.horarios_pontuais (
  id uuid primary key default gen_random_uuid(),
  funcionario_id uuid not null references public.funcionarios (id) on delete cascade,
  data date not null,
  hora text not null,
  created_at timestamptz not null default now(),
  unique (funcionario_id, data)
);

alter table public.horarios_pontuais enable row level security;

create policy "Donos podem ver horarios_pontuais do seu restaurante"
  on public.horarios_pontuais for select
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_pontuais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem cadastrar horarios_pontuais do seu restaurante"
  on public.horarios_pontuais for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_pontuais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem atualizar horarios_pontuais do seu restaurante"
  on public.horarios_pontuais for update
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_pontuais.funcionario_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos podem remover horarios_pontuais do seu restaurante"
  on public.horarios_pontuais for delete
  using (
    exists (
      select 1 from public.funcionarios f
      join public.restaurantes r on r.id = f.restaurante_id
      where f.id = horarios_pontuais.funcionario_id and r.owner_id = auth.uid()
    )
  );

-- ============================================================
-- Login individual de funcionarios (PIN) + niveis de acesso
-- (master / gerencial / consulta). 100% aditivo às policies acima:
-- não altera nem remove nada, só soma novas regras em paralelo.
-- Rodar apenas esta seção se as tabelas acima já existirem.
-- Para instalações já em produção, use supabase/login_funcionarios.sql
-- (mesmo conteúdo, revisável antes de rodar).
-- ============================================================

create table if not exists public.perfis_acesso (
  id uuid primary key references auth.users (id) on delete cascade,
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  funcionario_id uuid unique references public.funcionarios (id) on delete set null,
  -- nome_exibicao/email_login só são usados por quem não tem funcionario_id
  -- (liderança/gerência sem vínculo com a escala, ex.: cargos que não entram
  -- na escala). Quem tem funcionario_id usa o nome de lá; quem não tem,
  -- usa nome_exibicao. email_login é o e-mail sintético usado no Supabase
  -- Auth para login por PIN — fica nulo pro Master, que usa e-mail/senha.
  nome_exibicao text,
  email_login text unique,
  nivel_acesso text not null check (nivel_acesso in ('master', 'gerencial', 'consulta')),
  metodo_login text not null default 'pin' check (metodo_login in ('pin', 'senha', 'magic_link')),
  created_at timestamptz not null default now()
);

alter table public.perfis_acesso enable row level security;

create policy "Cada um ve o proprio perfil de acesso"
  on public.perfis_acesso for select
  using (auth.uid() = id);

create policy "Donos veem perfis de acesso do seu restaurante"
  on public.perfis_acesso for select
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = perfis_acesso.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos cadastram perfis de acesso no seu restaurante"
  on public.perfis_acesso for insert
  with check (
    exists (
      select 1 from public.restaurantes r
      where r.id = perfis_acesso.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos atualizam perfis de acesso do seu restaurante"
  on public.perfis_acesso for update
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = perfis_acesso.restaurante_id and r.owner_id = auth.uid()
    )
  );

create policy "Donos removem perfis de acesso do seu restaurante"
  on public.perfis_acesso for delete
  using (
    exists (
      select 1 from public.restaurantes r
      where r.id = perfis_acesso.restaurante_id and r.owner_id = auth.uid()
    )
  );

create or replace function public.tem_nivel(p_restaurante_id uuid, p_niveis text[])
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfis_acesso pa
    where pa.id = auth.uid()
      and pa.restaurante_id = p_restaurante_id
      and pa.nivel_acesso = any(p_niveis)
  )
  or exists (
    select 1 from public.restaurantes r
    where r.id = p_restaurante_id and r.owner_id = auth.uid()
  );
$$;

create policy "Todos os niveis podem ver restaurantes"
  on public.restaurantes for select
  using (public.tem_nivel(id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver funcionarios"
  on public.funcionarios for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver setores"
  on public.setores for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver pracas"
  on public.pracas for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver pax_esperado"
  on public.pax_esperado for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver dias_fechados"
  on public.dias_fechados for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver extras"
  on public.extras for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver reservas"
  on public.reservas for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver escala_manual"
  on public.escala_manual for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Todos os niveis podem ver folgas"
  on public.folgas for select
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = folgas.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial','consulta'])
    )
  );

create policy "Todos os niveis podem ver folgas_vendidas"
  on public.folgas_vendidas for select
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = folgas_vendidas.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial','consulta'])
    )
  );

create policy "Todos os niveis podem ver ausencias"
  on public.ausencias for select
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = ausencias.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial','consulta'])
    )
  );

create policy "Todos os niveis podem ver horarios_especiais"
  on public.horarios_especiais for select
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_especiais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial','consulta'])
    )
  );

create policy "Todos os niveis podem ver horarios_pontuais"
  on public.horarios_pontuais for select
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_pontuais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial','consulta'])
    )
  );

create policy "Master e gerencial cadastram escala_manual"
  on public.escala_manual for insert
  with check (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial atualizam escala_manual"
  on public.escala_manual for update
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial removem escala_manual"
  on public.escala_manual for delete
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial cadastram extras"
  on public.extras for insert
  with check (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial removem extras"
  on public.extras for delete
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial cadastram reservas"
  on public.reservas for insert
  with check (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial atualizam reservas"
  on public.reservas for update
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial cadastram folgas"
  on public.folgas for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      where f.id = folgas.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial removem folgas"
  on public.folgas for delete
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = folgas.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial cadastram folgas_vendidas"
  on public.folgas_vendidas for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      where f.id = folgas_vendidas.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial removem folgas_vendidas"
  on public.folgas_vendidas for delete
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = folgas_vendidas.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial cadastram ausencias"
  on public.ausencias for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      where f.id = ausencias.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial atualizam ausencias"
  on public.ausencias for update
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = ausencias.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial removem ausencias"
  on public.ausencias for delete
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = ausencias.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial cadastram horarios_especiais"
  on public.horarios_especiais for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_especiais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial atualizam horarios_especiais"
  on public.horarios_especiais for update
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_especiais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial removem horarios_especiais"
  on public.horarios_especiais for delete
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_especiais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial cadastram horarios_pontuais"
  on public.horarios_pontuais for insert
  with check (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_pontuais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial atualizam horarios_pontuais"
  on public.horarios_pontuais for update
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_pontuais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create policy "Master e gerencial removem horarios_pontuais"
  on public.horarios_pontuais for delete
  using (
    exists (
      select 1 from public.funcionarios f
      where f.id = horarios_pontuais.funcionario_id
        and public.tem_nivel(f.restaurante_id, array['master','gerencial'])
    )
  );

create or replace view public.funcionarios_login_publico
with (security_invoker = false) as
select
  pa.id as perfil_id,
  coalesce(f.nome, pa.nome_exibicao) as nome,
  pa.email_login,
  pa.restaurante_id
from public.perfis_acesso pa
left join public.funcionarios f on f.id = pa.funcionario_id
where pa.email_login is not null; -- exclui o Master (usa e-mail/senha, não PIN)

grant select on public.funcionarios_login_publico to anon, authenticated;

-- ============================================================
-- Bucket de Storage "logos" — logo do restaurante (public/painel.html
-- usa restaurantes.logo_url, com fallback pro logo padrão se vazio).
-- Convenção de caminho: "<restaurante_id>/<nome do arquivo>".
-- ============================================================

insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;

create policy "Logos sao publicos para leitura"
  on storage.objects for select
  using (bucket_id = 'logos');

create policy "Donos podem enviar o logo do seu restaurante"
  on storage.objects for insert
  with check (
    bucket_id = 'logos'
    and exists (
      select 1 from public.restaurantes r
      where r.owner_id = auth.uid()
        and (storage.foldername(name))[1] = r.id::text
    )
  );

create policy "Donos podem atualizar o logo do seu restaurante"
  on storage.objects for update
  using (
    bucket_id = 'logos'
    and exists (
      select 1 from public.restaurantes r
      where r.owner_id = auth.uid()
        and (storage.foldername(name))[1] = r.id::text
    )
  );

create policy "Donos podem remover o logo do seu restaurante"
  on storage.objects for delete
  using (
    bucket_id = 'logos'
    and exists (
      select 1 from public.restaurantes r
      where r.owner_id = auth.uid()
        and (storage.foldername(name))[1] = r.id::text
    )
  );
