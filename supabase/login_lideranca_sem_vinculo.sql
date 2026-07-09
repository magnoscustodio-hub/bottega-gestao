-- Rode isto no SQL Editor do Supabase DEPOIS de revisar.
-- Aditivo: só adiciona colunas novas (nulas, não quebra nenhuma linha existente)
-- e recria a view de login (drop + create, porque o nome da 1a coluna muda —
-- "create or replace view" não permite isso). Não mexe em nenhuma tabela,
-- policy ou dado já existente. Rode DEPOIS de supabase/login_funcionarios.sql.
--
-- Motivo: dar suporte a login de liderança/gerência que NÃO tem registro em
-- `funcionarios` (cargos que não entram na escala) — mesmo caso do seu próprio
-- acesso de Master, agora disponível também pros níveis gerencial/consulta.

alter table public.perfis_acesso
  add column if not exists nome_exibicao text,
  add column if not exists email_login text unique;

drop view if exists public.funcionarios_login_publico;

create view public.funcionarios_login_publico
with (security_invoker = false) as
select
  pa.id as perfil_id,
  coalesce(f.nome, pa.nome_exibicao) as nome,
  pa.email_login,
  pa.restaurante_id
from public.perfis_acesso pa
left join public.funcionarios f on f.id = pa.funcionario_id
where pa.email_login is not null; -- exclui o Master (usa e-mail/senha, não PIN)

grant select on public.funcionarios_login_publico to anon, authenticated;
