// The nine Bichoku animals in the Churrinche engraving style (one ink each, on paper).
// Frame: viewBox "10 20 200 196" (x 10..210, y 20..216); subjects face right, three-quarter view.
// The penguin and the hornero are ports of the kit's approved art study, in the one-ink version.
import { PAPER, band, clamp, ell } from "../../addons/churrinche_kit/art/engraving.mjs";

const PI = Math.PI;
/** Nearly horizontal, gently curved lines: the default family for bodies. */
const BODY = (cx, a = 0.7) => ({ circles: [cx, -160], r0: 190, r1: 360, a0: PI / 2 - a, a1: PI / 2 + a, sp: 2.6 });

/** A closed path through points from f(t), t in 0..1 (for fluffy, bumpy outlines). */
function loop(n, f) {
  const pts = [];
  for (let i = 0; i < n; i++) {
    const [x, y] = f(i / n);
    pts.push(`${x.toFixed(1)},${y.toFixed(1)}`);
  }
  return `M${pts.join("L")}Z`;
}

function pinguino(dr, ink) {
  const L = dr.L;
  const STRIPE = band(118, 80, 22, 20, -PI / 3, -PI / 3 - (PI * 4) / 3, 7.5 * L.st);
  const sil = "M98,30 C126,30 140,50 142,72 L162,80 L142,88 C150,110 156,140 152,170 C150,190 132,200 100,200 C66,200 48,188 48,164 C48,130 56,104 62,84 C60,54 72,30 98,30 Z";
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 122, y - 73) < 8) return 0;
    if (dr.inside(STRIPE, x, y)) return 0; // white face stripe
    if (y < 96) return 0.9; // black head
    if (x < 74 - 0.05 * (y - 100)) return 0.85; // black back and flipper
    if (Math.abs(y - (126 - 0.3 * (x - 108))) < 5.5) return 0.95; // chest band
    const f = clamp(ell(x, y, 104, 150, 52, 54));
    return 0.04 + 0.6 * f ** 3; // white belly, shaded at the rim
  }, { circles: [104, -150], r0: 170, r1: 360, a0: PI / 2 - 0.6, a1: PI / 2 + 0.6, sp: 2.6 });
  dr.path(STRIPE, { fill: PAPER, stroke: ink, "stroke-width": 1.1, "stroke-linejoin": "round" });
  dr.circle(122, 73, 7.2 * L.ey, { fill: PAPER });
  dr.outline(sil, ink);
  dr.ellipse(122, 73, 4.2 * L.ey, 4.8 * L.ey, { fill: ink });
  dr.circle(122 + 1.4 * L.ey, 73 - 1.5 * L.ey, 1.4 * L.ey, { fill: PAPER });
  dr.path("M142,72 L162,80 L142,88 Z", { fill: PAPER, stroke: ink, "stroke-width": 1.6, "stroke-linejoin": "round" });
  dr.line("M144,80 L157,80", ink, 1.1);
  dr.ellipse(86, 202, 10, 4, { fill: PAPER, stroke: ink, "stroke-width": 1.6 });
  dr.ellipse(116, 202, 10, 4, { fill: PAPER, stroke: ink, "stroke-width": 1.6 });
}

