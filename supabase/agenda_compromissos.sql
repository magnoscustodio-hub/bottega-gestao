-- Migra a Agenda do Gerente do localStorage (por navegador/dispositivo) para
-- uma tabela Supabase compartilhada por restaurante, com suporte a:
--   - visibilidade por item (compartilhado / pessoal)
--   - novo tipo de compromisso "evento" (com pax esperado + praça/locação)
--
-- Reaproveita a função public.tem_nivel(), já criada em login_funcionarios.sql.

create table public.agenda_compromissos (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  criado_por uuid not null references auth.users (id) on delete cascade,
  titulo text not null,
  descricao text,
  data date not null,
  hora text,
  tipo text not null check (tipo in ('reuniao','tarefa','compromisso','operacao','outro','evento')),
  prioridade text not null default 'normal' check (prioridade in ('normal','alta')),
  recorrencia text not null default 'nunca' check (recorrencia in ('nunca','semanal','quinzenal','mensal')),
  grupo_id uuid,
  concluido boolean not null default false,
  visibilidade text not null default 'compartilhado' check (visibilidade in ('compartilhado','pessoal')),
  pax_esperado int,
  praca_id uuid references public.pracas (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.agenda_compromissos enable row level security;

create policy "Quem tem acesso ve compartilhados; pessoal so o dono"
  on public.agenda_compromissos for select
  using (
    public.tem_nivel(restaurante_id, array['master','gerencial','consulta'])
    and (visibilidade = 'compartilhado' or criado_por = auth.uid())
  );

create policy "Quem tem acesso cria compromissos como si mesmo"
  on public.agenda_compromissos for insert
  with check (
    public.tem_nivel(restaurante_id, array['master','gerencial','consulta'])
    and criado_por = auth.uid()
  );

create policy "Master/gerencial edita compartilhado ou proprio; consulta so o proprio"
  on public.agenda_compromissos for update
  using (
    (
      public.tem_nivel(restaurante_id, array['master','gerencial'])
      and (visibilidade = 'compartilhado' or criado_por = auth.uid())
    )
    or (
      public.tem_nivel(restaurante_id, array['consulta'])
      and criado_por = auth.uid()
    )
  );

create policy "Master/gerencial remove compartilhado ou proprio; consulta so o proprio"
  on public.agenda_compromissos for delete
  using (
    (
      public.tem_nivel(restaurante_id, array['master','gerencial'])
      and (visibilidade = 'compartilhado' or criado_por = auth.uid())
    )
    or (
      public.tem_nivel(restaurante_id, array['consulta'])
      and criado_por = auth.uid()
    )
  );
