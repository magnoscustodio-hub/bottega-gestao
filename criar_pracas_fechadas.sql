-- Fechamento manual de praça por dia+turno — mesmo padrão de escala_manual.
-- Rode isto no SQL Editor do Supabase.

create table if not exists public.pracas_fechadas (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  data date not null,
  turno text not null default 'a' check (turno in ('a','j')),
  pracas jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  unique (restaurante_id, data, turno)
);

alter table public.pracas_fechadas enable row level security;

create policy "Todos os niveis podem ver pracas_fechadas"
  on public.pracas_fechadas for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Master e gerencial cadastram pracas_fechadas"
  on public.pracas_fechadas for insert
  with check (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial atualizam pracas_fechadas"
  on public.pracas_fechadas for update
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master e gerencial removem pracas_fechadas"
  on public.pracas_fechadas for delete
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));
