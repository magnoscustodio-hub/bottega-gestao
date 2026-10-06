-- Recurso "Manutenção": pedidos de manutenção (foto opcional + descrição) por
-- restaurante, com status Aberto/Concluído. Rode este arquivo INTEIRO de uma
-- vez no SQL Editor do Supabase, ANTES de publicar o código.
--
-- Reaproveita public.tem_nivel() (login_funcionarios.sql) -- mesmo critério de
-- permissão dos outros recursos:
--   * master / gerencial -> veem, criam, concluem/reabrem e excluem
--   * consulta           -> só veem (e compartilham por WhatsApp)

-- ============================================================
-- 1) Tabela
-- ============================================================

create table public.manutencoes (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references public.restaurantes (id) on delete cascade,
  criado_por uuid not null references auth.users (id) on delete cascade,
  descricao text not null,
  foto_path text,
  concluido boolean not null default false,
  concluido_em timestamptz,
  created_at timestamptz not null default now()
);

create index manutencoes_restaurante_idx
  on public.manutencoes (restaurante_id, concluido, created_at desc);

alter table public.manutencoes enable row level security;

create policy "Quem tem acesso ve os pedidos de manutencao"
  on public.manutencoes for select
  using (public.tem_nivel(restaurante_id, array['master','gerencial','consulta']));

create policy "Master/gerencial cria pedidos como si mesmo"
  on public.manutencoes for insert
  with check (
    public.tem_nivel(restaurante_id, array['master','gerencial'])
    and criado_por = auth.uid()
  );

create policy "Master/gerencial atualiza pedidos"
  on public.manutencoes for update
  using (public.tem_nivel(restaurante_id, array['master','gerencial']))
  with check (public.tem_nivel(restaurante_id, array['master','gerencial']));

create policy "Master/gerencial exclui pedidos"
  on public.manutencoes for delete
  using (public.tem_nivel(restaurante_id, array['master','gerencial']));

-- ============================================================
-- 2) Bucket PRIVADO "manutencoes" (fotos dos pedidos)
--
-- Convenção de caminho: "<restaurante_id>/<uuid>.jpg" -- a primeira pasta é o
-- restaurante, então a policy não depende do pedido já existir (o app envia a
-- foto ANTES de criar a linha, e só cria o pedido se o envio der certo).
-- A leitura no app é por URL assinada (1h na tela; 7 dias no link do WhatsApp).
-- ============================================================

insert into storage.buckets (id, name, public)
values ('manutencoes', 'manutencoes', false)
on conflict (id) do nothing;

create policy "Quem tem acesso ve as fotos de manutencao"
  on storage.objects for select
  using (
    bucket_id = 'manutencoes'
    and public.tem_nivel(((storage.foldername(name))[1])::uuid, array['master','gerencial','consulta'])
  );

create policy "Master/gerencial envia fotos de manutencao"
  on storage.objects for insert
  with check (
    bucket_id = 'manutencoes'
    and public.tem_nivel(((storage.foldername(name))[1])::uuid, array['master','gerencial'])
  );

create policy "Master/gerencial troca fotos de manutencao"
  on storage.objects for update
  using (
    bucket_id = 'manutencoes'
    and public.tem_nivel(((storage.foldername(name))[1])::uuid, array['master','gerencial'])
  );

create policy "Master/gerencial remove fotos de manutencao"
  on storage.objects for delete
  using (
    bucket_id = 'manutencoes'
    and public.tem_nivel(((storage.foldername(name))[1])::uuid, array['master','gerencial'])
  );
