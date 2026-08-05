-- Separa a escala manual (praças/mesas + áreas de suporte) por turno.
--
-- Não é só o conserto de um bug pontual (evento fechado no Jantar do dia
-- 12/08 vazando pro Almoço) — é uma capacidade permanente do produto: cada
-- restaurante pode ter uma dinâmica diferente entre Almoço e Jantar (ex:
-- almoço rodízio, jantar à la carte), então a escala manual de um turno
-- nunca deve valer pro outro, em nenhum dia.
--
-- Hoje escala_manual guarda 1 registro por dia (unique(restaurante_id,data)),
-- sem distinguir Almoço/Jantar — os dois turnos liam e gravavam na mesma linha.
--
-- 1) Adiciona a coluna "turno" (mesmo domínio 'a'/'j' já usado em RES/reservas).
--    Default 'a' classifica corretamente todo o histórico existente.
alter table public.escala_manual
  add column if not exists turno text not null default 'a' check (turno in ('a','j'));

-- 2) Troca a constraint única de (restaurante_id,data) pra (restaurante_id,data,turno)
--    ANTES de duplicar os registros (passo 3) — se trocássemos depois, o INSERT
--    do passo 3 esbarraria na constraint antiga, que não sabe distinguir turno
--    e rejeitaria 2 linhas com o mesmo restaurante_id+data.
alter table public.escala_manual
  drop constraint if exists escala_manual_restaurante_id_data_key;
alter table public.escala_manual
  add constraint escala_manual_restaurante_id_data_turno_key unique (restaurante_id, data, turno);

-- 3) Duplica cada registro existente pro turno 'j', com a mesma distribuição —
--    preserva o comportamento de hoje (escala igual nos dois turnos) pra tudo
--    que já estava configurado, até o gerente editar um turno especificamente
--    e eles passarem a divergir. Sem isso, quem já tinha escala manual salva
--    perderia a configuração do Jantar assim que o app passasse a ler por turno.
insert into public.escala_manual (restaurante_id, data, turno, distribuicao, updated_at)
select restaurante_id, data, 'j', distribuicao, updated_at
from public.escala_manual
where turno = 'a'
on conflict (restaurante_id, data, turno) do nothing;
