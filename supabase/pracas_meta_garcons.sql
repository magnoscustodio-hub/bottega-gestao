-- Meta de garçons por praça: peso relativo usado na distribuição automática
-- proporcional (Varanda 3 / Mesanino 2 = a Varanda recebe mais, na proporção
-- 3:2). Nulo = sem meta (a praça pesa 1; se nenhuma praça tiver meta, a
-- distribuição continua uniforme, exatamente como sempre foi).
alter table pracas
  add column meta_garcons integer;
