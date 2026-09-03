#!/usr/bin/env python3
"""String Catalog batch translation helper for weddingplanner/Localizable.xcstrings.

Subcommands
  langs                          -> print the target language set
  export  <outdir> [--size N] [--langs a,b] [--only-missing]
                                 -> per-language batch JSON files with untranslated keys
  merge   <indir>  [--langs a,b] -> validate + merge translated batches into the catalog
  report  [--langs a,b]          -> per-language translated/total coverage + English-clone count

Validation on merge (a batch that fails is REJECTED whole, nothing is written for it):
  * JSON well-formed, every requested key present, value a non-empty string
  * FORMAT-SPECIFIER PARITY: multiset of %@ / %lld / %d / %f / %1$@ ... must match the
    English source exactly (a mismatch is a String(format:) crash at runtime)
  * plural entries carry exactly the CLDR categories the language requires
  * English-clone check (soft, reported): value identical to the source and not whitelisted
"""
import json, os, re, sys, argparse, unicodedata

CAT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "weddingplanner", "Localizable.xcstrings")

# studio 30-language standard, with zh expanded into the two scripts the ASC listing declares
TARGETS = ["ar","cs","da","de","es","et","fi","fr","hr","hu","is","it","ja","ko","lv","nb",
           "nl","pl","pt","ro","ru","sk","sl","sv","th","tr","uk","vi","zh-Hans","zh-Hant"]

CLDR = {
    "ar": ["zero","one","two","few","many","other"],
    "cs": ["one","few","many","other"], "sk": ["one","few","many","other"],
    "pl": ["one","few","many","other"], "ru": ["one","few","many","other"],
    "uk": ["one","few","many","other"],
    "hr": ["one","few","other"], "ro": ["one","few","other"],
    "sl": ["one","two","few","other"], "lv": ["zero","one","other"],
    "ja": ["other"], "ko": ["other"], "th": ["other"], "vi": ["other"],
    "zh-Hans": ["other"], "zh-Hant": ["other"],
}
def cldr(lang): return CLDR.get(lang, ["one","other"])

# %[positional$][width][.prec][length]conv — no flag class on purpose (literal '%' in UI copy)
SPEC = re.compile(r'%(?:(\d+)\$)?\d*(?:\.\d+)?(ll|l|hh|h|q|z|j|t|L)?([@diouxXeEfFgG])')
def specs(s):
    if not s: return []
    return [(m.group(1), (m.group(2) or "") + m.group(3)) for m in SPEC.finditer(s.replace("%%", ""))]
def argmap(s):
    """Map argument index -> conversion type for a format string.

    Non-positional specifiers consume args left to right, so ORDER matters.
    Positional (%1$@) specifiers may reorder freely, which is exactly how a
    translation legally moves arguments around. Mixing the two forms is
    undefined behaviour in CFString formatting -> we reject it.
    Returns (dict {index: type}, error|None).
    """
    sp = specs(s)
    if not sp:
        return {}, None
    pos = [p for p, _ in sp]
    if all(pos):
        m = {}
        for p, t in sp:
            i = int(p)
            if i in m and m[i] != t:
                return {}, f"positional %{i}$ used with two types ({m[i]}/{t})"
            m[i] = t
        if sorted(m) != list(range(1, len(m) + 1)):
            return {}, f"positional indices not 1..n: {sorted(m)}"
        return m, None
    if any(pos):
        return {}, "mixes positional and non-positional specifiers"
    return {i + 1: t for i, (_, t) in enumerate(sp)}, None


def skel(s):
    m, err = argmap(s)
    return ("ERR:" + err) if err else tuple(sorted(m.items()))

# Keys that legitimately stay identical in every language: symbols, numbers, sample data,
# URLs, brand names, currency-formatted samples, single glyphs.
CLONE_OK = re.compile(r'^[\W\d\s]*$|^https?://|^(BridePlan|VIP|OK|Premium|Pro|Anna Lee|David Wilson|'
                      r'John & Sarah|Kate Lewis|Mike Roberts|Paul Taylor|AL|DW|JS|KL|MR|PT|Email|E-Mail|'
                      r'Instagram|Pinterest|PDF|CSV|RSVP|DJ|SMS|iCloud|Apple|Face ID|Touch ID)$', re.I)

