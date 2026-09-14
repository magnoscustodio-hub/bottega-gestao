-- Sub-função "Cumim" (auxiliar de garçom) dentro do cadastro de funcionário,
-- disponível em qualquer setor (Garçons ou áreas de suporte).
alter table funcionarios
  add column eh_cumim boolean not null default false;
