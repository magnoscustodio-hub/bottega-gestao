-- Adiciona a função exercida naquele extra específico (Garçom, Barman,
-- Maitre, etc.) — mesmo padrão de extras.valor: opcional, varia por
-- registro (a mesma pessoa pode exercer funções diferentes em dias
-- diferentes), não é um atributo fixo da pessoa. Lista fixa de opções
-- resolvida só na UI (igual ausencias.motivo), sem tabela de catálogo.

alter table public.extras
  add column if not exists funcao text;
