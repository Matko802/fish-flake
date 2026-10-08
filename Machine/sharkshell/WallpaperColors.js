function wcClean(C, list) {
  var out = [];
  var arr = list || [];
  for (var i = 0; i < arr.length; i++) {
    var v = String(arr[i] || "").trim().toLowerCase();
    if (!C.isValid(v)) continue;
    if (v.charAt(0) !== "#") v = "#" + v;
    if (out.indexOf(v) < 0) out.push(v);
  }
  return out;
}

function wcRole(roles, C, name) {
  if (!roles) return null;
  var v = roles[name];
  if (typeof v !== "string") return null;
  v = v.trim().toLowerCase();
  if (!C.isValid(v)) return null;
  if (v.charAt(0) !== "#") v = "#" + v;
  return v;
}

function wcPoolAdd(C, pool, hex) {
  var v = String(hex || "").trim().toLowerCase();
  if (!C.isValid(v)) return;
  if (v.charAt(0) !== "#") v = "#" + v;
  if (pool.indexOf(v) < 0) pool.push(v);
}

function wcMaxSat(C, pool) {
  var m = 0;
  for (var i = 0; i < pool.length; i++) {
    var hsl = C.toHsl(pool[i]);
    if (hsl && hsl.s > m) m = hsl.s;
  }
  return m;
}

function wcFit(C, hex, bg, ratio, dark) {
  if (dark) return C.ensureContrastOnDark(hex, bg, ratio);
  return C.ensureContrastOnLight(hex, bg, ratio);
}

function wcPickHueFrom(C, pool, targetHue, usedHues) {
  var cands = [];
  for (var i = 0; i < pool.length; i++) {
    var hsl = C.toHsl(pool[i]);
    if (!hsl || hsl.s < 0.12) continue;
    var ok = true;
    for (var u = 0; u < usedHues.length; u++) {
      if (C.hueDist(hsl.h * 360, usedHues[u]) < 40) {
        ok = false;
        break;
      }
    }
    if (ok) cands.push(pool[i]);
  }
  if (cands.length === 0) return null;
  var best = null;
  var bestScore = 1e9;
  for (var pass = 0; pass < 3; pass++) {
    best = null;
    bestScore = 1e9;
    for (var j = 0; j < cands.length; j++) {
      var ch = C.toHsl(cands[j]);
      if (!ch) continue;
      if (pass === 0) {
        if (ch.s < 0.12 || ch.l < 0.18 || ch.l > 0.90) continue;
      } else if (pass === 1) {
        if (ch.l < 0.10 || ch.l > 0.92) continue;
      }
      var d = C.hueDist(ch.h * 360, targetHue);
      var mid = (ch.l >= 0.25 && ch.l <= 0.75) ? 12 : 0;
      var score = d - ch.s * 15 - mid;
      if (score < bestScore) {
        bestScore = score;
        best = String(cands[j]);
      }
    }
    if (best) break;
  }
  if (!best) return null;
  if (C.hueDist(C.hueDeg(best), targetHue) > 65) return null;
  return best;
}

function wcPickHue(C, wall, rest, targetHue, usedHues) {
  var c = wcPickHueFrom(C, wall, targetHue, usedHues);
  if (c) return c;
  return wcPickHueFrom(C, rest, targetHue, usedHues);
}

function wcPickGrey(C, pool, targetL) {
  var best = null;
  var bestScore = 1e9;
  var p;
  for (p = 0; p < pool.length; p++) {
    var hsl = C.toHsl(pool[p]);
    if (!hsl || hsl.s > 0.15) continue;
    var score = Math.abs(hsl.l - targetL);
    if (score < bestScore) {
      bestScore = score;
      best = String(pool[p]);
    }
  }
  if (best) return best;
  for (p = 0; p < pool.length; p++) {
    var h2 = C.toHsl(pool[p]);
    if (!h2) continue;
    var s2 = Math.abs(h2.l - targetL) * 2 + h2.s;
    if (s2 < bestScore) {
      bestScore = s2;
      best = String(pool[p]);
    }
  }
  return best;
}

function wcSortedByLum(C, pool) {
  var a = pool.slice();
  a.sort(function(x, y) { return C.luminance(x) - C.luminance(y); });
  return a;
}

function wcCollides(C, a, b) {
  var ha = C.toHsl(a);
  var hb = C.toHsl(b);
  if (!ha || !hb) return false;
  return C.hueDist(ha.h * 360, hb.h * 360) < 28 && Math.abs(ha.l - hb.l) < 0.07;
}

