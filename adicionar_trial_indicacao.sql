-- Trial + programa de indicação. Rode isto no SQL Editor do Supabase.

-- 1) Novas colunas em restaurantes.
alter table public.restaurantes
  add column if not exists trial_fim timestamptz,
  add column if not exists indicado_por uuid references public.restaurantes (id) on delete set null,
  add column if not exists indicacao_confirmada boolean not null default false;

-- 2) Backfill: restaurantes já cadastrados antes desta feature ganham
--    30 dias de trial a partir de agora (não faz sentido calcular a partir
--    do created_at deles, senão apareceriam todos com trial "vencido há
--    meses" na área administrativa assim que a coluna existisse).
update public.restaurantes
  set trial_fim = now() + interval '30 days'
  where trial_fim is null;

-- 3) Trigger de proteção: nenhuma sessão autenticada normal (dono ou
--    funcionário logado) pode alterar trial_fim/indicado_por/
--    indicacao_confirmada via update comum — só a Edge Function
--    admin-dados (que usa a service_role key, sem JWT de usuário, então
--    auth.uid() vem nulo) tem esse poder. Sem isso, qualquer dono logado
--    conseguiria estender o próprio trial direto pelo console do navegador
--    (a policy de update de restaurantes não restringe por coluna).
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
  end if;
  return new;
end;
$$;

drop trigger if exists trg_proteger_campos_trial on public.restaurantes;
create trigger trg_proteger_campos_trial
  before update on public.restaurantes
  for each row execute function public.proteger_campos_trial();

-- 4) Resolver o slug de um link de indicação (?ref=slug) pro id de verdade
--    do restaurante. Precisa ser uma função (não um select direto do
--    cliente): a policy de leitura de restaurantes só deixa cada dono ver o
--    próprio restaurante, e quem está se cadastrando ainda não tem nenhum —
--    um select comum sempre voltaria vazio por causa do RLS, mesmo com o
--    slug certo. security definer roda como o dono da função (bypassa RLS
--    só pra essa consulta pontual) e só devolve o id — nada de endereço,
--    telefone ou qualquer outro dado sensível.
create or replace function public.resolver_indicante(p_slug text)
returns uuid
language sql
security definer
set search_path = public
as $$
  select id from public.restaurantes where slug = p_slug limit 1;
$$;

grant execute on function public.resolver_indicante(text) to anon, authenticated;
