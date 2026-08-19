-- Slug público e único por restaurante, usado pra escopar a tela de login
-- da equipe (/login/:slug) por restaurante.
--
-- Antes desta mudança não existia NENHUMA forma da tela de login saber
-- qual restaurante estava sendo acessado: era uma única rota /login
-- compartilhada por todo mundo, e o dropdown "Quem é você?" (aba "Sou da
-- equipe") trazia os funcionários de TODOS os restaurantes cadastrados no
-- sistema misturados na mesma lista — funcionarios_login_publico já tinha
-- a coluna restaurante_id disponível, mas a consulta em Login.jsx nunca
-- filtrava por ela.

alter table public.restaurantes
  add column if not exists slug text unique;

-- View pública mínima (nome, logo, slug) pra resolver slug -> restaurante
-- na tela de login, antes do funcionário se autenticar. Só devolve o
-- restaurante cujo slug for pedido (busca por igualdade) — nunca expõe a
-- lista completa de clientes cadastrados, diferente de listar tudo.
create or replace view public.restaurante_login_publico
with (security_invoker = false) as
select id, nome, logo_url, slug
from public.restaurantes
where slug is not null;

grant select on public.restaurante_login_publico to anon, authenticated;
