-- Rode isto no SQL Editor do Supabase DEPOIS de revisar.
-- Aditivo: só adiciona uma coluna nova (nula, não quebra nada existente) e cria
-- um bucket de Storage novo (armazenamento de arquivo) pro logo de cada
-- restaurante, com policies restringindo quem pode enviar/trocar/remover.
--
-- Convenção de caminho dos arquivos no bucket: "<restaurante_id>/<nome do arquivo>"
-- — é assim que a policy sabe de quem é cada logo.

-- ============================================================
-- 1) Coluna nova em restaurantes
-- ============================================================

alter table public.restaurantes add column if not exists logo_url text;

-- ============================================================
-- 2) Bucket de Storage "logos" — leitura publica (é só uma imagem
--    de logo, sem dado sensível), envio/troca/remoção só pro dono
--    do restaurante correspondente à pasta do arquivo.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;

create policy "Logos sao publicos para leitura"
  on storage.objects for select
  using (bucket_id = 'logos');

create policy "Donos podem enviar o logo do seu restaurante"
  on storage.objects for insert
  with check (
    bucket_id = 'logos'
    and exists (
      select 1 from public.restaurantes r
      where r.owner_id = auth.uid()
        and (storage.foldername(name))[1] = r.id::text
    )
  );

create policy "Donos podem atualizar o logo do seu restaurante"
  on storage.objects for update
  using (
    bucket_id = 'logos'
    and exists (
      select 1 from public.restaurantes r
      where r.owner_id = auth.uid()
        and (storage.foldername(name))[1] = r.id::text
    )
  );

create policy "Donos podem remover o logo do seu restaurante"
  on storage.objects for delete
  using (
    bucket_id = 'logos'
    and exists (
      select 1 from public.restaurantes r
      where r.owner_id = auth.uid()
        and (storage.foldername(name))[1] = r.id::text
    )
  );
