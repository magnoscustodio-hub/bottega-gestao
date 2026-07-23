-- Bug: duplo clique/toque em "Registrar ausência" (ou "Editar ausência" ao
-- estender o período por cima de dias já registrados) podia criar 2+ linhas
-- para a mesma pessoa/data em public.ausencias, já que não havia nenhuma
-- trava (diferente de folgas_vendidas, que já tem unique(funcionario_id,data)).
--
-- Passo 1 — limpeza: remove duplicatas EXATAS existentes, mantendo 1 linha
-- por pessoa+data+motivo (não mexe em registros com motivos diferentes na
-- mesma data, caso existam).
delete from public.ausencias a
using public.ausencias b
where a.ctid < b.ctid
  and a.funcionario_id = b.funcionario_id
  and a.data = b.data
  and a.motivo is not distinct from b.motivo;

-- Passo 2 — trava definitiva: mesmo padrão já usado em folgas_vendidas.
alter table public.ausencias
  add constraint ausencias_funcionario_data_unique unique (funcionario_id, data);
