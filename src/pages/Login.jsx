import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'

const EMAIL_SINTETICO_DOMINIO = 'login.gestaosalao.internal'
const emailSintetico = (funcionarioId) => `f-${funcionarioId}@${EMAIL_SINTETICO_DOMINIO}`

function LoginDono() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setError(null)
    setLoading(true)

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    setLoading(false)

    if (signInError) {
      setError(signInError.message)
      return
    }

    window.location.href = 'painel.html'
  }

  return (
    <form className="auth-card" onSubmit={handleSubmit}>
      <label htmlFor="email">E-mail</label>
      <input
        id="email"
        type="email"
        autoComplete="email"
        value={email}
        onChange={(event) => setEmail(event.target.value)}
        required
      />

      <label htmlFor="password">Senha</label>
      <input
        id="password"
        type="password"
        autoComplete="current-password"
        value={password}
        onChange={(event) => setPassword(event.target.value)}
        required
      />

      {error && <p className="auth-error">{error}</p>}

      <button type="submit" disabled={loading}>
        {loading ? 'Entrando...' : 'Entrar'}
      </button>

      <p className="auth-footer">
        Não tem conta? <a href="onboarding.html">Cadastre seu restaurante</a>
      </p>
    </form>
  )
}

function LoginEquipe() {
  const [funcionarios, setFuncionarios] = useState([])
  const [funcionarioId, setFuncionarioId] = useState('')
  const [pin, setPin] = useState('')
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const [carregandoLista, setCarregandoLista] = useState(true)

  useEffect(() => {
    let ativo = true

    async function carregarFuncionarios() {
      const { data, error: listaError } = await supabase
        .from('funcionarios_login_publico')
        .select('funcionario_id, nome')
        .order('nome')

      if (!ativo) return

      if (listaError) {
        setError('Não foi possível carregar a lista de funcionários.')
      } else {
        setFuncionarios(data || [])
      }
      setCarregandoLista(false)
    }

    carregarFuncionarios()

    return () => {
      ativo = false
    }
  }, [])

  async function handleSubmit(event) {
    event.preventDefault()
    setError(null)

    if (!funcionarioId) {
      setError('Escolha seu nome na lista.')
      return
    }

    setLoading(true)

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: emailSintetico(funcionarioId),
      password: pin,
    })

    setLoading(false)

    if (signInError) {
      setError('PIN incorreto. Confira e tente de novo.')
      return
    }

    window.location.href = 'painel.html'
  }

  return (
    <form className="auth-card" onSubmit={handleSubmit}>
      <label htmlFor="funcionario">Quem é você?</label>
      <select
        id="funcionario"
        value={funcionarioId}
        onChange={(event) => setFuncionarioId(event.target.value)}
        disabled={carregandoLista}
        required
      >
        <option value="">
          {carregandoLista ? 'Carregando...' : 'Selecione seu nome'}
        </option>
        {funcionarios.map((f) => (
          <option key={f.funcionario_id} value={f.funcionario_id}>
            {f.nome}
          </option>
        ))}
      </select>

      <label htmlFor="pin">PIN</label>
      <input
        id="pin"
        type="password"
        inputMode="numeric"
        pattern="\d{6}"
        maxLength={6}
        autoComplete="off"
        value={pin}
        onChange={(event) => setPin(event.target.value.replace(/\D/g, ''))}
        required
      />

      {error && <p className="auth-error">{error}</p>}

      <button type="submit" disabled={loading || carregandoLista}>
        {loading ? 'Entrando...' : 'Entrar'}
      </button>
    </form>
  )
}

function Login() {
  const [aba, setAba] = useState('dono')

  return (
    <main className="auth">
      <div className="auth-wrap">
        <h1>Entrar</h1>
        <p className="auth-subtitle">Acesse sua conta do GestãoSalão.</p>

        <div className="auth-tabs">
          <button
            type="button"
            className={aba === 'dono' ? 'auth-tab active' : 'auth-tab'}
            onClick={() => setAba('dono')}
          >
            Sou dono/administrador
          </button>
          <button
            type="button"
            className={aba === 'equipe' ? 'auth-tab active' : 'auth-tab'}
            onClick={() => setAba('equipe')}
          >
            Sou da equipe
          </button>
        </div>

        {aba === 'dono' ? <LoginDono /> : <LoginEquipe />}
      </div>
    </main>
  )
}

export default Login
