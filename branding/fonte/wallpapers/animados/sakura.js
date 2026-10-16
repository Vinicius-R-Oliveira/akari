// Akari · flores de cerejeira "de verdade" (pétala fendida, miolo e estames)
// Usado pelos wallpapers rosa (13 Sakura, 14 Sakura no Ki, 15 Harukaze). Precisa do comum.js antes.

// Pétala com a pontinha fendida, base no (0,0)
const PET_REAL = "M0 0 C-15 -9 -25 -32 -19 -50 C-15 -61 -7 -64 0 -57 C7 -64 15 -61 19 -50 C25 -32 15 -9 0 0 Z";

// Gradientes (coloque uma vez dentro de um <svg>)
function sakuraDefs(id = "sk", { base = "#e2799a", meio = "#f8c9d6", ponta = "#fff2f5" } = {}) {
  return `<defs>
    <radialGradient id="${id}" cx=".5" cy="1" r="1.05"><stop offset="0" stop-color="${base}"/><stop offset=".42" stop-color="${meio}"/><stop offset="1" stop-color="${ponta}"/></radialGradient>
    <radialGradient id="${id}-bud" cx=".5" cy=".7" r=".8"><stop offset="0" stop-color="${base}"/><stop offset="1" stop-color="${meio}"/></radialGradient>
  </defs>`;
}

// Uma flor. r = random com semente (para os estames saírem sempre iguais)
function sakuraFlor(x, y, s, rot, r, { id = "sk", miolo = "#c9406a", antera = "#f3cf6a", borda = "rgba(190,80,115,.35)", classe = "" } = {}) {
  let p = "";
  for (let i = 0; i < 5; i++) {
    const a = i * 72 + (r() - 0.5) * 8;
    const k = 0.92 + r() * 0.14;
    p += `<path d="${PET_REAL}" transform="rotate(${a.toFixed(1)}) scale(${k.toFixed(2)})" fill="url(#${id})" stroke="${borda}" stroke-width="1"/>`;
  }
  let est = "";
  for (let i = 0; i < 14; i++) {
    const a = (i / 14) * Math.PI * 2 + r() * 0.3, L = 12 + r() * 9;
    const ex = Math.cos(a) * L, ey = Math.sin(a) * L;
    est += `<line x1="0" y1="0" x2="${ex.toFixed(1)}" y2="${ey.toFixed(1)}" stroke="${miolo}" stroke-width="1.1" stroke-opacity=".85"/>`
         + `<circle cx="${ex.toFixed(1)}" cy="${ey.toFixed(1)}" r="1.9" fill="${antera}"/>`;
  }
  return `<g class="${classe}" transform="translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${rot.toFixed(0)}) scale(${s.toFixed(3)})">
    ${p}<circle r="7.5" fill="${miolo}" fill-opacity=".85"/>${est}</g>`;
}

// Botão (flor fechada)
function sakuraBotao(x, y, s, rot, id = "sk") {
  return `<g transform="translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${rot.toFixed(0)}) scale(${s.toFixed(3)})">
    <path d="M0 0 L-4 10 L4 10 Z" fill="#6b3a3f"/>
    <ellipse cx="0" cy="-8" rx="8" ry="12" fill="url(#${id}-bud)"/></g>`;
}

// Galho curvo e afinando, com flores ao longo dele.
// pontos: [[x,y],...]; devolve {svg, pontos de flor}
function galhoCurvo(pontos, larg, cor = "#3a2228") {
  let d = `M${pontos[0][0]} ${pontos[0][1]}`;
  for (let i = 1; i < pontos.length; i++) {
    const [x0, y0] = pontos[i - 1], [x1, y1] = pontos[i];
    d += ` Q${x0 + (x1 - x0) * 0.5 + (y1 - y0) * 0.12} ${y0 + (y1 - y0) * 0.5 - (x1 - x0) * 0.12} ${x1} ${y1}`;
  }
  return `<path d="${d}" fill="none" stroke="${cor}" stroke-width="${larg}" stroke-linecap="round" stroke-linejoin="round"/>`;
}

// Petalas cheias (rosadas) caindo — usa a mesma física do comum.js
function petalasRosa(alvo, n, opts = {}) {
  const r = semente(opts.seed || 3);
  const cores = opts.cores || ["#f7c3d1", "#f2a7bd", "#fbd9e2", "#ec92ad"];
  petalas(alvo, n, Object.assign({}, opts, { cor: "#f4b3c5" }));
  // troca o desenho das pétalas recém-criadas por pétalas cheias com sombra suave
  const novas = [...alvo.querySelectorAll(".petala svg")].slice(-n);
  for (const s of novas) {
    const c = cores[Math.floor(r() * cores.length)];
    const path = s.querySelector("path");
    path.setAttribute("d", PET_REAL);
    path.setAttribute("transform", "translate(0 -10) scale(1.25)");
    path.setAttribute("fill", c);
    path.setAttribute("fill-opacity", ".95");
    path.setAttribute("stroke", "rgba(200,90,125,.35)");
    path.setAttribute("stroke-width", "1.2");
  }
}