function hornero(dr, ink) {
  const L = dr.L;
  const BROW = band(128, 118, 36, 44, -PI * 0.86, -PI * 0.28, 5 * L.st);
  const sil = "M100,40 C136,40 158,64 160,96 L184,103 L160,112 C158,152 136,192 100,192 C72,192 54,178 46,158 L22,168 L38,146 C36,138 36,130 38,122 C44,72 66,40 100,40 Z";
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 130, y - 86) < 8) return 0;
    if (dr.inside(BROW, x, y)) return 0; // pale eyebrow
    if (ell(x, y, 142, 124, 17, 24) < 1) return 0.05; // pale throat
    if (x < 48) return 0.75; // tail
    const f = clamp(ell(x, y, 100, 116, 62, 78));
    let t = 0.2 + 0.55 * f ** 3 + (x < 100 ? 0.15 * f * f : 0);
    if (ell(x, y, 84, 140, 36, 30) < 1) t += 0.25; // wing a shade darker
    return t;
  }, BODY(100));
  dr.outline(sil, ink);
  dr.path(BROW, { fill: PAPER, stroke: ink, "stroke-width": 1, "stroke-linejoin": "round" });
  dr.circle(130, 86, 7.6 * L.ey, { fill: PAPER });
  dr.line("M54,114 C62,150 92,172 124,164", ink, 1.4);
  dr.line("M160,104 L176,104", ink, 1.3);
  dr.ellipse(130, 86, 5 * L.ey, 5.6 * L.ey, { fill: ink });
  dr.circle(130 + 1.6 * L.ey, 86 - 2 * L.ey, 1.5 * L.ey, { fill: PAPER });
  dr.line("M94,190 L92,204 M86,206 L98,204 M114,188 L116,204 M110,206 L122,204", ink, 1.8);
}

// --- the seven new animals (checkpoint 1: shapes) ---------------------------------------------

function yaguarete(dr, ink) {
  const sil =
    "M100,60 C92,50 94,36 106,35 C113,35 118,40 120,43 C128,39 138,38 145,41 C149,32 162,31 165,42 " +
    "C167,50 163,56 161,60 C168,68 172,78 176,84 C182,88 188,94 184,101 C180,107 172,109 164,111 " +
    "C158,114 153,118 151,122 C157,140 159,170 157,195 " +
    "C157,202 150,204 140,204 L78,204 C66,204 58,200 55,193 C38,197 22,187 22,169 C22,154 31,145 41,147 " +
    "C47,149 47,157 41,161 C35,166 38,178 55,178 C57,150 67,120 88,104 C90,90 94,72 100,60 Z";
  const MUZZLE = "M158,96 C164,87 178,88 183,96 C186,104 177,110 168,110 C160,110 155,103 158,96 Z";
  const CHEST = "M136,124 C146,118 156,128 156,150 C156,176 152,196 144,200 C134,196 130,170 130,150 C130,136 132,128 136,124 Z";
  const spots = [[88, 128], [112, 132], [104, 160], [80, 160], [124, 182], [92, 188], [116, 64], [134, 58]];
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 146, y - 74) < 9) return 0;
    if (dr.inside(MUZZLE, x, y) || dr.inside(CHEST, x, y)) return 0;
    const f = clamp(ell(x, y, 104, 130, 64, 80));
    return 0.38 + 0.5 * f ** 3;
  }, BODY(104));
  for (const [sx, sy] of dr.L.simple ? spots.slice(0, 6) : spots) {
    // rosette: a broken dark ring around a paler centre
    const r = dr.L.simple ? 8 : 6.5;
    dr.circle(sx, sy, r, {
      fill: PAPER, stroke: ink, "stroke-width": 2.6 * dr.L.ln,
      "stroke-dasharray": dr.L.simple ? "9 4" : "7 3", "stroke-linecap": "round",
    });
  }
  dr.outline(sil, ink);
  dr.path(MUZZLE, { fill: "none", stroke: ink, "stroke-width": 1.1 });
  dr.path(CHEST, { fill: "none", stroke: ink, "stroke-width": 1.1 });
  dr.path("M172,86 C179,82 190,87 189,94 C188,100 181,101 177,100 C172,98 168,90 172,86 Z", { fill: ink }); // nose
  dr.line("M181,97 L180,103 M171,107 C175,109 179,106 180,103", ink, 1.2); // mouth
  dr.line("M104,44 C108,46 110,50 110,54 M152,44 C155,46 156,50 155,54", ink, 1.2);
  dr.line("M138,200 L138,192 M146,200 L146,192", ink, 1.2);
  dr.eye(146, 74, 4.6, ink);
}

