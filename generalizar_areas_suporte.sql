-- Generaliza "Esterilização" (sempre extra + só fim de semana) como opção
-- configurável em qualquer área de suporte, e renomeia pracas_fechadas pra
-- cobrir também setores de suporte. Rode isto no SQL Editor do Supabase.

-- 1) Setores ganham os mesmos 2 flags que Praças já tinham (fim_semana) +
--    um novo (sempre_extra) — ambos editáveis em Configurações.
alter table public.setores
  add column if not exists sempre_extra boolean not null default false,
  add column if not exists fim_semana boolean not null default false;

-- 2) Renomeia pracas_fechadas -> areas_fechadas (e a coluna pracas -> areas):
--    a partir de agora essa tabela guarda id de praça OU de setor fechado
--    manualmente pro dia+turno — RLS/índices/constraint continuam intactos
--    (rename preserva tudo, só muda o nome).
alter table public.pracas_fechadas rename to areas_fechadas;
alter table public.areas_fechadas rename column pracas to areas;

-- 3) Esterilização volta pro Bottega (único restaurante já existente antes
--    dessa generalização — novos cadastros já ganham automaticamente pelo
--    onboarding). chave='esteril' de propósito: é o mesmo valor já usado
--    no histórico de extras salvos antes dessa correção, então os dados
--    antigos (Relatório de Extras etc.) continuam batendo sem precisar
--    migrar nada. Ajuste o nome do restaurante abaixo se necessário.
insert into public.setores (restaurante_id, chave, nome, emoji, cor, min_funcionarios, sempre_extra, fim_semana, ordem)
select r.id, 'esteril', 'Esterilização', '🧴', '#2A7A6A', 1, true, true,
  coalesce((select max(ordem)+1 from public.setores where restaurante_id = r.id), 0)
from public.restaurantes r
where r.nome = 'Bottega Bernacca'
on conflict (restaurante_id, chave) do nothing;
