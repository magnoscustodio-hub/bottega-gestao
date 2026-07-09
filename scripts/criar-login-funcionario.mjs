// Cria (ou reseta) um login por PIN — de um funcionário já cadastrado em
// `funcionarios`, OU de alguém da liderança/gerência sem vínculo com a escala
// (mesmo caso do acesso de Master, mas nos níveis gerencial/consulta).
// Rode manualmente, informando a service_role key na hora — ela nunca fica
// neste arquivo nem é commitada:
//
//   $env:SUPABASE_SERVICE_ROLE_KEY = "sua-service-role-key"
//   node scripts/criar-login-funcionario.mjs
//
// Cria o usuário no Supabase Auth com um e-mail interno sintético (nunca usado
// de verdade, a pessoa não precisa saber disso) e grava o vínculo em
// perfis_acesso — sem recadastrar ninguém em `funcionarios`.
//
// Se a pessoa já tiver login, só atualiza o PIN e o nível (pede confirmação antes).

import { createClient } from '@supabase/supabase-js'
import { randomUUID } from 'node:crypto'
import { createInterface } from 'node:readline/promises'

const SUPABASE_URL = 'https://ufsdmlyrbkvgrlemvzde.supabase.co'
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!SERVICE_ROLE_KEY) {
  console.error('Defina a variável de ambiente SUPABASE_SERVICE_ROLE_KEY antes de rodar este script.')
  console.error('A chave fica em: Supabase Dashboard > Project Settings > API > service_role.')
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
})

const rl = createInterface({ input: process.stdin, output: process.stdout })
const pergunta = (texto) => rl.question(texto)

async function escolherRestaurante() {
  const { data: restaurantes, error } = await supabase.from('restaurantes').select('id, nome')
  if (error) {
    console.error('Erro ao buscar restaurantes:', error.message)
    process.exit(1)
  }
  if (!restaurantes || restaurantes.length === 0) {
    console.error('Nenhum restaurante cadastrado.')
    process.exit(1)
  }
  if (restaurantes.length === 1) {
    return restaurantes[0].id
  }
  console.log('Mais de um restaurante cadastrado, escolha um:')
  restaurantes.forEach((r) => console.log(`  ${r.id}  ${r.nome}`))
  const escolhido = (await pergunta('ID do restaurante: ')).trim()
  if (!restaurantes.some((r) => r.id === escolhido)) {
    console.error('ID não corresponde a nenhum restaurante listado.')
    process.exit(1)
  }
  return escolhido
}

async function buscarDadosFuncionario() {
  const nome = (await pergunta('Nome do funcionário (exatamente como está cadastrado em funcionarios): ')).trim()
  if (!nome) {
    console.error('Nome não pode ser vazio.')
    process.exit(1)
  }

  const { data: funcionarios, error: buscaError } = await supabase
    .from('funcionarios')
    .select('id, nome, restaurante_id')
    .ilike('nome', nome)

  if (buscaError) {
    console.error('Erro ao buscar funcionário:', buscaError.message)
    process.exit(1)
  }
  if (!funcionarios || funcionarios.length === 0) {
    console.error(`Nenhum funcionário encontrado com o nome "${nome}". Confira o cadastro na tabela funcionarios.`)
    process.exit(1)
  }
  if (funcionarios.length > 1) {
    console.error(
      `Mais de um funcionário encontrado com esse nome: ${funcionarios.map((f) => f.nome).join(', ')}. ` +
        'Ajuste pra um nome único antes de continuar.',
    )
    process.exit(1)
  }
  const funcionario = funcionarios[0]

  const { data: perfilExistente } = await supabase
    .from('perfis_acesso')
    .select('id, nivel_acesso')
    .eq('funcionario_id', funcionario.id)
    .maybeSingle()

  return {
    nomeExibicao: funcionario.nome,
    restauranteId: funcionario.restaurante_id,
    funcionarioId: funcionario.id,
    emailLogin: `f-${funcionario.id}@login.gestaosalao.internal`,
    perfilExistente,
  }
}

