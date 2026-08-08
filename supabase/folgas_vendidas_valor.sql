-- Adiciona o valor (R$) de cada venda de folga (domingo ou dia de semana),
-- mesmo padrão já usado em extras.valor. Opcional — vendas já registradas
-- continuam contando na quantidade, só ficam sem valor (null).

alter table public.folgas_vendidas
  add column if not exists valor numeric(10,2);
