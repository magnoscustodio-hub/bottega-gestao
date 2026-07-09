import { Link } from 'react-router-dom'

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
      <header className="home-hero">
        <h1>GestãoSalão</h1>
        <p>Sistema de gestão de salão para restaurantes.</p>
        <div className="home-cta-group">
          <Link className="home-cta" to="/login">
            Entrar
          </Link>
          <a className="home-cta home-cta-secondary" href="/onboarding.html">
            Cadastrar restaurante
          </a>
          <a className="home-cta home-cta-secondary" href="/painel.html">
            Escala de funcionários
          </a>
        </div>
      </header>

      <section className="home-features">
        {features.map((feature) => (
          <article key={feature.title} className="feature-card">
            <h2>{feature.title}</h2>
            <p>{feature.description}</p>
          </article>
        ))}
      </section>
    </main>
  )
}

export default Home
