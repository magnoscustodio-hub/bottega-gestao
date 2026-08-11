-- Data de início (opcional) do funcionário. Em branco = disponível pra
-- alocação em praça/suporte desde sempre (comportamento de hoje, intocado
-- pra todo mundo já cadastrado). Preenchida = só aparece como disponível
-- a partir dessa data (inclusive) em qualquer lugar que hoje já filtra por
-- folga/ausência/férias.

alter table public.funcionarios
  add column if not exists data_inicio date;
