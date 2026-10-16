// Akari · utilidades dos wallpapers animados
// Todas as animações usam períodos que dividem LOOP, para o vídeo fechar o loop sem emenda.
const LOOP = 16; // segundos
const PETALA = "M0 -14 C-20 -30 -26 -58 -12 -76 L0 -66 L12 -76 C26 -58 20 -30 0 -14 Z";

// Números "aleatórios" com semente fixa (sempre o mesmo resultado)
function semente(s) {
  return () => (s = (s * 16807) % 2147483647) / 2147483647;
}

function svgPetala(cor, tam) {
  return `<svg width="${tam}" height="${tam}" viewBox="-40 -90 80 90" style="overflow:visible">
    <path d="${PETALA}" fill="${cor}" fill-opacity=".35" stroke="${cor}" stroke-width="3.5" stroke-linejoin="round"/></svg>`;
}

// Pétalas atravessando a tela. dir: vetor do vento (dx, dy) em px por loop.
function petalas(alvo, n, { cor = "#fff", seed = 7, dx = 300, dy = 1400, tamMin = 18, tamMax = 46, w = 1920, h = 1080 } = {}) {
  const r = semente(seed);
  const periodos = [LOOP, LOOP / 2, LOOP / 2, LOOP / 4];
  let html = "";
  for (let i = 0; i < n; i++) {
    const prof = r();
    const dur = periodos[Math.floor(r() * periodos.length)];
    const k = w / 1920;
    const x0 = r() * (w + 280 * k) - 300 * k - dx * 0.5, y0 = -120 * k - r() * 200 * k;
    const x1 = x0 + dx * (0.6 + r() * 0.8), y1 = y0 + dy + 300 * k;
    const r0 = Math.floor(r() * 360), r1 = r0 + (r() > 0.5 ? 1 : -1) * (180 + Math.floor(r() * 360));
    const tam = (tamMin + prof * (tamMax - tamMin)) * k;
    const blur = prof < 0.3 ? 3 : prof < 0.55 ? 1.2 : 0;
    const op = 0.25 + prof * 0.7;
    const atraso = -(r() * dur).toFixed(2);
    const balanço = [LOOP / 8, LOOP / 4][Math.floor(r() * 2)];
    html += `<div class="petala" style="--x0:${x0}px;--y0:${y0}px;--x1:${x1}px;--y1:${y1}px;--r0:${r0}deg;--r1:${r1}deg;--op:${op};
      animation-duration:${dur}s;animation-delay:${atraso}s;filter:blur(${blur}px)">
      <div class="balanco" style="animation-duration:${balanço}s;animation-delay:${-(r() * balanço).toFixed(2)}s">${svgPetala(cor, tam)}</div></div>`;
  }
  alvo.insertAdjacentHTML("beforeend", html);
}

// CSS comum das pétalas (injetado uma vez)
document.head.insertAdjacentHTML("beforeend", `<style>
  .petala{position:absolute;left:0;top:0;animation-name:cai;animation-timing-function:linear;animation-iteration-count:infinite;will-change:transform}
  .balanco{animation-name:balanca;animation-timing-function:ease-in-out;animation-iteration-count:infinite;animation-direction:alternate}
  @keyframes cai{
    0%{transform:translate(var(--x0),var(--y0)) rotate(var(--r0));opacity:0}
    8%{opacity:var(--op)} 92%{opacity:var(--op)}
    100%{transform:translate(var(--x1),var(--y1)) rotate(var(--r1));opacity:0}}
  @keyframes balanca{from{transform:translateX(-30px) rotate(-12deg)}to{transform:translateX(30px) rotate(12deg)}}
  @keyframes respira{0%,100%{opacity:.45}50%{opacity:.95}}
  @keyframes respiraHalo{0%,100%{opacity:.7}50%{opacity:1}}
</style>`);

// Controle de tempo para gravar quadro a quadro (usado pelo gerador)
window.akariSeek = (ms) => {
  for (const a of document.getAnimations()) { a.pause(); a.currentTime = ms; }
};
