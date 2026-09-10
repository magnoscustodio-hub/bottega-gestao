-- Horário de corte entre Almoço e Jantar, editável em Configurações > Dias
-- de funcionamento. Valor padrão 16 (16h) para restaurantes que nunca
-- configuraram.
alter table restaurantes
  add column horario_corte_turno smallint not null default 16;
