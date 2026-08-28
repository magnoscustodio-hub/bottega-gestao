-- Créditos de indicação pra restaurantes pagantes (alternativa aos 30 dias
-- de trial, pra quando quem indicou já não está mais em trial). Rode isto
-- no SQL Editor do Supabase.

-- 1) Nova coluna.
alter table public.restaurantes
  add column if not exists creditos_indicacao integer not null default 0;

-- 2) Recria o trigger de proteção pra também cobrir creditos_indicacao —
--    mesma brecha que motivou o trigger original: sem isso, qualquer dono
--    logado poderia se autoconceder créditos direto pelo console do
--    navegador (a policy de update de restaurantes não restringe por coluna).
create or replace function public.proteger_campos_trial()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null then
    new.trial_fim := old.trial_fim;
    new.indicado_por := old.indicado_por;
    new.indicacao_confirmada := old.indicacao_confirmada;
    new.creditos_indicacao := old.creditos_indicacao;
  end if;
  return new;
end;
$$;