def has_words(k):
    """True if the key still contains real words once format specifiers are stripped."""
    return bool(re.search(r'[A-Za-z]{2,}', SPEC.sub(' ', k.replace('%%', ' '))))

def load():
    with open(CAT, encoding="utf-8") as f: return json.load(f)

def save(cat):
    tmp = CAT + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cat, f, ensure_ascii=False, indent=2, sort_keys=True, separators=(",", " : "))
        f.write("\n")
    os.replace(tmp, CAT)

def translatable(cat):
    """Source keys that are real UI text and must be translated."""
    out = {}
    for k, e in cat["strings"].items():
        if not k.strip():                       continue
        if e.get("shouldTranslate") is False:   continue
        if CLONE_OK.match(k):                   continue   # symbols/numbers/sample data/URLs
        if not has_words(k):                    continue   # pure format strings: '$%lld', '+%lld'
        out[k] = e
    return out

def is_plural(entry):
    for u in (entry.get("localizations") or {}).values():
        if "variations" in u: return True
    return False

def src_plural(entry):
    en = (entry.get("localizations") or {}).get("en", {})
    v = (en.get("variations") or {}).get("plural", {})
    return {c: b["stringUnit"]["value"] for c, b in v.items()}

def done(entry, lang):
    loc = (entry.get("localizations") or {}).get(lang)
    if not loc: return False
    if "variations" in loc:
        cats = (loc["variations"].get("plural") or {})
        return bool(cats) and all((b.get("stringUnit") or {}).get("value", "").strip() for b in cats.values())
    su = loc.get("stringUnit") or {}
    return bool(su.get("value", "").strip()) and su.get("state") == "translated"

def cmd_export(a):
    cat = load(); tr = translatable(cat)
    os.makedirs(a.outdir, exist_ok=True)
    total = 0
    for lang in (a.langs or TARGETS):
        pending = [k for k, e in tr.items() if not (a.only_missing and done(e, lang)) and not done(e, lang)] \
                  if a.only_missing else [k for k, e in tr.items() if not done(e, lang)]
        for i in range(0, len(pending), a.size):
            chunk = pending[i:i + a.size]
            body = {}
            for k in chunk:
                e = tr[k]
                body[k] = {"plural": cldr(lang), "source": src_plural(e)} if is_plural(e) else ""
            p = os.path.join(a.outdir, f"{lang}__{i//a.size + 1:02d}.json")
            with open(p, "w", encoding="utf-8") as f:
                json.dump({"language": lang, "strings": body}, f, ensure_ascii=False, indent=1)
            total += len(chunk)
        print(f"{lang:8} pending={len(pending):5} batches={(len(pending)+a.size-1)//a.size}")
    print(f"TOTAL cells exported: {total}")

def validate(cat, lang, data):
    """-> (ok_dict, errors). ok_dict maps key -> value(str) or {'plural': {...}}"""
    tr = translatable(cat); ok = {}; err = []
    for k, v in data.get("strings", {}).items():
        if k not in tr: err.append(f"unknown key {k!r}"); continue
        e = tr[k]
        if is_plural(e):
            cats = v.get("plural") if isinstance(v, dict) else None
            if not isinstance(cats, dict): err.append(f"{k!r}: plural object required"); continue
            need = set(cldr(lang))
            if set(cats) != need:
                err.append(f"{k!r}: plural cats {sorted(cats)} != CLDR {sorted(need)}"); continue
            bad = False
            for c, val in cats.items():
                if not isinstance(val, str) or not val.strip(): err.append(f"{k!r}[{c}]: empty"); bad = True; break
                if skel(val) != skel(k): err.append(f"{k!r}[{c}]: fmt {specs(val)} != src {specs(k)}"); bad = True; break
            if not bad: ok[k] = {"plural": cats}
        else:
            if not isinstance(v, str) or not v.strip(): err.append(f"{k!r}: empty/non-string"); continue
            if skel(v) != skel(k): err.append(f"{k!r}: fmt {specs(v)} != src {specs(k)} -> CRASH RISK"); continue
            ok[k] = v
    return ok, err

