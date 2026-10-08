var BROWSER_RES = [
  /firefox/i, /librewolf/i, /floorp/i, /waterfox/i, /mercury/i, /palemoon/i,
  /chrome/i, /chromium/i, /\bhelium\b/i, /\bzen\b/i, /brave/i, /vivaldi/i,
  /edge/i, /opera/i, /qutebrowser/i, /falkon/i, /epiphany/i, /konqueror/i,
  /ladybird/i, /nyxt/i, /seamonkey/i, /dillo/i
];
var BROWSER_NAME_RES = [/browser/i, /firefox/i, /chrome/i, /chromium/i, /\bzen\b/i, /helium/i, /brave/i, /vivaldi/i, /edge/i, /opera/i];

var FILES_RES = [
  /nautilus/i, /dolphin/i, /thunar/i, /nemo/i, /pcmanfm/i, /caja/i,
  /konqueror/i, /krusader/i, /sunflower/i, /doublecmd/i, /spacefm/i,
  /\branger\b/i, /\byazi\b/i, /\blf\b/i, /\bnnn\b/i, /vifm/i
];
var FILES_NAME_RES = [/file manager/i, /^files$/i];

var MAIL_RES = [
  /thunderbird/i, /betterbird/i, /evolution/i, /geary/i, /mailspring/i,
  /kmail/i, /clawsmail/i, /sylpheed/i, /neomutt/i, /\bmutt\b/i, /aerc/i, /alpine/i
];
var MAIL_NAME_RES = [/mail/i, /e-mail/i, /email/i];

var TERM_RES = [
  /kitty/i, /alacritty/i, /\bfoot\b/i, /wezterm/i, /gnome-terminal/i,
  /konsole/i, /xfce4-terminal/i, /tilix/i, /\bxterm\b/i, /\bst\b/i,
  /terminator/i, /terminology/i, /hyper/i, /tabby/i, /prompt/i,
  /console/i, /ptyxis/i, /blackbox/i, /ghostty/i, /\brio\b/i, /cool-retro-term/i
];
var TERM_NAME_RES = [/terminal/i, /console/i];

function matchEntries(entries, res, nameRes) {
  var out = [];
  var seen = {};
  for (var i = 0; i < (entries || []).length; i++) {
    var e = entries[i];
    if (!e || e.noDisplay) continue;
    var id = String(e.id || "");
    var nm = String(e.name || "");
    if (id === "") continue;
    var hit = false;
    for (var r = 0; r < res.length; r++) {
      if (res[r].test(id)) {
        hit = true;
        break;
      }
    }
    if (!hit && nm !== "") {
      for (var q = 0; q < (nameRes || []).length; q++) {
        if (nameRes[q].test(nm)) {
          hit = true;
          break;
        }
      }
    }
    if (!hit) continue;
    if (seen[id]) continue;
    seen[id] = true;
    out.push({ id: id, name: nm !== "" ? nm : id.replace(/\.desktop$/, "") });
  }
  out.sort(function(a, b) {
    var x = a.name.toLowerCase();
    var y = b.name.toLowerCase();
    return x < y ? -1 : (x > y ? 1 : 0);
  });
  return out;
}

function displayName(id, byId) {
  if (!id) return "";
  var e = byId ? byId[id] : null;
  if (e && e.name) return String(e.name);
  return String(id).replace(/\.desktop$/, "");
}

function nextId(currentId, candidates) {
  if (!candidates || candidates.length === 0) return null;
  var idx = candidates.indexOf(currentId);
  return candidates[(idx + 1) % candidates.length];
}

function parseMimeapps(text) {
  var out = {};
  var lines = String(text || "").split("\n");
  var inDefaults = false;
  for (var i = 0; i < lines.length; i++) {
    var t = lines[i].trim();
    if (t === "") continue;
    if (t.charAt(0) === "[") {
      inDefaults = (t === "[Default Applications]");
      continue;
    }
    if (!inDefaults) continue;
    if (t.charAt(0) === "#" || t.charAt(0) === ";") continue;
    var eq = lines[i].indexOf("=");
    if (eq < 0) continue;
    var key = lines[i].slice(0, eq).trim();
    var val = lines[i].slice(eq + 1).split(";")[0].trim();
    if (key !== "" && val !== "" && !(key in out)) out[key] = val;
  }
  return out;
}

function serializeMimeapps(curText, updates) {
  var text = String(curText || "");
  var lines = text === "" ? [] : text.split("\n");
  var keys = [];
  for (var k in updates) {
    if (Object.prototype.hasOwnProperty.call(updates, k)) keys.push(k);
  }
  var headerIdx = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() === "[Default Applications]") {
      headerIdx = i;
      break;
    }
  }
  if (headerIdx < 0) {
    if (lines.length > 0 && lines[lines.length - 1].trim() !== "") lines.push("");
    lines.push("[Default Applications]");
    for (var a = 0; a < keys.length; a++) lines.push(keys[a] + "=" + updates[keys[a]] + ";");
    lines.push("");
    return lines.join("\n");
  }
  var seen = {};
  var j = headerIdx + 1;
  for (; j < lines.length; j++) {
    var t = lines[j].trim();
    if (t !== "" && t.charAt(0) === "[") break;
    if (t === "" || t.charAt(0) === "#" || t.charAt(0) === ";") continue;
    var eq = lines[j].indexOf("=");
    if (eq < 0) continue;
    var key = lines[j].slice(0, eq).trim();
    for (var u = 0; u < keys.length; u++) {
      if (keys[u] === key && !seen[key]) {
        lines[j] = key + "=" + updates[key] + ";";
        seen[key] = true;
      }
    }
  }
  var missing = [];
  for (var m = 0; m < keys.length; m++) {
    if (!seen[keys[m]]) missing.push(keys[m] + "=" + updates[keys[m]] + ";");
  }
  if (missing.length > 0) {
    var insertAt = j;
    var merged = lines.slice(0, insertAt).concat(missing).concat(lines.slice(insertAt));
    lines = merged;
  }
  return lines.join("\n").replace(/\n*$/, "\n");
}

function binFromExec(exec) {
  var parts = String(exec || "").trim().split(/\s+/);
  for (var i = 0; i < parts.length; i++) {
    var tok = parts[i].replace(/^["']|["']$/g, "");
    if (tok === "" || tok === "env" || tok.indexOf("=") >= 0 || tok.charAt(0) === "%") continue;
    var slash = tok.lastIndexOf("/");
    var bin = slash >= 0 ? tok.slice(slash + 1) : tok;
    return bin.replace(/%[A-Za-z]/g, "");
  }
  return "";
}

function termCmdForBin(bin) {
  if (bin === "foot") return ["foot"];
  if (bin === "wezterm") return ["wezterm", "start", "--"];
  if (bin === "gnome-terminal") return ["gnome-terminal", "--"];
  if (bin === "xdg-terminal-exec") return ["xdg-terminal-exec"];
  return [bin, "-e"];
}
