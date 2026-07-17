-- Imagem do menu de um compromisso do tipo "evento" (upload feito pelo modal
-- aberto a partir do widget Agenda na Home, ao tocar num item de Evento).
--
-- Bucket PRIVADO (diferente do "logos", que é público): a imagem pertence a
-- um compromisso que pode estar marcado como "Pessoal" (visível só pra quem
-- criou), então a leitura da imagem precisa respeitar a mesma regra de
-- visibilidade da tabela agenda_compromissos — daí guardar só o caminho do
-- arquivo (menu_imagem_path) e gerar uma URL assinada (expira em 1h) no
-- app, em vez de uma URL pública fixa.

alter table public.agenda_compromissos
  add column menu_imagem_path text;

insert into storage.buckets (id, name, public)
values ('eventos-menu', 'eventos-menu', false)
on conflict (id) do nothing;

create policy "Quem ve o compromisso ve a imagem do menu"
  on storage.objects for select
  using (
    bucket_id = 'eventos-menu'
    and exists (
      select 1 from public.agenda_compromissos ac
      where ac.id::text = (storage.foldername(name))[1]
        and public.tem_nivel(ac.restaurante_id, array['master','gerencial','consulta'])
        and (ac.visibilidade = 'compartilhado' or ac.criado_por = auth.uid())
    )
  );

create policy "Quem pode editar o compromisso envia a imagem do menu"
  on storage.objects for insert
  with check (
    bucket_id = 'eventos-menu'
    and exists (
      select 1 from public.agenda_compromissos ac
      where ac.id::text = (storage.foldername(name))[1]
        and (
          (public.tem_nivel(ac.restaurante_id, array['master','gerencial']) and (ac.visibilidade = 'compartilhado' or ac.criado_por = auth.uid()))
          or (public.tem_nivel(ac.restaurante_id, array['consulta']) and ac.criado_por = auth.uid())
        )
    )
  );

create policy "Quem pode editar o compromisso troca a imagem do menu"
  on storage.objects for update
  using (
    bucket_id = 'eventos-menu'
    and exists (
      select 1 from public.agenda_compromissos ac
      where ac.id::text = (storage.foldername(name))[1]
        and (
          (public.tem_nivel(ac.restaurante_id, array['master','gerencial']) and (ac.visibilidade = 'compartilhado' or ac.criado_por = auth.uid()))
          or (public.tem_nivel(ac.restaurante_id, array['consulta']) and ac.criado_por = auth.uid())
        )
    )
  );

create policy "Quem pode editar o compromisso remove a imagem do menu"
  on storage.objects for delete
  using (
    bucket_id = 'eventos-menu'
    and exists (
      select 1 from public.agenda_compromissos ac
      where ac.id::text = (storage.foldername(name))[1]
        and (
          (public.tem_nivel(ac.restaurante_id, array['master','gerencial']) and (ac.visibilidade = 'compartilhado' or ac.criado_por = auth.uid()))
          or (public.tem_nivel(ac.restaurante_id, array['consulta']) and ac.criado_por = auth.uid())
        )
    )
  );