def cmd_merge(a):
    cat = load(); files = sorted(f for f in os.listdir(a.indir) if f.endswith(".json"))
    wrote = 0; rejected = []
    for fn in files:
        lang = fn.split("__")[0]
        if a.langs and lang not in a.langs: continue
        p = os.path.join(a.indir, fn)
        try:
            with open(p, encoding="utf-8") as f: data = json.load(f)
        except Exception as ex:
            rejected.append(f"{fn}: BAD JSON {ex}"); continue
        if data.get("language") != lang:
            rejected.append(f"{fn}: language field {data.get('language')!r} != {lang}"); continue
        ok, err = validate(cat, lang, data)
        if err:
            rejected.append(f"{fn}: {len(err)} error(s) -> {err[:3]}"); continue
        for k, v in ok.items():
            e = cat["strings"][k]
            locs = e.setdefault("localizations", {})
            if isinstance(v, dict):
                locs[lang] = {"variations": {"plural": {c: {"stringUnit": {"state": "translated", "value": s}}
                                                        for c, s in v["plural"].items()}}}
            else:
                locs[lang] = {"stringUnit": {"state": "translated", "value": v}}
            wrote += 1
    save(cat)
    print(f"merged cells: {wrote}   files ok: {len(files)-len(rejected)}   rejected: {len(rejected)}")
    for r in rejected: print("  REJECT", r)
    return 1 if rejected else 0

def cmd_report(a):
    cat = load(); tr = translatable(cat)
    langs = a.langs or TARGETS
    print(f"{'lang':9} {'translated':>10} {'total':>6} {'missing':>8} {'en-clone':>9}  status")
    bad = 0
    for lang in langs:
        d = c = 0; clones = []
        for k, e in tr.items():
            if done(e, lang):
                d += 1
                loc = e["localizations"][lang]
                if "stringUnit" in loc and loc["stringUnit"]["value"] == k and not CLONE_OK.match(k):
                    clones.append(k)
        c = len(clones)
        rate = c / max(1, len(tr))
        # missing is a hard fail; clones are a hard fail only above 5% (a lazy agent that
        # echoed English), below that they are genuine cognates (Budget/Florist/Halal/"%lld h").
        st = "OK" if d == len(tr) and rate <= 0.05 else "FAIL"
        if st == "FAIL": bad += 1
        print(f"{lang:9} {d:>10} {len(tr):>6} {len(tr)-d:>8} {c:>9}  {st}"
              + (f"  (clone rate {rate:.1%})" if c else ""))
        if a.show_clones and clones: print(f"          clones: {clones}")
    print("\n" + ("ALL_OK" if bad == 0 else f"HAS_FAILURES ({bad} langs)"))
    return 1 if bad else 0

if __name__ == "__main__":
    ap = argparse.ArgumentParser(); sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("langs")
    e = sub.add_parser("export"); e.add_argument("outdir"); e.add_argument("--size", type=int, default=190)
    e.add_argument("--langs", type=lambda s: s.split(",")); e.add_argument("--only-missing", action="store_true")
    m = sub.add_parser("merge"); m.add_argument("indir"); m.add_argument("--langs", type=lambda s: s.split(","))
    r = sub.add_parser("report"); r.add_argument("--langs", type=lambda s: s.split(",")); r.add_argument("--show-clones", action="store_true")
    a = ap.parse_args()
    if a.cmd == "langs":  print(" ".join(TARGETS)); sys.exit(0)
    sys.exit({"export": cmd_export, "merge": cmd_merge, "report": cmd_report}[a.cmd](a) or 0)
