-- Status "cancelado" pra compromissos do tipo "evento" — antes disso, o
-- botão "×" (agExcluir) apagava o registro de verdade (DELETE), sem deixar
-- rastro. Evento passou a precisar de um relatório histórico juntando
-- concluídos e cancelados (ver painel.html: agCancelarEvento e
-- openRelatorioEventos), então cancelar virou um soft-delete (marca este
-- campo em vez de apagar) só pra eventos — os outros tipos (reunião,
-- tarefa, compromisso, operação, outro) continuam sendo excluídos de
-- verdade pelo "×", comportamento intocado.
--
-- Sem mudança de RLS: a policy de update já existente em
-- agenda_compromissos.sql ("Master/gerencial edita compartilhado ou
-- proprio; consulta so o proprio") já cobre update de qualquer coluna,
-- incluindo esta.

alter table public.agenda_compromissos
  add column cancelado boolean not null default false;