// A plump pup sitting up like the Mar del Plata statues: chest out, thick neck, head raised.
function lobo(dr, ink) {
  const sil =
    "M140,34 C154,30 168,34 176,42 C182,48 180,56 172,58 C168,60 164,62 162,66 " +
    "C170,84 178,104 176,128 C174,148 166,162 160,170 C170,180 182,190 190,198 " +
    "C192,204 184,208 172,206 C162,206 154,204 148,202 C130,208 98,208 80,204 " +
    "C66,202 54,200 44,204 C34,208 20,206 20,200 C24,192 34,188 42,184 " +
    "C30,166 34,140 52,118 C72,92 100,72 118,58 C124,44 130,36 140,34 Z";
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 150, y - 44) < 9) return 0;
    if (ell(x, y, 170, 50, 9, 7) < 1) return 0.1; // pale muzzle
    const f = clamp(ell(x, y, 106, 136, 82, 90));
    let t = 0.8 + 0.2 * f ** 2;
    if (ell(x, y, 160, 116, 14, 42) < 1) t -= 0.3; // lighter chest
    return t;
  }, BODY(106));
  dr.outline(sil, ink);
  dr.line("M160,170 C164,182 170,190 178,197", ink, 1.2); // front flipper edge
  dr.line("M44,186 C40,192 32,196 26,198", ink, 1.2); // rear flipper edge
  dr.line("M124,70 C132,78 138,86 142,98 M116,80 C122,90 126,100 128,112", ink, 1); // folds of the neck
  dr.line("M130,46 C132,48 132,52 130,54", ink, 1.4); // tiny ear
  dr.line("M168,54 L186,50 M168,56 L186,58 M166,58 L182,64", ink, 0.8); // whiskers
  dr.circle(174, 47, 1.8, { fill: ink });
  dr.eye(150, 44, 4.6, ink);
}

// A young condor drying its wings: fingered wing tips, the pale wing patch, the white ruff.
function condor(dr, ink) {
  // Four long primaries, spread like fingers.
  const LEFT = [[94, 100], [66, 84], [38, 84], [14, 96], [6, 110], [24, 112], [10, 126], [28, 126],
    [18, 142], [36, 138], [34, 154], [50, 146], [62, 152], [80, 148], [92, 140]];
  const wing = (pts) => "M" + pts.map(([x, y]) => `${x},${y}`).join(" L") + " Z";
  const SPREAD = LEFT.map(([x, y]) => [Math.round(94 + (x - 94) * 0.9), Math.round(100 + (y - 100) * 0.9)]);
  const WING_L = wing(SPREAD);
  const WING_R = wing(SPREAD.map(([x, y]) => [220 - x, y]).reverse());
  const BODY_SIL = "M112,92 C132,92 142,116 142,142 C142,170 130,190 112,190 C94,190 82,170 82,142 C82,116 92,92 112,92 Z";
  const HEAD = "M106,92 C104,78 110,64 122,61 C132,58 140,62 142,68 C149,68 155,73 155,81 C155,87 151,89 148,86 C148,83 146,81 143,81 C139,87 132,91 124,94 Z";
  const RUFF = loop(60, (t) => {
    const a = t * PI * 2;
    const r = 1 + 0.12 * Math.abs(Math.sin(a * 7));
    return [114 + Math.cos(a) * 22 * r, 94 + Math.sin(a) * 8 * r];
  });
  const patch = (x, y, sx) => {
    const d = Math.hypot(x - sx, y - 100);
    return d > 26 && d < 44 && y < 132;
  };
  for (const [w, sx] of [[WING_R, 126], [WING_L, 94]]) {
    dr.path(w, { fill: PAPER });
    dr.engrave(w, ink, (x, y) => (patch(x, y, sx) ? 0.05 : 0.88), BODY(112));
    dr.outline(w, ink);
  }
  dr.line("M104,186 L102,204 M95,206 L110,206 M120,186 L122,204 M116,206 L131,206", ink, 2.2);
  dr.path(BODY_SIL, { fill: PAPER });
  dr.engrave(BODY_SIL, ink, (x, y) => 0.75 + 0.2 * clamp(ell(x, y, 112, 142, 30, 48)) ** 3, BODY(112));
  dr.outline(BODY_SIL, ink);
  dr.path(HEAD, { fill: PAPER });
  dr.engrave(HEAD, ink, (x, y) => (Math.hypot(x - 127, y - 72) < 7 || x > 144 ? 0 : 0.55), BODY(120, 0.5));
  dr.outline(HEAD, ink);
  dr.path(RUFF, { fill: PAPER, stroke: ink, "stroke-width": 1.3 * dr.L.ow, "stroke-linejoin": "round" });
  dr.line("M144,73 C148,75 152,79 153,84", ink, 1.1); // beak edge
  dr.eye(127, 72, 3.8, ink);
}