function wcNudge(C, hex, dark, amount, awayL) {
  var hsl = C.toHsl(hex);
  if (!hsl) return String(hex);
  var dir;
  if (awayL === undefined || awayL === null) {
    dir = dark ? 1 : -1;
  } else {
    dir = hsl.l >= awayL ? 1 : -1;
  }
  var l = hsl.l + dir * amount;
  if (l > 0.95 || l < 0.05) l = hsl.l - dir * amount;
  l = Math.min(0.95, Math.max(0.05, l));
  return C.fromHsl(hsl.h, hsl.s, l);
}

function wcFitsTarget(C, hex, bg, ratio) {
  return C.contrastRatio(hex, bg) >= ratio - 0.05;
}

function wcFreeOf2(C, hex, fixed, hueTol, gapTol) {
  var h = C.toHsl(hex);
  if (!h) return false;
  for (var k = 0; k < fixed.length; k++) {
    var f = C.toHsl(fixed[k]);
    if (!f) continue;
    if (C.hueDist(h.h * 360, f.h * 360) < hueTol && Math.abs(h.l - f.l) < gapTol) return false;
  }
  return true;
}

function wcFreeOf(C, hex, fixed) {
  return wcFreeOf2(C, hex, fixed, 28, 0.07);
}

function wcPlaceGreys(C, pool, count, target, anchors, bg) {
  var picked = [];
  var used = {};
  for (var n = 0; n < count; n++) {
    var best = null;
    var bestScore = -1;
    for (var p = 0; p < pool.length; p++) {
      if (used[pool[p]]) continue;
      var hsl = C.toHsl(pool[p]);
      if (!hsl || hsl.s > 0.15) continue;
      if (!wcFitsTarget(C, pool[p], bg, target)) continue;
      var score = wcMinGap(C, pool[p], anchors.concat(picked));
      if (score > bestScore) {
        bestScore = score;
        best = String(pool[p]);
      }
    }
    if (!best) {
      var mr = 0.5 + (n % 2 === 0 ? 1 : -1) * 0.07 * Math.ceil(n / 2);
      mr = Math.min(0.85, Math.max(0.15, mr));
      best = C.mix(bg, "#808080", mr);
      var guard = 0;
      while (used[best] && guard < 10) {
        mr = Math.min(0.9, Math.max(0.1, mr + 0.05));
        best = C.mix(bg, "#808080", mr);
        guard++;
      }
    }
    used[best] = true;
    picked.push(best);
  }
  return picked;
}

function wcMinGap(C, hex, obstacles) {
  var h = C.toHsl(hex);
  if (!h) return 0;
  var m = 1.0;
  for (var k = 0; k < obstacles.length; k++) {
    var f = C.toHsl(obstacles[k]);
    if (!f) continue;
    if (C.hueDist(h.h * 360, f.h * 360) >= 28) continue;
    var g = Math.abs(h.l - f.l);
    if (g < m) m = g;
  }
  return m;
}

function wcDodgeItem(C, hex, target, obstacles, bg, dark) {
  if (!wcFitsTarget(C, hex, bg, target)) return hex;
  var cur = C.toHsl(hex);
  if (!cur) return hex;
  var best = hex;
  var bestScore = wcMinGap(C, hex, obstacles);
  if (bestScore >= 0.07) return hex;
  var dirs = dark ? [0.07, -0.07] : [-0.07, 0.07];
  for (var d = 0; d < dirs.length; d++) {
    var l = cur.l + dirs[d];
    if (l > 0.95 || l < 0.05) continue;
    var cand = C.fromHsl(cur.h, cur.s, l);
    if (!wcFitsTarget(C, cand, bg, target)) continue;
    var score = wcMinGap(C, cand, obstacles);
    if (score > bestScore + 0.005) {
      bestScore = score;
      best = cand;
    }
  }
  return best;
}

