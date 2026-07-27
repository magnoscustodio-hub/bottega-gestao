// Componente compartilhado: lista livre de linhas "quantidade de mesas +
// lugares por mesa" (ex: 5 mesas de 2 lugares, 8 mesas de 4 lugares...).
// Usado tanto no onboarding (step "Espaço físico") quanto em Configurações >
// Praças e áreas de suporte — carregado nas duas páginas via <script src>,
// já que nenhuma das duas usa bundler/import.
//
// Cada página é dona do seu próprio estado (o array de linhas em si) e do
// seu próprio fluxo de salvar; este módulo só cuida de somar totais, montar
// o HTML da lista e reagir a add/remove/edição de linha, chamando de volta
// a função de re-render que a página registrou.

const MC_REGISTRY = {};

function mcTotais(linhas) {
  return (linhas || []).reduce((t, l) => {
    const qtd = parseInt(l.qtd) || 0;
    const lugares = parseInt(l.lugares) || 0;
    t.mesas += qtd;
    t.lugares += qtd * lugares;
    return t;
  }, { mesas: 0, lugares: 0 });
}

// Ponto de partida editável pra praças que já existiam com mesas/lugares
// como totais soltos, mas ainda não têm o detalhamento em linhas — só usado
// em memória (nada é gravado até a página chamadora salvar).
function mcEstimarLinhas(mesasAtual, lugaresAtual) {
  const mesas = parseInt(mesasAtual) || 0;
  const lugares = parseInt(lugaresAtual) || 0;
  if (mesas <= 0) return [];
  return [{ qtd: mesas, lugares: Math.round(lugares / mesas) }];
}

function mcRegistrar(chave, linhas, onChange) {
  MC_REGISTRY[chave] = { linhas, onChange };
}

function mcAdicionar(chave) {
  const r = MC_REGISTRY[chave]; if (!r) return;
  r.linhas.push({ qtd: 0, lugares: 0 });
  r.onChange();
}
function mcRemover(chave, i) {
  const r = MC_REGISTRY[chave]; if (!r) return;
  r.linhas.splice(i, 1);
  r.onChange();
}
function mcAtualizar(chave, i, campo, valor) {
  const r = MC_REGISTRY[chave]; if (!r) return;
  r.linhas[i][campo] = parseInt(valor) || 0;
  r.onChange();
}

function mcHtml(chave, linhas) {
  const t = mcTotais(linhas);
  let h = `<div style="margin-bottom:8px">`;
  (linhas || []).forEach((l, i) => {
    h += `<div style="display:flex;gap:6px;align-items:center;margin-bottom:6px">
      <input type="number" min="0" inputmode="numeric" placeholder="Qtd." value="${l.qtd || ""}" oninput="mcAtualizar('${chave}',${i},'qtd',this.value)" style="width:64px;font-size:13px;padding:8px;border-radius:8px;border:1.5px solid var(--border-s,#D4CBC0);background:var(--surface2,#F7F4F0);color:inherit;font-family:inherit;-webkit-appearance:none">
      <span style="font-size:12px;color:var(--text2,#6B5F52);white-space:nowrap">mesa(s) de</span>
      <input type="number" min="0" inputmode="numeric" placeholder="Lugares" value="${l.lugares || ""}" oninput="mcAtualizar('${chave}',${i},'lugares',this.value)" style="width:72px;font-size:13px;padding:8px;border-radius:8px;border:1.5px solid var(--border-s,#D4CBC0);background:var(--surface2,#F7F4F0);color:inherit;font-family:inherit;-webkit-appearance:none">
      <span style="font-size:12px;color:var(--text2,#6B5F52);white-space:nowrap;flex:1">lugar(es)</span>
      <button type="button" onclick="mcRemover('${chave}',${i})" style="width:26px;height:26px;border-radius:50%;border:1.5px solid var(--border-s,#D4CBC0);background:transparent;color:var(--danger,#B02020);cursor:pointer;font-size:14px;flex-shrink:0;font-family:inherit">×</button>
    </div>`;
  });
  h += `</div>
    <button type="button" onclick="mcAdicionar('${chave}')" style="width:100%;padding:8px;border-radius:8px;border:1.5px dashed var(--border-s,#D4CBC0);background:transparent;color:var(--text2,#6B5F52);font-size:12px;font-weight:700;cursor:pointer;font-family:inherit;margin-bottom:8px">+ Adicionar linha</button>
    <div style="font-size:12px;font-weight:700;color:var(--text2,#6B5F52);margin-bottom:10px">Total: ${t.mesas} mesa${t.mesas !== 1 ? "s" : ""} · ${t.lugares} lugar${t.lugares !== 1 ? "es" : ""}</div>`;
  return h;
}