async function buscarDadosLideranca() {
  const nome = (await pergunta('Nome da pessoa (só pra identificação no login — NÃO entra na tabela funcionarios): ')).trim()
  if (!nome) {
    console.error('Nome não pode ser vazio.')
    process.exit(1)
  }

  const { data: perfisExistentes, error: buscaError } = await supabase
    .from('perfis_acesso')
    .select('id, nivel_acesso, nome_exibicao')
    .is('funcionario_id', null)
    .ilike('nome_exibicao', nome)

  if (buscaError) {
    console.error('Erro ao buscar perfis de acesso:', buscaError.message)
    process.exit(1)
  }
  if (perfisExistentes && perfisExistentes.length > 1) {
    console.error(`Mais de uma pessoa sem vínculo com esse nome: ${perfisExistentes.map((p) => p.nome_exibicao).join(', ')}. Ajuste pra um nome único.`)
    process.exit(1)
  }
  const perfilExistente = perfisExistentes && perfisExistentes[0] ? perfisExistentes[0] : null

  const restauranteId = perfilExistente ? null : await escolherRestaurante()

  return {
    nomeExibicao: nome,
    restauranteId,
    funcionarioId: null,
    emailLogin: `l-${randomUUID()}@login.gestaosalao.internal`,
    perfilExistente,
  }
}

async function main() {
  const tipo = (await pergunta('Essa pessoa é (1) funcionário já cadastrado na escala, ou (2) liderança/gerência sem vínculo com a escala? (1/2): ')).trim()
  if (tipo !== '1' && tipo !== '2') {
    console.error('Responda "1" (funcionário) ou "2" (liderança sem vínculo).')
    process.exit(1)
  }

  const dados = tipo === '1' ? await buscarDadosFuncionario() : await buscarDadosLideranca()
  const { nomeExibicao, restauranteId, funcionarioId, emailLogin, perfilExistente } = dados

  if (perfilExistente) {
    const confirmar = await pergunta(
      `${nomeExibicao} já tem login (nível atual: ${perfilExistente.nivel_acesso}). ` +
        'Isso vai TROCAR o PIN dele(a). Continuar? (digite "sim" para confirmar): ',
    )
    if (confirmar.trim().toLowerCase() !== 'sim') {
      console.log('Cancelado.')
      rl.close()
      return
    }
  }

  const pin = (await pergunta('PIN de 6 dígitos: ')).trim()
  if (!/^\d{6}$/.test(pin)) {
    console.error('O PIN precisa ter exatamente 6 dígitos numéricos.')
    process.exit(1)
  }

  const nivel = (await pergunta('Nível de acesso (gerencial/consulta): ')).trim().toLowerCase()
  if (nivel !== 'gerencial' && nivel !== 'consulta') {
    console.error('Nível precisa ser "gerencial" ou "consulta".')
    process.exit(1)
  }

  if (perfilExistente) {
    const { error: updError } = await supabase.auth.admin.updateUserById(perfilExistente.id, { password: pin })
    if (updError) {
      console.error('Erro ao atualizar o PIN:', updError.message)
      process.exit(1)
    }
    const { error: perfilError } = await supabase
      .from('perfis_acesso')
      .update({ nivel_acesso: nivel })
      .eq('id', perfilExistente.id)
    if (perfilError) {
      console.error('Erro ao atualizar o nível de acesso:', perfilError.message)
      process.exit(1)
    }
    console.log(`✅ PIN e nível de ${nomeExibicao} atualizados (nível: ${nivel}).`)
  } else {
    const { data: novoUsuario, error: criarError } = await supabase.auth.admin.createUser({
      email: emailLogin,
      password: pin,
      email_confirm: true,
    })
    if (criarError) {
      console.error('Erro ao criar o login:', criarError.message)
      process.exit(1)
    }

    const { error: perfilError } = await supabase.from('perfis_acesso').insert({
      id: novoUsuario.user.id,
      restaurante_id: restauranteId,
      funcionario_id: funcionarioId,
      nome_exibicao: funcionarioId ? null : nomeExibicao,
      email_login: emailLogin,
      nivel_acesso: nivel,
      metodo_login: 'pin',
    })
    if (perfilError) {
      console.error('Erro ao gravar o vínculo em perfis_acesso:', perfilError.message)
      console.error('O login já foi criado no Supabase Auth (Authentication > Users) — pode ser necessário apagá-lo manualmente antes de tentar de novo.')
      process.exit(1)
    }

    console.log(
      `✅ Login criado para ${nomeExibicao} (nível: ${nivel}). ` +
        'Ele(a) já pode entrar escolhendo o próprio nome na tela de login e digitando o PIN combinado.',
    )
  }

  rl.close()
}

main()