function wcSolveBright(C, normHex, norms, ownIdx, earlier, fixed, brightWhite, bg, dark, bt) {
  var h = C.toHsl(normHex);
  if (!h) return String(normHex);
  var occupied = fixed.slice();
  occupied.push(brightWhite);
  for (var n = 0; n < norms.length; n++) {
    if (n !== ownIdx) occupied.push(norms[n]);
  }
  occupied = occupied.concat(earlier);
  var s = dark ? 1 : -1;
  var offs = [0.14 * s, 0.10 * s, -0.14 * s, 0.07 * s, -0.07 * s, 0.18 * s, -0.18 * s,
              0.22 * s, -0.22 * s, 0.26 * s, -0.26 * s, 0.30 * s, -0.30 * s];
  var rescue = null;
  var rescueGap = -1;
  function consider(hex) {
    var hh = C.toHsl(hex);
    if (!hh) return false;
    if (Math.abs(hh.l - h.l) < 0.07 && hh.s - h.s < 0.18) return false;
    if (!wcFitsTarget(C, hex, bg, bt)) return false;
    var g = wcMinGap(C, hex, occupied);
    if (g > rescueGap) {
      rescueGap = g;
      rescue = hex;
    }
    return g >= 0.04;
  }
  for (var o = 0; o < offs.length; o++) {
    var bl = Math.min(0.95, Math.max(0.05, h.l + offs[o]));
    if (Math.abs(bl - h.l) < 0.07) continue;
    var cand = C.fromHsl(h.h, h.s, bl);
    if (!wcFitsTarget(C, cand, bg, bt)) continue;
    if (!wcFreeOf2(C, cand, occupied, 28, 0.07)) {
      consider(cand);
      continue;
    }
    return cand;
  }
  for (var r = 0; r < offs.length; r++) {
    var bl2 = Math.min(0.95, Math.max(0.05, h.l + offs[r]));
    if (Math.abs(bl2 - h.l) < 0.07) continue;
    var cand2 = C.fromHsl(h.h, h.s, bl2);
    if (!wcFitsTarget(C, cand2, bg, bt)) continue;
    if (!wcFreeOf2(C, cand2, occupied, 20, 0.04)) {
      consider(cand2);
      continue;
    }
    return cand2;
  }
  var ns = C.toHsl(normHex);
  if (ns && ns.s >= 0.02 && ns.s < 0.25) {
    var rots = [0.11, -0.11, 0.19, -0.19];
    for (var t = 0; t < rots.length; t++) {
      var rh = ns.h + rots[t];
      rh = rh - Math.floor(rh);
      var rcand = C.fromHsl(rh, ns.s, h.l);
      if (!wcFitsTarget(C, rcand, bg, bt)) continue;
      if (!wcFreeOf2(C, rcand, occupied, 28, 0.035)) continue;
      var rg = wcMinGap(C, rcand, occupied);
      if (rg > rescueGap) {
        rescueGap = rg;
        rescue = rcand;
      }
      if (C.hueDist(rh * 360, h.h * 360) >= 35) return rcand;
    }
  }
  if (ns && ns.s < 0.25) {
    var fb = wcFit(C, wcNudge(C, normHex, dark, 0.10), bg, Math.max(3.0, bt - 0.5), dark);
    if (consider(fb)) return fb;
  } else {
    var fb2 = wcFit(C, C.saturate(normHex, 0.5), bg, Math.max(4.0, bt - 1.0), dark);
    if (consider(fb2)) return fb2;
  }
  if (rescue && rescueGap >= 0.035) return rescue;
  if (ns && ns.s < 0.25) {
    return wcFit(C, wcNudge(C, normHex, dark, 0.10), bg, Math.max(3.0, bt - 0.5), dark);
  }
  return wcFit(C, C.saturate(normHex, 0.5), bg, Math.max(4.0, bt - 1.0), dark);
}

