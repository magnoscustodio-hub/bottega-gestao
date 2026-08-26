-- Campo "Data de saída" em funcionários — espelho do "data_inicio" já existente.
-- Rode isto no SQL Editor do Supabase.

alter table funcionarios
  add column if not exists data_saida date;
