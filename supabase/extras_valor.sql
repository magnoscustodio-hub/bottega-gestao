-- Adiciona o valor (R$) de cada extra chamado, pra dar visibilidade de custo
-- ao gerente (nova aba "Extras" em Relatórios). Opcional — extras já
-- registrados continuam contando na quantidade, só ficam sem valor (null).

alter table public.extras
  add column if not exists valor numeric(10,2);
