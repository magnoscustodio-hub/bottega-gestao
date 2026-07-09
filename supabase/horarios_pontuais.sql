-- Rode isto no SQL Editor do Supabase (projeto do Bottega Bernacca).
-- Cria a tabela de horarios especiais PONTUAIS: um ajuste de entrada
-- valido so para uma data especifica. No dia seguinte volta ao normal
-- automaticamente, pois a linha so e aplicada quando a data bate.

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
