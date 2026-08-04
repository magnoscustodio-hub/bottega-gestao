// Edge Function: gerenciar-acesso
//
// Self-service de login individual (Master/Gerencial/Consulta), substituindo
// o script local scripts/criar-login-funcionario.mjs. Roda com a
// service_role key (só existe nas variáveis de ambiente da própria função,
// nunca chega ao navegador) — é ela quem tem poder de criar/trocar senha/
// apagar usuário no Supabase Auth (auth.admin.*), coisa que nenhuma chave
// pública consegue fazer.
//
// Ações suportadas (campo "action" no corpo da requisição):
//   - "criar":        { funcionario_id, nivel, pin }
//   - "resetar_pin":  { perfil_id, pin }
//   - "deletar":      { perfil_id }
//
// Regras de permissão (replicadas aqui, não só na tela — esta é a barreira
// que vale de verdade, já que só ela tem o poder de mexer no Auth):
//   - Master: cria Gerencial ou Consulta; reseta/remove qualquer acesso
//     (menos o próprio Master, que não é gerenciado por aqui).
//   - Gerencial: só cria Consulta; só reseta/remove acessos de nivel
//     Consulta — nunca Master nem outros Gerenciais.
//   - Consulta: sem acesso a nenhuma ação.
//   - Nunca é possível criar nivel "master" por aqui.
//
// O restaurante do chamador NUNCA é aceito como parâmetro do cliente — é
// sempre derivado da própria identidade dele (dono via restaurantes.owner_id,
// ou a própria linha em perfis_acesso), a mesma dualidade que a função SQL
// tem_nivel() já usa. Isso impede um Gerencial de tentar mexer no acesso de
// outro restaurante passando um id diferente.
//
// Respostas sempre voltam com HTTP 200 (sucesso ou erro de regra de negócio
// tratado) — o corpo ({ok:true,...} ou {error:"..."}) é quem diz o que
// aconteceu. Isso evita o cliente ter que lidar com o parsing de erro HTTP
// do supabase-js; só uma falha realmente inesperada (exceção não tratada)
// cai no catch geral com status 500.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}
const erro = (msg: string) => jsonResponse({ error: msg })

const PIN_REGEX = /^\d{6}$/

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return erro('Não autenticado.')
    const token = authHeader.replace(/^Bearer\s+/i, '')

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const { data: userData, error: userError } = await admin.auth.getUser(token)
    if (userError || !userData.user) return erro('Sessão inválida.')
    const chamadorId = userData.user.id

    // Descobre o nível efetivo do chamador: dono do restaurante (master
    // implícito, sem linha em perfis_acesso — é assim pra todo restaurante
    // criado pelo onboarding) OU a própria linha em perfis_acesso.
    const { data: restauranteDono } = await admin
      .from('restaurantes')
      .select('id')
      .eq('owner_id', chamadorId)
      .maybeSingle()

    let nivelChamador: string
    let restauranteId: string
    if (restauranteDono) {
      nivelChamador = 'master'
      restauranteId = restauranteDono.id
    } else {
      const { data: perfilChamador } = await admin
        .from('perfis_acesso')
        .select('nivel_acesso, restaurante_id')
        .eq('id', chamadorId)
        .maybeSingle()
      if (!perfilChamador) return erro('Perfil de acesso não encontrado.')
      nivelChamador = perfilChamador.nivel_acesso
      restauranteId = perfilChamador.restaurante_id
    }

    if (nivelChamador === 'consulta') {
      return erro('Você não tem permissão para gerenciar acessos.')
    }

    const body = await req.json().catch(() => ({}))
    const { action } = body

    if (action === 'criar') {
      const { funcionario_id, nivel, pin } = body
      if (!funcionario_id || !nivel || !pin) return erro('Informe funcionário, nível e PIN.')
      if (!PIN_REGEX.test(pin)) return erro('O PIN precisa ter exatamente 6 dígitos.')
      if (nivel !== 'gerencial' && nivel !== 'consulta') return erro('Nível inválido. Use "gerencial" ou "consulta".')
      if (nivelChamador === 'gerencial' && nivel !== 'consulta') {
        return erro('Gerencial só pode criar acessos de nível Consulta.')
      }

      const { data: funcionario } = await admin
        .from('funcionarios')
        .select('id, restaurante_id')
        .eq('id', funcionario_id)
        .maybeSingle()
      if (!funcionario || funcionario.restaurante_id !== restauranteId) {
        return erro('Funcionário não encontrado nesse restaurante.')
      }

      const { data: existente } = await admin
        .from('perfis_acesso')
        .select('id')
        .eq('funcionario_id', funcionario_id)
        .maybeSingle()
      if (existente) return erro('Esse funcionário já tem acesso.')

      const emailLogin = `f-${funcionario_id}@login.gestaosalao.internal`
      const { data: novoUsuario, error: criarError } = await admin.auth.admin.createUser({
        email: emailLogin,
        password: pin,
        email_confirm: true,
      })
      if (criarError || !novoUsuario?.user) {
        return erro('Não foi possível criar o login: ' + (criarError?.message || ''))
      }

      const { error: perfilError } = await admin.from('perfis_acesso').insert({
        id: novoUsuario.user.id,
        restaurante_id: restauranteId,
        funcionario_id,
        nivel_acesso: nivel,
        metodo_login: 'pin',
      })
      if (perfilError) {
        // desfaz o usuário recém-criado no Auth pra não ficar orfão
        await admin.auth.admin.deleteUser(novoUsuario.user.id)
        return erro('Não foi possível salvar o vínculo: ' + perfilError.message)
      }

      return jsonResponse({ ok: true, id: novoUsuario.user.id })
    }

    if (action === 'resetar_pin' || action === 'deletar') {
      const { perfil_id, pin } = body
      if (!perfil_id) return erro('Informe o acesso.')

      const { data: alvo } = await admin
        .from('perfis_acesso')
        .select('id, restaurante_id, nivel_acesso')
        .eq('id', perfil_id)
        .maybeSingle()
      if (!alvo || alvo.restaurante_id !== restauranteId) return erro('Acesso não encontrado nesse restaurante.')
      if (alvo.nivel_acesso === 'master') return erro('Não é possível mexer no acesso Master por aqui.')
      if (nivelChamador === 'gerencial' && alvo.nivel_acesso !== 'consulta') {
        return erro('Você não tem permissão para mexer nesse acesso.')
      }

      if (action === 'resetar_pin') {
        if (!pin || !PIN_REGEX.test(pin)) return erro('O PIN precisa ter exatamente 6 dígitos.')
        const { error: updError } = await admin.auth.admin.updateUserById(perfil_id, { password: pin })
        if (updError) return erro('Não foi possível trocar o PIN: ' + updError.message)
        return jsonResponse({ ok: true })
      }

      // deletar: apaga o usuário do Auth — perfis_acesso cai junto via
      // "on delete cascade" (referência a auth.users).
      const { error: delError } = await admin.auth.admin.deleteUser(perfil_id)
      if (delError) return erro('Não foi possível remover o acesso: ' + delError.message)
      return jsonResponse({ ok: true })
    }

    return erro('Ação inválida.')
  } catch (err) {
    return jsonResponse({ error: (err as Error).message || 'Erro inesperado.' }, 500)
  }
})
