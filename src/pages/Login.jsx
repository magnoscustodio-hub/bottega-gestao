import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { supabase } from '../lib/supabaseClient'
import RestauranteAvatar from '../components/RestauranteAvatar'

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

    // Caminho absoluto a partir da raiz do app — precisa ser assim porque
    // esta página também vive na rota aninhada /login/:slug: um caminho
    // relativo ('painel.html') resolveria contra o segmento do slug (ex:
    // /login/bottega-bernacca -> /login/painel.html, quebrando o redirect).
    window.location.href = `${import.meta.env.BASE_URL}painel.html`
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
        {/* Absoluto pelo mesmo motivo do redirect pós-login: essa página
            também vive em /login/:slug, onde um href relativo resolveria
            errado (ex: /login/onboarding.html). */}
        Não tem conta? <a href={`${import.meta.env.BASE_URL}onboarding.html`}>Cadastre seu restaurante</a>
      </p>
    </form>
  )
}

// restauranteId: obrigatório — sem ele não é seguro listar ninguém (traria
// funcionários de todos os restaurantes cadastrados misturados na mesma
// lista, um vazamento entre clientes diferentes).
function LoginEquipe({ restauranteId }) {
  const [pessoas, setPessoas] = useState([])
  const [emailLogin, setEmailLogin] = useState('')
  const [pin, setPin] = useState('')
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const [carregandoLista, setCarregandoLista] = useState(true)

  useEffect(() => {
    let ativo = true

    async function carregarPessoas() {
      const { data, error: listaError } = await supabase
        .from('funcionarios_login_publico')
        .select('perfil_id, nome, email_login')
        .eq('restaurante_id', restauranteId)
        .order('nome')

      if (!ativo) return

      if (listaError) {
        setError('Não foi possível carregar a lista de funcionários.')
      } else {
        setPessoas(data || [])
      }
      setCarregandoLista(false)
    }

    carregarPessoas()

    return () => {
      ativo = false
    }
  }, [restauranteId])

  async function handleSubmit(event) {
    event.preventDefault()
    setError(null)

    if (!emailLogin) {
      setError('Escolha seu nome na lista.')
      return
    }

    setLoading(true)

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: emailLogin,
      password: pin,
    })

    setLoading(false)

    if (signInError) {
      setError('PIN incorreto. Confira e tente de novo.')
      return
    }

    // Caminho absoluto a partir da raiz do app — precisa ser assim porque
    // esta página também vive na rota aninhada /login/:slug: um caminho
    // relativo ('painel.html') resolveria contra o segmento do slug (ex:
    // /login/bottega-bernacca -> /login/painel.html, quebrando o redirect).
    window.location.href = `${import.meta.env.BASE_URL}painel.html`
  }

  return (
    <form className="auth-card" onSubmit={handleSubmit}>
      <label htmlFor="funcionario">Quem é você?</label>
      <select
        id="funcionario"
        value={emailLogin}
        onChange={(event) => setEmailLogin(event.target.value)}
        disabled={carregandoLista}
        required
      >
        <option value="">
          {carregandoLista ? 'Carregando...' : 'Selecione seu nome'}
        </option>
        {pessoas.map((p) => (
          <option key={p.perfil_id} value={p.email_login}>
            {p.nome}
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
  const { slug } = useParams()
  const [aba, setAba] = useState('dono')
  const [restaurante, setRestaurante] = useState(null)
  const [carregandoRestaurante, setCarregandoRestaurante] = useState(!!slug)
  const [slugInvalido, setSlugInvalido] = useState(false)

  useEffect(() => {
    if (!slug) {
      setRestaurante(null)
      setCarregandoRestaurante(false)
      setSlugInvalido(false)
      return
    }

    let ativo = true
    setCarregandoRestaurante(true)
    setSlugInvalido(false)

    async function carregarRestaurante() {
      const { data, error } = await supabase
        .from('restaurante_login_publico')
        .select('id, nome, logo_url')
        .eq('slug', slug)
        .maybeSingle()

      if (!ativo) return

      if (error || !data) {
        setRestaurante(null)
        setSlugInvalido(true)
      } else {
        setRestaurante(data)
        // Link é específico da equipe — não faz sentido abrir já na aba do dono.
        setAba('equipe')
      }
      setCarregandoRestaurante(false)
    }

    carregarRestaurante()

    return () => {
      ativo = false
    }
  }, [slug])

  return (
    <main className="auth">
      <div className="auth-wrap">
        {slug && restaurante && (
          <div className="auth-restaurante">
            <RestauranteAvatar nome={restaurante.nome} logoUrl={restaurante.logo_url} size={56} />
            <span className="auth-restaurante-nome">{restaurante.nome}</span>
          </div>
        )}

        <h1>Entrar</h1>
        <p className="auth-subtitle">Acesse sua conta do GestãoSalão.</p>

        {slug && slugInvalido && (
          <p className="auth-error" style={{ marginBottom: 16 }}>
            Link de login inválido. Confira o link com o gerente do restaurante.
          </p>
        )}

        {!carregandoRestaurante && (
          <>
            <div className="auth-tabs">
              <button
                type="button"
                className={aba === 'dono' ? 'auth-tab active' : 'auth-tab'}
                onClick={() => setAba('dono')}
              >
                Sou dono/administrador
              </button>
              {slug && restaurante && (
                <button
                  type="button"
                  className={aba === 'equipe' ? 'auth-tab active' : 'auth-tab'}
                  onClick={() => setAba('equipe')}
                >
                  Sou da equipe
                </button>
              )}
            </div>

            {aba === 'equipe' && slug && restaurante ? (
              <LoginEquipe restauranteId={restaurante.id} />
            ) : (
              <LoginDono />
            )}
          </>
        )}
      </div>
    </main>
  )
}

export default Login