function yacare(dr, ink) {
  const sil =
    "M200,140 C202,148 194,154 182,155 C170,156 160,158 152,162 C140,168 128,170 110,170 " +
    "C92,170 74,168 60,164 C46,162 32,156 24,146 C18,138 16,124 20,116 C22,112 27,114 27,118 " +
    "C27,128 36,140 52,142 C70,142 88,132 108,130 C126,128 140,126 152,130 C158,120 170,120 176,126 " +
    "C184,130 196,132 200,140 Z";
  const legs = [
    "M140,160 C146,172 150,180 156,184 C160,188 150,190 144,186 C138,180 132,172 128,164 Z",
    "M80,162 C84,174 86,182 92,186 C96,190 86,192 80,188 C74,182 70,172 68,164 Z",
  ];
  const tone = (x, y) => {
    if (Math.hypot(x - 168, y - 127) < 7) return 0;
    const band = Math.sin((x + 0.35 * (y - 140)) / 6) > 0.72 && x < 150; // hatchling crossbands
    return band ? 0.08 : 0.85;
  };
  for (const leg of legs) {
    dr.path(leg, { fill: PAPER });
    dr.engrave(leg, ink, () => 0.8, BODY(110));
    dr.outline(leg, ink);
  }
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, tone, BODY(110));
  dr.outline(sil, ink);
  dr.line("M152,150 C164,148 180,147 196,145", ink, 1.2); // mouth
  dr.line("M60,140 L64,134 L68,140 M80,136 L84,130 L88,136 M100,132 L104,126 L108,132 M120,130 L124,124 L128,130", ink, 1.4); // scutes
  dr.eye(168, 127, 4.2, ink);
}

function flamenco(dr, ink) {
  const sil =
    "M44,104 C58,98 64,92 78,88 C94,84 116,84 128,92 C136,82 132,68 134,54 C136,40 150,34 160,38 " +
    "C170,42 174,50 172,58 C180,62 188,72 184,86 C182,90 176,88 176,82 C176,76 170,70 162,68 " +
    "C154,70 150,76 150,86 C150,102 152,116 140,130 C128,144 106,150 88,148 C72,146 60,134 56,120 " +
    "C52,114 48,108 44,104 Z";
  dr.line("M98,146 L98,202 M88,205 L108,205", ink, 2.2); // standing leg
  dr.line("M110,146 L126,170 L104,178", ink, 2.2); // folded leg
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 158, y - 50) < 8) return 0;
    if (x > 174 && y > 70) return 0.95; // dark beak tip
    const f = clamp(ell(x, y, 96, 116, 50, 34));
    let t = 0.12 + 0.5 * f ** 3;
    if (ell(x, y, 82, 112, 28, 18) < 1) t += 0.35; // wing
    if (x > 128 && y < 120) t = 0.2 + (x < 142 ? 0.25 : 0); // neck, shaded on its back
    return t;
  }, BODY(96));
  dr.outline(sil, ink);
  dr.line("M172,58 C176,66 178,74 180,84", ink, 1); // beak bend
  dr.eye(158, 50, 4, ink);
}

