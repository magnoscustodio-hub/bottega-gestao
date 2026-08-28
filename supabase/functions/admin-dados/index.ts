// Edge Function: admin-dados
//
// Serve a área administrativa (public/admin.html) — a única tela do sistema
// que enxerga TODOS os restaurantes de uma vez, não só o do dono logado.
// Não usa Supabase Auth: a "autenticação" é um segredo próprio (header
// x-admin-secret, comparado contra a env var ADMIN_SECRET desta função),
// já que admin.html é acessada por link direto, sem sessão nenhuma.
//
// Roda sempre com a service_role key — é o único jeito de ler/gravar em
// restaurantes.trial_fim / indicado_por / indicacao_confirmada, já que o
// trigger trg_proteger_campos_trial (ver adicionar_trial_indicacao.sql)
// bloqueia essas 3 colunas pra qualquer sessão autenticada normal
// (auth.uid() não nulo) — só a service_role (auth.uid() nulo) passa.
//
// Ações suportadas (campo "action" no corpo da requisição):
//   - "listar":               {} -> lista completa + contagem + indicações pendentes
//   - "confirmar_indicacao":  { restaurante_id, tipo }
//       tipo="trial":   +30 dias no trial_fim do indicante (quem ainda está em trial)
//       tipo="credito": +1 em creditos_indicacao do indicante (quem já é pagante)
//       Sem default de propósito — o admin escolhe manualmente qual dar a
//       cada confirmação, dependendo da situação de quem indicou.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ADMIN_SECRET = Deno.env.get('ADMIN_SECRET')!

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-secret',
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}
const erro = (msg: string, status = 200) => jsonResponse({ error: msg }, status)

const DIA_MS = 24 * 60 * 60 * 1000
function diasRestantes(trialFim: string | null): number | null {
  if (!trialFim) return null
  return Math.ceil((new Date(trialFim).getTime() - Date.now()) / DIA_MS)
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS })

  try {
    if (!ADMIN_SECRET) return erro('ADMIN_SECRET não configurado na função.', 500)
    const secretRecebido = req.headers.get('x-admin-secret')
    if (!secretRecebido || secretRecebido !== ADMIN_SECRET) return erro('Não autorizado.', 401)

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const body = await req.json().catch(() => ({}))
    const { action } = body

    if (action === 'listar') {
      const { data: restaurantes, error: listError } = await admin
        .from('restaurantes')
        .select('id, nome, cidade, endereco, telefone, slug, created_at, trial_fim, indicado_por, indicacao_confirmada, creditos_indicacao')
        .order('created_at', { ascending: false })
      if (listError) return erro('Não foi possível carregar os restaurantes: ' + listError.message)

      const porId = new Map((restaurantes || []).map(r => [r.id, r]))
      const lista = (restaurantes || []).map(r => ({ ...r, dias_trial_restantes: diasRestantes(r.trial_fim) }))
      const indicacoesPendentes = (restaurantes || [])
        .filter(r => r.indicado_por && !r.indicacao_confirmada)
        .map(r => ({
          ...r,
          dias_trial_restantes: diasRestantes(r.trial_fim),
          indicante_nome: porId.get(r.indicado_por)?.nome || null,
        }))

      return jsonResponse({ total: lista.length, restaurantes: lista, indicacoes_pendentes: indicacoesPendentes })
    }

    if (action === 'confirmar_indicacao') {
      const { restaurante_id, tipo } = body
      if (!restaurante_id) return erro('Informe o restaurante.')
      if (tipo !== 'trial' && tipo !== 'credito') return erro('Informe o tipo de recompensa: "trial" (+30 dias) ou "credito" (+1 mês).')

      const { data: indicado } = await admin
        .from('restaurantes')
        .select('id, indicado_por, indicacao_confirmada')
        .eq('id', restaurante_id)
        .maybeSingle()
      if (!indicado) return erro('Restaurante não encontrado.')
      if (!indicado.indicado_por) return erro('Esse restaurante não tem indicação registrada.')
      if (indicado.indicacao_confirmada) return erro('Essa indicação já foi confirmada antes.')

      // Marca como confirmada ANTES de conceder a recompensa, e de forma
      // atômica (a condição indicacao_confirmada=false vai dentro do próprio
      // update, não numa checagem separada antes) — evita que dois cliques
      // em "Confirmar" quase simultâneos concedam a recompensa duas vezes.
      // Se essa atualização não afetar nenhuma linha, é porque outra
      // requisição já confirmou entre a leitura acima e agora.
      const { data: confirmados, error: updIndicadoError } = await admin
        .from('restaurantes')
        .update({ indicacao_confirmada: true })
        .eq('id', restaurante_id)
        .eq('indicacao_confirmada', false)
        .select('id')
      if (updIndicadoError) return erro('Não foi possível confirmar a indicação: ' + updIndicadoError.message)
      if (!confirmados || confirmados.length === 0) return erro('Essa indicação já foi confirmada antes.')

      const { data: indicante } = await admin
        .from('restaurantes')
        .select('id, trial_fim, creditos_indicacao')
        .eq('id', indicado.indicado_por)
        .maybeSingle()
      if (!indicante) return erro('Indicação confirmada, mas o restaurante indicante não foi encontrado (pode ter sido removido) — recompensa não concedida.')

      if (tipo === 'trial') {
        const baseAtual = indicante.trial_fim ? new Date(indicante.trial_fim).getTime() : Date.now()
        const novoTrialFim = new Date(baseAtual + 30 * DIA_MS).toISOString()
        const { error: updIndicanteError } = await admin
          .from('restaurantes')
          .update({ trial_fim: novoTrialFim })
          .eq('id', indicante.id)
        if (updIndicanteError) return erro('Indicação confirmada, mas não foi possível estender o trial do indicante: ' + updIndicanteError.message)
      } else {
        const { error: updIndicanteError } = await admin
          .from('restaurantes')
          .update({ creditos_indicacao: (indicante.creditos_indicacao || 0) + 1 })
          .eq('id', indicante.id)
        if (updIndicanteError) return erro('Indicação confirmada, mas não foi possível conceder o crédito ao indicante: ' + updIndicanteError.message)
      }

      return jsonResponse({ ok: true })
    }

    return erro('Ação inválida.')
  } catch (err) {
    return jsonResponse({ error: (err as Error).message || 'Erro inesperado.' }, 500)
  }
})
