function LogoGestaoOperacional({ size = 72 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
      <rect width="130" height="130" rx="30" fill="#FBF7F0" />
      <rect x="3" y="3" width="124" height="124" rx="28" fill="none" stroke="#E8D4A0" strokeWidth="1.5" />
      <g opacity=".08" fill="#1A1410">
        <circle cx="75" cy="55" r="36" />
        <circle cx="75" cy="55" r="26" fill="#FBF7F0" />
        <rect x="28" y="10" width="5" height="70" rx="2.5" />
        <rect x="24" y="10" width="4" height="22" rx="2" />
        <rect x="33" y="10" width="4" height="22" rx="2" />
        <ellipse cx="30" cy="32" rx="6" ry="3" />
        <rect x="112" y="10" width="5" height="70" rx="2.5" />
        <path d="M112 10 Q122 22 117 42 L112 42 Z" />
      </g>
      <text x="16" y="58" fontFamily="-apple-system,sans-serif" fontSize="9" fontWeight="700" fill="#B5893A" letterSpacing="3">
        23 ANOS
      </text>
      <text x="12" y="106" fontFamily="Georgia,serif" fontSize="56" fontWeight="700" fill="#1A1410" letterSpacing="-2">
        EM
      </text>
      <line x1="12" y1="114" x2="118" y2="114" stroke="#B5893A" strokeWidth="1.2" opacity=".4" />
    </svg>
  )
}

export default LogoGestaoOperacional
