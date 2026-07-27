-- Configuração de mesas totalmente livre: cada praça passa a guardar uma
-- lista de linhas "quantidade de mesas + lugares por mesa" (ex: 5 mesas de
-- 2 lugares, 8 mesas de 4 lugares...), em vez de só dois números soltos.
--
-- As colunas "mesas" e "lugares" continuam existindo (todo o resto do
-- sistema - ocupação, distribuição de garçom por praça, capacidade total -
-- continua lendo elas normalmente) — passam apenas a ser calculadas
-- automaticamente a partir da soma das linhas, em vez de digitadas.

alter table public.pracas add column if not exists mesas_config jsonb not null default '[]'::jsonb;
