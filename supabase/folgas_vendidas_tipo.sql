-- Adiciona o campo "tipo" a folgas_vendidas, para separar vendas de folga
-- feitas aos domingos/feriados das feitas em dias de semana (nova opção
-- liberada na seção "De folga hoje" dos dias de semana).
--
-- O default 'domingo' já classifica corretamente todo o histórico existente
-- (até hoje só era possível vender folga aos domingos/feriados), sem precisar
-- de nenhum backfill manual.

alter table public.folgas_vendidas
  add column if not exists tipo text not null default 'domingo' check (tipo in ('domingo','semana'));
