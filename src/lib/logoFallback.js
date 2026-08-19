// Mesmo algoritmo usado em public/painel.html (logoOuFallbackHtml) — cor e
// iniciais determinísticas por nome, pra manter a mesma identidade visual
// entre o painel e a tela de login quando o restaurante ainda não tem logo
// próprio enviado.
const CORES = ['#B02020', '#378ADD', '#2E9E5B', '#C77D2E', '#7B4FA0', '#1F8A8C']

export function iniciaisDoNome(nome) {
  const palavras = (nome || '').trim().split(/\s+/).filter(Boolean)
  return ((palavras[0]?.[0] || '') + (palavras[1]?.[0] || '')).toUpperCase()
}

export function corPorNome(nome) {
  const texto = nome || ''
  let hash = 0
  for (let i = 0; i < texto.length; i++) hash = (hash * 31 + texto.charCodeAt(i)) >>> 0
  return CORES[hash % CORES.length]
}
