// Cria (ou reseta) o login por PIN de um funcionário já cadastrado em `funcionarios`.
// Rode manualmente, informando a service_role key na hora — ela nunca fica neste arquivo
// nem é commitada:
//
//   $env:SUPABASE_SERVICE_ROLE_KEY = "sua-service-role-key"
//   node scripts/criar-login-funcionario.mjs
//
// Pede: nome do funcionário (exatamente como está cadastrado), PIN de 6 dígitos e o
// nível de acesso (gerencial ou consulta). Cria o usuário no Supabase Auth com um
// e-mail interno sintético (nunca usado de verdade, o funcionário não precisa saber
// disso) e grava o vínculo em perfis_acesso — sem recadastrar ninguém em `funcionarios`.
//
// Se o funcionário já tiver login, só atualiza o PIN e o nível (pede confirmação antes).

import { createClient } from '@supabase/supabase-js'
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

const emailSintetico = (funcionarioId) => `f-${funcionarioId}@login.gestaosalao.internal`

async function main() {
  const nome = (await pergunta('Nome do funcionário (exatamente como está cadastrado): ')).trim()
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

  if (perfilExistente) {
    const confirmar = await pergunta(
      `${funcionario.nome} já tem login (nível atual: ${perfilExistente.nivel_acesso}). ` +
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
    console.log(`✅ PIN e nível de ${funcionario.nome} atualizados (nível: ${nivel}).`)
  } else {
    const email = emailSintetico(funcionario.id)
    const { data: novoUsuario, error: criarError } = await supabase.auth.admin.createUser({
      email,
      password: pin,
      email_confirm: true,
    })
    if (criarError) {
      console.error('Erro ao criar o login:', criarError.message)
      process.exit(1)
    }

    const { error: perfilError } = await supabase.from('perfis_acesso').insert({
      id: novoUsuario.user.id,
      restaurante_id: funcionario.restaurante_id,
      funcionario_id: funcionario.id,
      nivel_acesso: nivel,
      metodo_login: 'pin',
    })
    if (perfilError) {
      console.error('Erro ao gravar o vínculo em perfis_acesso:', perfilError.message)
      console.error('O login já foi criado no Supabase Auth (Authentication > Users) — pode ser necessário apagá-lo manualmente antes de tentar de novo.')
      process.exit(1)
    }

    console.log(
      `✅ Login criado para ${funcionario.nome} (nível: ${nivel}). ` +
        'Ele(a) já pode entrar escolhendo o próprio nome na tela de login e digitando o PIN combinado.',
    )
  }

  rl.close()
}

main()
