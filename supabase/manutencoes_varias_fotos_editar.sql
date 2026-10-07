-- Recurso "Manutenção": (1) VÁRIAS fotos por pedido (até 5) e (2) EDITAR pedido.
--
-- Rode este arquivo INTEIRO de uma vez no SQL Editor do Supabase, ANTES de
-- publicar o código. Roda numa transação: ou aplica tudo, ou nada. NÃO recria a
-- tabela nem o bucket (já existem em produção).
--
-- O que muda:
--   1) Coluna nova fotos_paths (text[]) em manutencoes, máximo 5 fotos (também
--      garantido no banco). A coluna antiga foto_path NÃO é removida: o app novo
--      grava as duas (foto_path = primeira foto), então uma aba aberta com o
--      código antigo continua mostrando a primeira foto e dá pra voltar atrás.
--   2) Migração dos pedidos existentes: foto_path -> fotos_paths. Uma TRAVA
--      confere se alguma foto ficou sem cópia; se sobrar uma, a migração aborta
--      e desfaz tudo (nenhuma foto é perdida).
--   3) Trigger de proteção: ninguém altera restaurante, autor ou data de criação
--      do pedido; quem NÃO é master/gerencial não consegue concluir/reabrir
--      (concluido / concluido_em), mesmo editando o próprio pedido (RLS não
--      restringe coluna, por isso o trigger). Sem usuário logado (SQL Editor,
--      chave de serviço) o trigger deixa passar, pra você poder corrigir dados.
--   4) UPDATE da tabela: master/gerencial qualquer pedido; consulta só o próprio
--      (criado_por = auth.uid()), com WITH CHECK impedindo trocar o autor.
--   5) DELETE do bucket: master/gerencial qualquer arquivo da pasta do
--      restaurante; consulta só os arquivos que ELA mesma enviou.
--
-- Fica como está: SELECT e INSERT (já liberados aos 3 níveis) e o DELETE da
-- TABELA (só master/gerencial: consulta continua sem excluir pedido).
--
-- Limitações conhecidas (não são bugs):
--   * A consulta pode editar QUALQUER campo do próprio pedido (descrição, fotos),
--     inclusive depois de um master concluí-lo; só não consegue concluir/reabrir.
--   * Foto removida que a consulta NÃO enviou (ex: um master adicionou na edição)
--     perde a referência no pedido, mas o arquivo fica solto no bucket (a consulta
--     não pode apagar arquivo de outra pessoa). Invisível no app e pequeno.
--   * Idem se o salvamento falhar logo após o upload de foto nova feito por quem
--     não tem permissão de apagar.
--   * Dois usuários editando o MESMO pedido ao mesmo tempo: o último a salvar vence.

begin;

-- ============================================================
-- 1) Coluna fotos_paths (máx. 5) -- foto_path continua existindo
-- ============================================================

alter table public.manutencoes
  add column if not exists fotos_paths text[] not null default '{}';

alter table public.manutencoes drop constraint if exists manutencoes_fotos_max;
alter table public.manutencoes
  add constraint manutencoes_fotos_max check (cardinality(fotos_paths) <= 5);

-- ============================================================
-- 2) Migração dos pedidos existentes + trava de segurança
-- ============================================================

update public.manutencoes
   set fotos_paths = array[foto_path]
 where foto_path is not null
   and cardinality(fotos_paths) = 0;

do $$
declare faltando int;
begin
  select count(*) into faltando
    from public.manutencoes
   where foto_path is not null
     and not (foto_path = any (fotos_paths));
  if faltando > 0 then
    raise exception 'Migração abortada: % pedido(s) com foto_path sem cópia em fotos_paths. Nada foi alterado.', faltando;
  end if;
end $$;

-- ============================================================
-- 3) Trigger de proteção do UPDATE
-- ============================================================

create or replace function public.manutencoes_guarda_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- Sem usuário logado (SQL Editor / chave de serviço): não interfere.
  if auth.uid() is null then
    return new;
  end if;

  if new.restaurante_id is distinct from old.restaurante_id
     or new.criado_por is distinct from old.criado_por
     or new.created_at is distinct from old.created_at then
    raise exception 'Não é permitido alterar o restaurante, o autor ou a data de criação do pedido.'
      using errcode = '42501';
  end if;

  if (new.concluido is distinct from old.concluido
      or new.concluido_em is distinct from old.concluido_em)
     and not public.tem_nivel(old.restaurante_id, array['master','gerencial']) then
    raise exception 'Sem permissão para concluir ou reabrir pedidos.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists manutencoes_guarda_update on public.manutencoes;
create trigger manutencoes_guarda_update
  before update on public.manutencoes
  for each row execute function public.manutencoes_guarda_update();

-- ============================================================
-- 4) UPDATE da tabela: master/gerencial qualquer; consulta só o próprio
-- ============================================================

-- (remove a policy antiga e também a nova, pra o arquivo poder ser rodado de novo sem erro)
drop policy if exists "Master/gerencial atualiza pedidos" on public.manutencoes;
drop policy if exists "Master/gerencial atualizam qualquer pedido; consulta so o proprio" on public.manutencoes;

create policy "Master/gerencial atualizam qualquer pedido; consulta so o proprio"
  on public.manutencoes for update
  using (
    public.tem_nivel(restaurante_id, array['master','gerencial'])
    or (public.tem_nivel(restaurante_id, array['consulta']) and criado_por = auth.uid())
  )
  with check (
    public.tem_nivel(restaurante_id, array['master','gerencial'])
    or (public.tem_nivel(restaurante_id, array['consulta']) and criado_por = auth.uid())
  );

-- ============================================================
-- 5) DELETE do bucket: master/gerencial qualquer arquivo do restaurante;
--    consulta só os que ela mesma enviou. O dono do arquivo é lido de "owner" e
--    "owner_id" via to_jsonb, porque o nome da coluna varia entre versões do
--    Supabase Storage (assim a policy não falha se uma delas não existir).
-- ============================================================

drop policy if exists "Master/gerencial remove fotos de manutencao" on storage.objects;
drop policy if exists "Master/gerencial removem fotos; consulta so as que enviou" on storage.objects;

create policy "Master/gerencial removem fotos; consulta so as que enviou"
  on storage.objects for delete
  using (
    bucket_id = 'manutencoes'
    and (
      public.tem_nivel(((storage.foldername(name))[1])::uuid, array['master','gerencial'])
      or (
        public.tem_nivel(((storage.foldername(name))[1])::uuid, array['consulta'])
        and (
          to_jsonb(objects) ->> 'owner_id' = auth.uid()::text
          or to_jsonb(objects) ->> 'owner' = auth.uid()::text
        )
      )
    )
  );

commit;
