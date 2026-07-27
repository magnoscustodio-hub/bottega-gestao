-- Permite que compromissos do tipo "tarefa" funcionem como lembrete
-- permanente (sem data) — aparecem em todos os filtros da Agenda (Todos,
-- Hoje, Próximos 7 dias, Pendentes) todo dia, até serem marcados como
-- concluídos. Os demais tipos (reunião, compromisso, operação, evento,
-- outro) continuam exigindo data, como hoje.

alter table public.agenda_compromissos alter column data drop not null;

alter table public.agenda_compromissos
  add constraint agenda_compromissos_data_obrigatoria_exceto_tarefa
  check (tipo = 'tarefa' or data is not null);