function buildTerminalTheme(C, wallColors, roles, palettes, darkMode) {
  var dark = !!darkMode;
  var wc = wcClean(C, wallColors);
  var pool = wc.slice();
  if (roles) {
    for (var rk in roles) {
      if (Object.prototype.hasOwnProperty.call(roles, rk)) wcPoolAdd(C, pool, roles[rk]);
    }
  }
  if (palettes) {
    for (var pn in palettes) {
      if (!Object.prototype.hasOwnProperty.call(palettes, pn)) continue;
      var lv = palettes[pn];
      for (var lk in lv) {
        if (Object.prototype.hasOwnProperty.call(lv, lk)) wcPoolAdd(C, pool, lv[lk]);
      }
    }
  }

  var bg = wcRole(roles, C, "background") || (dark ? "#000000" : "#ffffff");
  var fg = wcRole(roles, C, "on_surface") || (dark ? "#ffffff" : "#000000");
  var mono = wc.length > 0 ? wcMaxSat(C, wc) < 0.10 : wcMaxSat(C, pool) < 0.10;

  function wcNeutral(C, hex) {
    var hsl = C.toHsl(hex);
    if (!hsl) return String(hex);
    return C.fromHsl(0, 0, hsl.l);
  }

  var black = C.pickDarkest(pool.concat([bg, "#000000"])) || "#000000";
  var brightWhite = dark ? "#ffffff" : "#000000";

  var norm = [];
  var steps14 = [];
  var grey = dark ? "#767676" : "#555555";
  var white = dark ? "#e8e8e8" : "#1a1a1a";
  var targets = [0, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 7.0, 3.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 0];
  if (mono) {
    var loL = C.lightnessOf(black);
    var hiL = 0.96;
    for (var s = 0; s < 14; s++) {
      steps14.push(C.fromHsl(0, 0, loL + (hiL - loL) * ((s + 1) / 15)));
    }
    grey = steps14[6];
    white = steps14[12];
    brightWhite = dark ? "#ffffff" : "#000000";
  } else {
    var usedHues = [];
    var got = {};
    var need = [["red", 0], ["green", 120], ["blue", 215], ["yellow", 55], ["magenta", 300], ["cyan", 185]];
    var rest = [];
    for (var ri = 0; ri < pool.length; ri++) {
      if (wc.indexOf(pool[ri]) < 0) rest.push(pool[ri]);
    }
    for (var h = 0; h < need.length; h++) {
      var gc = wcPickHue(C, wc, rest, need[h][1], usedHues);
      got[need[h][0]] = gc;
      if (gc) usedHues.push(C.hueDeg(gc));
    }
    var bases = [got.red, got.green, got.yellow, got.blue, got.magenta, got.cyan];
    var fillIdx = [];
    var b;
    for (b = 0; b < bases.length; b++) {
      if (!bases[b]) fillIdx.push(b);
    }
    var whiteBase = wcPickGrey(C, pool, dark ? 0.88 : 0.14) || fg;
    white = wcFit(C, whiteBase, bg, 7.0, dark);
    var anchors = [bg, fg, white, black, brightWhite];
    for (var c = 0; c < 6; c++) {
      if (fillIdx.indexOf(c) < 0) anchors.push(wcFit(C, bases[c], bg, 4.5, dark));
    }
  var greyPick = wcPlaceGreys(C, pool, 1, 3.5, anchors, bg);
  var gh = C.toHsl(greyPick[0]);
  if (!gh || gh.l < 0.30 || gh.l > 0.58) {
    var alt = null;
    var altScore = -1;
    for (var gp = 0; gp < pool.length; gp++) {
      var ghsl = C.toHsl(pool[gp]);
      if (!ghsl || ghsl.s > 0.15 || ghsl.l < 0.30 || ghsl.l > 0.58) continue;
      var gs = wcMinGap(C, pool[gp], anchors);
      if (gs > altScore) {
        altScore = gs;
        alt = String(pool[gp]);
      }
    }
    if (alt) greyPick = [alt];
  }
  grey = wcFit(C, greyPick[0], bg, 3.5, dark);
    anchors.push(grey);
    for (var f = 0; f < fillIdx.length; f++) {
      var placed = wcPlaceGreys(C, pool, 1, 4.5, anchors, bg);
      bases[fillIdx[f]] = placed[0];
      anchors.push(placed[0]);
    }
    for (var o = 0; o < 6; o++) {
      norm.push(wcFit(C, bases[o], bg, 4.5, dark));
    }
  }

  var ansi;
  if (mono) {
    ansi = [black, steps14[0], steps14[1], steps14[2], steps14[3], steps14[4], steps14[5],
            steps14[12], steps14[6],
            steps14[7], steps14[8], steps14[9], steps14[10], steps14[11], steps14[13], brightWhite];
    for (var d1 = 0; d1 < ansi.length; d1++) {
      for (var d2 = d1 + 1; d2 < ansi.length; d2++) {
        if (ansi[d1] === ansi[d2]) ansi[d2] = wcNudge(C, ansi[d2], dark, 0.03);
      }
    }
  } else {
    var obstacles = [bg, fg, white, black, brightWhite];
    for (var c = 0; c < 6; c++) {
      if (fillIdx.indexOf(c) < 0) obstacles.push(norm[c]);
    }
    for (var g = 0; g < fillIdx.length; g++) {
      var gi = fillIdx[g];
      norm[gi] = wcDodgeItem(C, norm[gi], 4.5, obstacles, bg, dark);
      obstacles.push(norm[gi]);
    }
    grey = wcDodgeItem(C, grey, 3.5, obstacles, bg, dark);
    var low = [black].concat(norm).concat([white, grey]);
    var brt = [];
    for (var q = 0; q < 6; q++) {
      var nsh = C.toHsl(low[1 + q]);
      var bTarget = (nsh && nsh.s < 0.2) ? 3.5 : 5.5;
      brt.push(wcSolveBright(C, low[1 + q], low.slice(1, 9), q, brt, [bg, fg], brightWhite, bg, dark, bTarget));
    }
    ansi = low.concat(brt).concat([brightWhite]);
  }

  var primary = wcRole(roles, C, "primary") || fg;
  var onPrimary = wcRole(roles, C, "on_primary") || bg;
  var primaryContainer = wcRole(roles, C, "primary_container") || primary;
  var onPrimaryContainer = wcRole(roles, C, "on_primary_container") || onPrimary;
  var surface = wcRole(roles, C, "surface") || bg;
  var onSurfVar = wcRole(roles, C, "on_surface_variant") || grey;
  var invSurf = wcRole(roles, C, "inverse_surface") || fg;
  var invOnSurf = wcRole(roles, C, "inverse_on_surface") || bg;

  var bgN = mono ? wcNeutral(C, bg) : bg;
  var fgN = mono ? wcNeutral(C, fg) : fg;

  return {
    source: "wallpaper-only colors",
    background: bgN,
    foreground: fgN,
    cursor: mono ? fgN : primary,
    selBg: mono ? grey : primaryContainer,
    selFg: mono ? bgN : onPrimaryContainer,
    ansi: ansi,
    tabActiveFg: mono ? bgN : invOnSurf,
    tabActiveBg: mono ? fgN : primary,
    tabInactiveFg: mono ? grey : onSurfVar,
    tabInactiveBg: mono ? bgN : surface
  };
}

