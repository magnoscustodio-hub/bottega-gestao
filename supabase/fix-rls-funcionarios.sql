-- 1) Ver o que está ativo hoje (antes de corrigir)
select policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'funcionarios';

-- 2) Remover as políticas antigas de funcionarios (se existirem)
drop policy if exists "Donos podem ver funcionarios do seu restaurante" on public.funcionarios;
drop policy if exists "Donos podem cadastrar funcionarios no seu restaurante" on public.funcionarios;
drop policy if exists "Donos podem atualizar funcionarios do seu restaurante" on public.funcionarios;
drop policy if exists "Donos podem remover funcionarios do seu restaurante" on public.funcionarios;

-- 3) Garantir que RLS está ligado
alter table public.funcionarios enable row level security;

-- 4) Recriar as políticas corretas
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

-- 5) Conferir o resultado final (deve mostrar as 4 políticas novas)
select policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'funcionarios';

-- 6) Limpar o restaurante parcial criado na tentativa anterior
delete from public.restaurantes where nome = 'Bottega Bernacca';
