import { Link } from 'react-router-dom'
import LogoGestaoOperacional from '../components/LogoGestaoOperacional'

const features = [
  {
    title: 'Login',
    description: 'Acesso seguro para donos e funcionários do restaurante.',
  },
  {
    title: 'Cadastro de Restaurante',
    description: 'Registre os dados do seu estabelecimento e do salão.',
  },
  {
    title: 'Escala de Funcionários',
    description: 'Organize turnos e escalas da equipe com facilidade.',
  },
]

function Home() {
  return (
    <main className="home">
      <div className="home-inner">
        <div className="entry-block">
          <div className="entry-topbar">
            <LogoGestaoOperacional size={72} />
            <span className="entry-brand">GESTÃO OPERACIONAL</span>
          </div>

          <div className="entry-hero">
            <h1 className="entry-title">GestãoSalão</h1>
            <p className="entry-subtitle">Organize turnos e escalas com facilidade.</p>
          </div>

          <div className="entry-actions">
            <Link className="btn-primary" to="/login">
              Entrar
            </Link>
            <a className="btn-secondary" href="/onboarding.html">
              Cadastrar restaurante
            </a>
          </div>
          <a className="entry-link-secondary" href="/painel.html">
            Escala de funcionários
          </a>
        </div>

        <section className="home-features">
          {features.map((feature) => (
            <article key={feature.title} className="feature-card">
              <h2>{feature.title}</h2>
              <p>{feature.description}</p>
            </article>
          ))}
        </section>
      </div>
    </main>
  )
}

export default Home
