// Importação única dos dados já testados do Bottega Bernacca para o Supabase.
// Rode uma vez, manualmente:
//
//   $env:DONO_EMAIL = "dono@bottegabernacca.com"
//   $env:DONO_SENHA = "uma-senha-forte"
//   node scripts/migrar-bottega.mjs
//
// As credenciais nunca ficam neste arquivo — vêm de variáveis de ambiente
// definidas por você na hora de rodar.

import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'https://ufsdmlyrbkvgrlemvzde.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_ylatUIjLh_w05QXuW0ORYQ_adC3-mvp'

const DONO_EMAIL = process.env.DONO_EMAIL
const DONO_SENHA = process.env.DONO_SENHA

if (!DONO_EMAIL || !DONO_SENHA) {
  console.error('Defina as variáveis de ambiente DONO_EMAIL e DONO_SENHA antes de rodar este script.')
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

const ANO = 2026
const MES = 6 // julho (índice 0-based, igual ao usado no painel)

const PAX = {
  Segunda: { a: 122, j: 57 },
  Terça: { a: 134, j: 101 },
  Quarta: { a: 154, j: 111 },
  Quinta: { a: 185, j: 131 },
  Sexta: { a: 262, j: 187 },
  Sábado: { a: 486, j: 218 },
  Domingo: { a: 482, j: 19 },
}

const DIAS_FECHADOS = [
  { dia_semana: 'Segunda', turno: 'jantar' },
  { dia_semana: 'Domingo', turno: 'jantar' },
]

const SETORES = [
  { chave: 'garcons', nome: 'Garçons', emoji: '🍽️', cor: '#1A4A8B', min: 3, membros: ['Daniel', 'Corinto', 'Isaías', 'Maya', 'Viviana', 'Leyla', 'Vanderlei', 'Vinicius', 'Jose', 'Antonio'] },
  { chave: 'bar', nome: 'Bar', emoji: '🍹', cor: '#8B3A1A', min: 2, membros: ['Paulo', 'Breno', 'João', 'Willian'] },
  { chave: 'rec', nome: 'Recepção', emoji: '🤝', cor: '#8B1A4A', min: 2, membros: ['Tayna', 'Fernanda', 'Fernanda Karen'] },
  { chave: 'boqb', nome: 'Boqueta Bebida', emoji: '🥂', cor: '#4A1A8B', min: 1, membros: ['Edicarlos', 'Vini Guimarães'] },
  { chave: 'boqc', nome: 'Boqueta Comida', emoji: '🍲', cor: '#8B6000', min: 1, membros: ['Emanuela', 'Jovana'] },
  { chave: 'fax', nome: 'Faxina', emoji: '🧹', cor: '#4A4A4A', min: 2, membros: ['Michele', 'Maria', 'Tayna (faxina)'] },
]

// Isaías é o preferencial da Praça 01. Está de férias em julho/2026 e volta em agosto.
const PRACAS = [
  { nome: 'Praça 01', mesas: 55, lugares: 62, fim_semana: false, gc: ['Daniel', 'Corinto', 'Isaías'] },
  { nome: 'Praça 02', mesas: 23, lugares: 64, fim_semana: false, gc: ['Viviana', 'Leyla'] },
  { nome: 'Praça 03', mesas: 20, lugares: 56, fim_semana: false, gc: ['Vanderlei', 'Vinicius', 'Jose'] },
  { nome: 'Praça 04', mesas: 67, lugares: 110, fim_semana: false, gc: ['Maya', 'Antonio'] },
  { nome: 'Praça Espera', mesas: 0, lugares: 0, fim_semana: true, gc: [] },
]

const FOLGAS_JULHO = {
  Daniel: [7, 12, 14, 21, 28], Jose: [1, 6, 13, 19, 20, 27], Vinicius: [8, 15, 22, 26, 29],
  Vanderlei: [6, 12, 13, 20, 27], Leyla: [7, 14, 21, 26, 28], Viviana: [6, 13, 19, 20, 27],
  Maya: [5, 6, 13, 20, 27], Corinto: [1, 7, 12, 14, 20, 21, 28], Antonio: [5, 6, 13, 20, 27],
  Emanuela: [6, 13, 19, 20, 27], 'Vini Guimarães': [7, 14, 21, 26, 27, 28],
  Edicarlos: [8, 12, 15, 22, 29], Jovana: [1, 5, 8, 15, 22, 29],
  João: [5, 7, 13, 21, 28], Paulo: [5, 6, 13, 20, 27], Breno: [6, 14, 19, 20, 27], Willian: [8, 12, 13, 22, 29],
  Tayna: [6, 13, 19, 20, 27], Fernanda: [6, 13, 20, 27], 'Fernanda Karen': [7, 14, 21, 26, 28],
  Michele: [7, 12, 14, 21, 28], Maria: [5, 6, 13, 20, 27], 'Tayna (faxina)': [6, 13, 20, 26, 27],
}

// Fernanda e Isaías tiram férias em julho inteiro; ambos voltam em agosto/2026.
const FERIAS_JULHO = ['Fernanda', 'Isaías']

// Maya e Vanderlei entram às 15h (em vez do horário padrão), só de segunda a sexta.
// Sábados, domingos e feriados seguem o horário normal.
const HORARIOS_ESPECIAIS = {
  Maya: { dias: ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'], hora: '15h' },
  Vanderlei: { dias: ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'], hora: '15h' },
}

function diasDoMes(ano, mesIdx) {
  return new Date(ano, mesIdx + 1, 0).getDate()
}

async function main() {
  console.log('Criando conta do dono...')
  let session, user
  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email: DONO_EMAIL,
    password: DONO_SENHA,
  })
  if (signUpError && /already registered|already exists/i.test(signUpError.message)) {
    console.log('E-mail já cadastrado — entrando com a conta existente...')
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: DONO_EMAIL,
      password: DONO_SENHA,
    })
    if (signInError) throw signInError
    session = signInData.session
    user = signInData.user
  } else if (signUpError) {
    throw signUpError
  } else {
    session = signUpData.session
    user = signUpData.user
  }
  if (!session) {
    throw new Error('Conta criada, mas exige confirmação de e-mail antes de continuar. Confirme o e-mail e rode o script novamente.')
  }
  const ownerId = user.id

  console.log('Verificando se este dono já tem um restaurante cadastrado...')
  const { data: restauranteExistente, error: checkError } = await supabase
    .from('restaurantes')
    .select('id, nome')
    .eq('owner_id', ownerId)
  if (checkError) throw checkError
  if (restauranteExistente.length > 0) {
    throw new Error(
      `Este dono já tem ${restauranteExistente.length} restaurante(s) cadastrado(s) (${restauranteExistente.map((r) => r.nome).join(', ')}). ` +
      'Abortando para não criar um duplicado — apague o restaurante antigo no Supabase (ou nesta conta) antes de rodar a migração de novo, se for o caso.'
    )
  }

  console.log('Criando restaurante...')
  const { data: restaurante, error: restError } = await supabase
    .from('restaurantes')
    .insert({ owner_id: ownerId, nome: 'Bottega Bernacca', cidade: 'São Paulo' })
    .select()
    .single()
  if (restError) throw restError
  const restauranteId = restaurante.id

  console.log('Criando setores e funcionários...')
  const funcionarioIdPorNome = {}
  for (const [i, setor] of SETORES.entries()) {
    const { data: setorCriado, error: setorError } = await supabase
      .from('setores')
      .insert({ restaurante_id: restauranteId, chave: setor.chave, nome: setor.nome, emoji: setor.emoji, cor: setor.cor, min_funcionarios: setor.min, ordem: i })
      .select()
      .single()
    if (setorError) throw setorError

    for (const nome of setor.membros) {
      const { data: func, error: funcError } = await supabase
        .from('funcionarios')
        .insert({ restaurante_id: restauranteId, nome, setor_id: setorCriado.id })
        .select()
        .single()
      if (funcError) throw funcError
      funcionarioIdPorNome[nome] = func.id
    }
  }

  console.log('Criando praças e preferências de garçom...')
  for (const [i, praca] of PRACAS.entries()) {
    const { data: pracaCriada, error: pracaError } = await supabase
      .from('pracas')
      .insert({ restaurante_id: restauranteId, nome: praca.nome, mesas: praca.mesas, lugares: praca.lugares, fim_semana: praca.fim_semana, ordem: i })
      .select()
      .single()
    if (pracaError) throw pracaError

    for (const nome of praca.gc) {
      const funcionarioId = funcionarioIdPorNome[nome]
      if (!funcionarioId) {
        console.warn(`  aviso: "${nome}" não encontrado entre os funcionários criados, pulando preferência de praça.`)
        continue
      }
      const { error: updError } = await supabase
        .from('funcionarios')
        .update({ praca_preferencial_id: pracaCriada.id })
        .eq('id', funcionarioId)
      if (updError) throw updError
    }
  }

  console.log('Salvando PAX esperado...')
  const paxRows = []
  Object.entries(PAX).forEach(([dia, v]) => {
    if (v.a > 0) paxRows.push({ restaurante_id: restauranteId, dia_semana: dia, turno: 'almoco', quantidade: v.a })
    if (v.j > 0) paxRows.push({ restaurante_id: restauranteId, dia_semana: dia, turno: 'jantar', quantidade: v.j })
  })
  const { error: paxError } = await supabase.from('pax_esperado').insert(paxRows)
  if (paxError) throw paxError

  console.log('Salvando dias fechados...')
  const { error: fechadosError } = await supabase
    .from('dias_fechados')
    .insert(DIAS_FECHADOS.map((d) => ({ restaurante_id: restauranteId, ...d })))
  if (fechadosError) throw fechadosError

  console.log('Salvando folgas de julho/2026...')
  const folgasRows = []
  Object.entries(FOLGAS_JULHO).forEach(([nome, dias]) => {
    const funcionarioId = funcionarioIdPorNome[nome]
    if (!funcionarioId) return
    dias.forEach((dia) => {
      folgasRows.push({ funcionario_id: funcionarioId, data: `${ANO}-${String(MES + 1).padStart(2, '0')}-${String(dia).padStart(2, '0')}` })
    })
  })
  const { error: folgasError } = await supabase.from('folgas').insert(folgasRows)
  if (folgasError) throw folgasError

  console.log('Salvando férias de julho/2026 como ausências...')
  const feriasRows = []
  FERIAS_JULHO.forEach((nome) => {
    const funcionarioId = funcionarioIdPorNome[nome]
    if (!funcionarioId) return
    const totalDias = diasDoMes(ANO, MES)
    for (let dia = 1; dia <= totalDias; dia++) {
      feriasRows.push({
        funcionario_id: funcionarioId,
        data: `${ANO}-${String(MES + 1).padStart(2, '0')}-${String(dia).padStart(2, '0')}`,
        motivo: 'Férias',
      })
    }
  })
  if (feriasRows.length > 0) {
    const { error: feriasError } = await supabase.from('ausencias').insert(feriasRows)
    if (feriasError) throw feriasError
  }

  console.log('Salvando horários especiais de entrada...')
  const horariosRows = Object.entries(HORARIOS_ESPECIAIS)
    .map(([nome, h]) => {
      const funcionarioId = funcionarioIdPorNome[nome]
      if (!funcionarioId) return null
      return { funcionario_id: funcionarioId, dias: h.dias, hora: h.hora }
    })
    .filter(Boolean)
  if (horariosRows.length > 0) {
    const { error: horariosError } = await supabase.from('horarios_especiais').insert(horariosRows)
    if (horariosError) throw horariosError
  }

  console.log('\nMigração concluída! Restaurante:', restauranteId)
  console.log('Faça login em /login com o e-mail informado para ver o painel.')
}

main().catch((err) => {
  console.error('Erro na migração:', err.message || err)
  process.exit(1)
})
