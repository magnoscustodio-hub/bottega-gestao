import { corPorNome, iniciaisDoNome } from '../lib/logoFallback'

// Logo real do restaurante quando existe, ou um círculo com as iniciais do
// nome (cor determinística) quando ainda não há logo próprio enviado —
// nunca mostra um placeholder de outro cliente.
function RestauranteAvatar({ nome, logoUrl, size = 56 }) {
  const style = {
    width: size,
    height: size,
    borderRadius: Math.round(size * 0.28),
    overflow: 'hidden',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    boxShadow: '0 2px 8px rgba(0,0,0,.15)',
    flexShrink: 0,
  }

  if (logoUrl) {
    return (
      <div style={style}>
        <img
          src={logoUrl}
          alt={nome || 'Logo do restaurante'}
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
        />
      </div>
    )
  }

  const iniciais = iniciaisDoNome(nome) || '🍽️'
  return (
    <div
      style={{
        ...style,
        background: corPorNome(nome || ''),
        color: 'white',
        fontWeight: 800,
        fontSize: Math.round(size * 0.36),
        letterSpacing: '.02em',
      }}
    >
      {iniciais}
    </div>
  )
}

export default RestauranteAvatar
