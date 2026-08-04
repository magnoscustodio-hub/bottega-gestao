-- Rode isto no SQL Editor do Supabase DEPOIS de revisar.
-- Aditivo: só adiciona uma policy nova de SELECT, não muda nada existente.
--
-- Motivo: a nova tela "Acessos" (self-service, criar/resetar PIN/remover
-- acesso de Gerencial/Consulta) precisa que um usuário Gerencial consiga
-- LISTAR os acessos de nível Consulta do próprio restaurante — hoje só o
-- dono (via owner_id) consegue ler perfis_acesso. Gerencial continua sem
-- poder ver acessos Master ou de outros Gerenciais (a policy só libera
-- linhas com nivel_acesso = 'consulta').
--
-- Toda ESCRITA (criar/resetar PIN/remover) passa pela Edge Function
-- "gerenciar-acesso", que usa a service_role key (ignora RLS) e valida as
-- mesmas regras no servidor — por isso não é preciso nenhuma policy nova
-- de insert/update/delete aqui.

create policy "Gerencial ve acessos de nivel consulta do seu restaurante"
  on public.perfis_acesso for select
  using (
    public.tem_nivel(restaurante_id, array['gerencial'])
    and nivel_acesso = 'consulta'
  );
