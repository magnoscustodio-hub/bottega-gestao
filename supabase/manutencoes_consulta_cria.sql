-- Ajuste de permissões do recurso "Manutenção": o nível CONSULTA passa a poder
-- CRIAR pedidos (com foto), além de ver a lista e compartilhar por WhatsApp.
--
-- Rode este arquivo INTEIRO de uma vez no SQL Editor do Supabase. Só troca 2
-- policies de INSERT -- NÃO recria a tabela nem o bucket (já existem em
-- produção, criados por supabase/manutencoes.sql). Tudo roda numa transação:
-- ou troca as duas, ou não troca nenhuma.
--
-- Fica como está (não mexe):
--   * SELECT da tabela e do bucket: master / gerencial / consulta
--   * UPDATE e DELETE da tabela e do bucket: só master / gerencial
--     (consulta continua SEM concluir, reabrir ou excluir)
--
-- Observação: se o INSERT do pedido falhar logo depois do upload da foto, quem
-- é consulta não consegue apagar a foto recém-enviada (DELETE do bucket segue
-- restrito a master/gerencial, como pedido) e ela fica como arquivo solto, sem
-- pedido associado. É raro e inofensivo (arquivo pequeno, invisível no app).

begin;

-- 1) Tabela: INSERT liberado pros três níveis, sempre escopado ao restaurante
--    do usuário (tem_nivel confere o vínculo com restaurante_id) e criado
--    como o próprio usuário (criado_por = auth.uid()).
drop policy if exists "Master/gerencial cria pedidos como si mesmo" on public.manutencoes;

create policy "Quem tem acesso cria pedidos como si mesmo"
  on public.manutencoes for insert
  with check (
    public.tem_nivel(restaurante_id, array['master','gerencial','consulta'])
    and criado_por = auth.uid()
  );

-- 2) Bucket "manutencoes": upload (INSERT) liberado pros três níveis, só na
--    pasta do próprio restaurante (primeira pasta do caminho = restaurante_id).
drop policy if exists "Master/gerencial envia fotos de manutencao" on storage.objects;

create policy "Quem tem acesso envia fotos de manutencao"
  on storage.objects for insert
  with check (
    bucket_id = 'manutencoes'
    and public.tem_nivel(((storage.foldername(name))[1])::uuid, array['master','gerencial','consulta'])
  );

commit;
