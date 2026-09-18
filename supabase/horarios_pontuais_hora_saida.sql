-- Horário de SAÍDA (opcional) no Horário pontual, além da entrada (hora) que
-- já existia. Nulo = só entrada, exatamente como sempre funcionou.
alter table horarios_pontuais
  add column hora_saida text;