function wcContrastFg(C, bgHex) {
  return C.luminance(bgHex) < 0.45 ? "#ffffff" : "#000000";
}

function wcMix3(C, a, b, t) {
  if (typeof C.mix === "function") return String(C.mix(a, b, t));
  var ca = C.toRgb(a);
  var cb = C.toRgb(b);
  if (!ca) return String(b);
  if (!cb) return String(a);
  function hx(v) {
    var h = Math.round(Math.min(255, Math.max(0, v))).toString(16);
    return h.length < 2 ? "0" + h : h;
  }
  return "#" + hx(ca.r + (cb.r - ca.r) * t) + hx(ca.g + (cb.g - ca.g) * t) + hx(ca.b + (cb.b - ca.b) * t);
}

function buildCustomRoles(C, bg, fg, accent, dark) {
  var B = C.isValid(bg) ? String(bg).toLowerCase() : (dark ? "#000000" : "#ededed");
  var F = C.isValid(fg) ? String(fg).toLowerCase() : wcContrastFg(C, B);
  var A = C.isValid(accent) ? String(accent).toLowerCase() : "#3daee9";
  if (B.charAt(0) !== "#") B = "#" + B;
  if (F.charAt(0) !== "#") F = "#" + F;
  if (A.charAt(0) !== "#") A = "#" + A;
  var onA = wcContrastFg(C, A);
  var cont = wcMix3(C, A, B, 0.55);
  var onCont = wcContrastFg(C, cont);
  var map = {
    background: B,
    on_background: F,
    surface: wcMix3(C, B, F, 0.05),
    surface_container: wcMix3(C, B, F, 0.16),
    surface_container_low: wcMix3(C, B, F, 0.10),
    surface_container_high: wcMix3(C, B, F, 0.24),
    surface_container_highest: wcMix3(C, B, F, 0.32),
    surface_container_lowest: B,
    on_surface: F,
    on_surface_variant: wcMix3(C, F, B, 0.35),
    primary: A,
    on_primary: onA,
    primary_container: cont,
    on_primary_container: onCont,
    secondary: A,
    tertiary: A,
    error: dark ? "#ffb4ab" : "#ba1a1a",
    on_error: dark ? "#690005" : "#ffffff",
    inverse_surface: F,
    inverse_on_surface: B
  };
  return map;
}

function customLightPair(C, bg, accent) {
  var lb = wcMix3(C, bg, "#ffffff", 0.88);
  var la = wcMix3(C, accent, "#000000", 0.18);
  return { bg: lb, fg: "#202020", accent: la };
}
