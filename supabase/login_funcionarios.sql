-- Rode isto no SQL Editor do Supabase (projeto do Bottega Bernacca), DEPOIS de revisar.
-- Este script é 100% aditivo: não altera nem remove nenhuma tabela, coluna ou policy
-- que já existe. Só cria coisas novas (tabela perfis_acesso, função tem_nivel, view de
-- login, e novas policies em paralelo às atuais) e faz 1 insert idempotente (seguro
-- rodar de novo) pra registrar seu próprio acesso de Master.
--
-- Objetivo: login individual de funcionários por PIN, em 3 níveis de acesso
-- (master / gerencial / consulta), sem recadastrar ninguém e sem tocar no
-- acesso que o dono (custodios23@hotmail.com) já usa hoje.

-- ============================================================
-- 1) Tabela de vínculo login <-> funcionário/nível de acesso
-- ============================================================

create table if not exists public.perfis_acesso (
  id uuid primary key references auth.users (id) on delete cascade,
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  funcionario_id uuid unique references public.funcionarios (id) on delete set null,
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

-- ============================================================
-- 2) Função auxiliar usada pelas novas policies abaixo.
--    security definer: le perfis_acesso/restaurantes sem re-disparar a RLS
--    dessas tabelas (evita recursão), rodando com o privilegio de quem
--    criou a funcao (dono das tabelas no Supabase, que ignora RLS).
--    Sempre retorna true para o dono do restaurante, não importa o nivel pedido.
-- ============================================================

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

-- ============================================================
-- 3) Leitura para os 3 niveis (master/gerencial/consulta), aditiva,
--    em todas as tabelas operacionais do painel.
-- ============================================================

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

-- ============================================================
-- 4) Escrita (insert/update/delete) para master + gerencial, aditiva,
--    só nas tabelas de escala/faltas/horarios (o escopo do nivel Gerencial).
--    Cadastro de equipe/setores/pracas/pax/dias-fechados/restaurante
--    continua so-dono, de proposito (igual hoje).
--    Cada policy so cobre a operacao que ja existia antes pra dono
--    (ex.: "reservas" e "extras" ja nao tinham delete/update pra dono
--    hoje, entao tambem nao ganham aqui).
-- ============================================================

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

-- ============================================================
-- 5) View publica minima para a tela de login (funcionario) escolher
--    o nome numa lista. So aparece quem ja tem perfis_acesso (ou seja,
--    quem ja tem login criado pelo script de provisionamento) — nenhum
--    dado sensivel (nivel, PIN) fica exposto, so funcionario_id/nome.
-- ============================================================

create or replace view public.funcionarios_login_publico
with (security_invoker = false) as
select f.id as funcionario_id, f.nome, f.restaurante_id
from public.funcionarios f
join public.perfis_acesso pa on pa.funcionario_id = f.id;

grant select on public.funcionarios_login_publico to anon, authenticated;

-- ============================================================
-- 6) Migracao idempotente: registra SEU proprio acesso de Master.
--    Nao mexe em nenhum funcionario — nivel_acesso deles so existe
--    quando voce rodar o script de provisionamento pra cada um.
-- ============================================================

insert into public.perfis_acesso (id, restaurante_id, funcionario_id, nivel_acesso, metodo_login)
select u.id, r.id, null, 'master', 'senha'
from auth.users u
join public.restaurantes r on r.owner_id = u.id
where u.email = 'custodios23@hotmail.com'
on conflict (id) do update set nivel_acesso = 'master', metodo_login = 'senha';