function guanaco(dr, ink) {
  const sil =
    "M38,108 C38,94 54,88 76,88 C98,88 112,90 122,94 C126,78 132,62 138,52 C138,42 140,32 144,28 " +
    "C147,25 151,28 150,34 C152,38 154,40 157,41 C162,44 168,50 174,57 C178,63 176,69 168,69 " +
    "C160,69 154,67 150,71 C146,83 144,100 140,116 C138,132 128,140 112,142 C90,144 66,144 50,138 " +
    "C42,132 38,122 38,108 Z";
  const legs = ["M54,136 L50,170 L54,204", "M68,140 L68,172 L72,204", "M120,138 L124,170 L122,204", "M132,132 L138,168 L136,202"];
  for (const leg of legs) dr.line(leg, ink, 3.4);
  dr.line("M48,204 L58,204 M66,205 L76,205 M116,205 L126,205 M130,203 L140,203", ink, 2.4); // hooves
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 154, y - 50) < 8) return 0;
    if (y > 118 && x < 132) return 0.08; // pale belly
    if (x > 156 && y > 52) return 0.55; // grey muzzle
    const f = clamp(ell(x, y, 92, 104, 60, 44));
    return 0.68 + 0.3 * f ** 3;
  }, BODY(92));
  dr.outline(sil, ink);
  dr.line("M38,100 C32,104 30,112 34,118", ink, 2.4); // tail
  dr.line("M143,32 C144,38 146,42 150,44", ink, 1); // inner ear
  dr.circle(172, 62, 1.6, { fill: ink });
  dr.eye(154, 50, 4.2, ink);
}

function ballena(dr, ink) {
  const sil =
    "M98,186 C102,160 104,132 104,110 C90,104 62,96 42,80 C34,74 28,66 26,58 C46,58 76,66 96,76 " +
    "C102,79 106,82 110,86 C114,82 118,79 124,76 C144,66 174,56 194,56 C192,64 186,70 180,76 " +
    "C162,94 136,104 118,110 C118,132 122,160 126,186 Z";
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    const f = clamp(ell(x, y, 110, 110, 90, 80));
    let t = 0.55 + 0.35 * f;
    if (y < 82 && Math.abs(x - 110) > 40) t -= 0.25; // light catching the upper edge of the flukes
    return t;
  }, { rays: [110, 300], n: 360, r0: 90, r1: 260, sp: 2.6 });
  dr.outline(sil, ink);
  dr.line("M40,192 C56,186 70,186 84,190 C96,194 110,194 124,190 C140,186 156,186 176,192", ink, 1.6);
  dr.line("M58,202 C74,198 88,198 104,202 M120,202 C134,198 148,198 162,202", ink, 1.3);
  dr.line("M30,66 C28,74 26,80 28,86 M194,62 C196,70 198,76 196,82", ink, 1.2); // water falling
  dr.circle(28, 94, 1.8, { fill: ink });
  dr.circle(196, 90, 1.8, { fill: ink });
}

/** Digit order matches src/animals/animals.gd. */
export const ANIMALS = [
  { id: "yaguarete", ink: "#b07d1c", draw: yaguarete },
  { id: "lobo_marino", ink: "#6b5a4e", draw: lobo },
  { id: "pinguino", ink: "#2f4a5c", draw: pinguino },
  { id: "condor", ink: "#5b3f8c", draw: condor },
  { id: "hornero", ink: "#b5532a", draw: hornero },
  { id: "yacare", ink: "#3d6b4f", draw: yacare },
  { id: "flamenco", ink: "#9c3d6b", draw: flamenco },
  { id: "guanaco", ink: "#7d6b4a", draw: guanaco },
  { id: "ballena", ink: "#2a6a6e", draw: ballena },
];

/** Drawn at full detail; the rest wait for art checkpoint 1. */
export const FULL_APPROVED = ["pinguino", "hornero"];
