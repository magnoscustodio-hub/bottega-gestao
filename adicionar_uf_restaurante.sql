-- Campo UF (opcional) pra desambiguar a geocodificação do card de previsão
-- do tempo — sem ele, cidades homônimas em estados diferentes podem
-- resolver pro lugar errado. Rode isto no SQL Editor do Supabase.

alter table public.restaurantes
  add column if not exists uf text;
