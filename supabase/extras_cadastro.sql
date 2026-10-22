-- Rode isto no SQL Editor do Supabase DEPOIS de revisar. Pode rodar mais de uma vez (idempotente) e
-- roda inteiro dentro de uma transação: se algo falhar, nada fica pela metade.
--
-- Cadastro de EXTRAS (pessoas que trabalham como extra com frequência). Tabela NOVA e independente:
-- não altera nenhuma tabela existente (nem "extras"). Ao incluir um extra numa praça/área de suporte
-- pelo cadastro, o app grava em "extras" uma CÓPIA de nome, função e valor (mesmo registro da digitação
-- manual) -- por isso mudar ou excluir alguém aqui NÃO altera dias já registrados nem os relatórios.
--
-- Acesso (RLS):
--   * SELECT  -> master e gerencial (nível Consulta não inclui extras, então não precisa ver o cadastro,
--                que guarda o valor combinado de cada pessoa).
--   * INSERT / UPDATE / DELETE -> só master (o dono do restaurante também passa, como em tem_nivel).
-- Depende da função public.tem_nivel(uuid, text[]), criada em supabase/login_funcionarios.sql.

begin;

create table if not exists public.extras_cadastro (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  nome text not null check (btrim(nome) <> ''),
  -- Nome normalizado (sem acento, minúsculo, espaços únicos), calculado pelo app. Garante pelo banco
  -- que não existam duas pessoas com o "mesmo" nome no mesmo restaurante ("José" = "jose" = " JOSÉ ").
  nome_chave text not null check (btrim(nome_chave) <> ''),
  -- Função: uma das opções da lista fixa do app (FUNCOES_EXTRA), validada na tela -- sem tabela de
  -- catálogo e sem CHECK de valores, pra lista poder crescer sem mexer no banco.
  funcao text not null check (btrim(funcao) <> ''),
  -- Valor combinado (diária, em R$).
  valor numeric(10,2) not null check (valor > 0),
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists extras_cadastro_restaurante_nome_chave_uk
  on public.extras_cadastro (restaurante_id, nome_chave);

alter table public.extras_cadastro enable row level security;

drop policy if exists "Master e gerencial veem o cadastro de extras" on public.extras_cadastro;
create policy "Master e gerencial veem o cadastro de extras"
  on public.extras_cadastro for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

drop policy if exists "Master cadastra extras no cadastro" on public.extras_cadastro;
create policy "Master cadastra extras no cadastro"
  on public.extras_cadastro for insert
  with check (public.tem_nivel(restaurante_id, array['master']));

drop policy if exists "Master atualiza o cadastro de extras" on public.extras_cadastro;
create policy "Master atualiza o cadastro de extras"
  on public.extras_cadastro for update
  using (public.tem_nivel(restaurante_id, array['master']))
  with check (public.tem_nivel(restaurante_id, array['master']));

drop policy if exists "Master remove do cadastro de extras" on public.extras_cadastro;
create policy "Master remove do cadastro de extras"
  on public.extras_cadastro for delete
  using (public.tem_nivel(restaurante_id, array['master']));

commit;
