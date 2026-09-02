/* Glossify — a topic-agnostic engine that links glossary terms in lesson prose
   to the workspace glossary (reference/glossary.html), with a hover/focus tooltip.

   It carries NO term data of its own. The term bank is supplied by a sibling
   reference/glossary-terms.js, which sets `self.GLOSSIFY_TERMS` to an array of
   { term, id, gloss } — so this file is copied verbatim into every teaching
   workspace and only the data file changes per topic.

   Runs in the browser (<script defer>) and is also require()-able in Node for
   unit tests. No dependencies. */
(function (root, factory) {
  var api = factory();
  if (typeof module !== 'undefined' && module.exports) module.exports = api; // Node / tests
  if (typeof document !== 'undefined') api._runInBrowser();                  // browser
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var WORD = /[A-Za-z0-9_]/;

  // A term edge that is itself a word char must not sit against another word char,
  // so "OTP" never matches inside "OTPX". Non-word edges (e.g. "@impl") are exempt.
  function boundaryOk(text, term, start, end) {
    var before = start > 0 ? text[start - 1] : '';
    var after = end < text.length ? text[end] : '';
    var leftOk = !WORD.test(term[0]) || !WORD.test(before);
    var rightOk = !WORD.test(term[term.length - 1]) || !WORD.test(after);
    return leftOk && rightOk;
  }

  function overlapsTaken(taken, start, end) {
    for (var i = start; i < end; i++) if (taken[i]) return true;
    return false;
  }

  // Ordered, non-overlapping matches of glossary terms in `text`.
  // Longer terms are placed first so "delta-CRDT" wins over the "CRDT" inside it.
  function glossifyMatches(text, terms) {
    var ordered = terms.slice().sort(function (a, b) {
      return b.term.length - a.term.length;
    });
    var taken = [];
    var matches = [];
    for (var t = 0; t < ordered.length; t++) {
      var term = ordered[t].term;
      var from = 0;
      var idx;
      while ((idx = text.indexOf(term, from)) !== -1) {
        var end = idx + term.length;
        from = end;
        if (!boundaryOk(text, term, idx, end)) continue;
        if (overlapsTaken(taken, idx, end)) continue;
        for (var m = idx; m < end; m++) taken[m] = true;
        matches.push({
          index: idx,
          length: term.length,
          term: term,
          id: ordered[t].id,
          gloss: ordered[t].gloss,
        });
      }
    }
    matches.sort(function (a, b) {
      return a.index - b.index;
    });
    return matches;
  }

  // ---- Browser runtime -------------------------------------------------------
  // Elements whose text must never be rewritten (code, existing links, scripts…).
  var SKIP = { A: 1, CODE: 1, PRE: 1, SCRIPT: 1, STYLE: 1, NOSCRIPT: 1, TEXTAREA: 1, BUTTON: 1 };

  // The term bank is provided by reference/glossary-terms.js (self.GLOSSIFY_TERMS).
  function getTerms() {
    var terms = (typeof self !== 'undefined' && self.GLOSSIFY_TERMS) || [];
    if (!terms.length && typeof console !== 'undefined') {
      console.warn('glossify: no GLOSSIFY_TERMS found — include reference/glossary-terms.js before glossify.js');
    }
    return terms;
  }

  // Derive the glossary URL from this script's own src, so the same engine works
  // wherever it is included from (../reference/glossify.js -> ../reference/glossary.html).
  function glossaryUrl() {
    var scripts = document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      var src = scripts[i].getAttribute('src') || '';
      if (/glossify\.js(\?.*)?$/.test(src)) return src.replace(/glossify\.js(\?.*)?$/, 'glossary.html');
    }
    return '../reference/glossary.html'; // sensible default for a lesson
  }

  function injectStyle() {
    var css =
      '.gl-term{color:inherit;text-decoration:none;border-bottom:1px dotted var(--accent,#6d3fb3);cursor:help}' +
      '.gl-term:hover,.gl-term:focus{background:var(--accent-soft,#f1ebfa);border-bottom-style:solid;outline:none}' +
      '.gl-tip{position:fixed;z-index:80;max-width:22rem;background:#1b1822;color:#f3eff9;' +
      'font:400 .82rem/1.45 ui-sans-serif,system-ui,sans-serif;padding:.55rem .7rem;border-radius:9px;' +
      'box-shadow:0 4px 18px rgba(27,24,34,.28);pointer-events:none;opacity:0;transform:translateY(3px);' +
      'transition:opacity .12s,transform .12s}' +
      '.gl-tip.show{opacity:1;transform:none}' +
      '.gl-tip b{color:#c9aef0;display:block;font-size:.7rem;letter-spacing:.08em;text-transform:uppercase;margin-bottom:.2rem}' +
      '.gl-tip .gl-hint{color:#9b8bb4;font-size:.72rem;margin-top:.35rem}' +
      '@media print{.gl-term{border-bottom:none}.gl-tip{display:none}}';
    var el = document.createElement('style');
    el.textContent = css;
    document.head.appendChild(el);
  }

  function collectTextNodes(root) {
    var nodes = [];
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!node.nodeValue || !/\S/.test(node.nodeValue)) return NodeFilter.FILTER_REJECT;
        for (var p = node.parentNode; p && p !== root; p = p.parentNode) {
          if (p.nodeType === 1 && (SKIP[p.nodeName] || p.classList.contains('gl-term'))) {
            return NodeFilter.FILTER_REJECT;
          }
        }
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    var n;
    while ((n = walker.nextNode())) nodes.push(n);
    return nodes;
  }

  function wrapNode(node, base, terms) {
    var text = node.nodeValue;
    var matches = glossifyMatches(text, terms);
    if (!matches.length) return;
    var frag = document.createDocumentFragment();
    var cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      var m = matches[i];
      if (m.index > cursor) frag.appendChild(document.createTextNode(text.slice(cursor, m.index)));
      var a = document.createElement('a');
      a.className = 'gl-term';
      a.href = base + '#' + m.id;
      a.textContent = text.substr(m.index, m.length);
      a.setAttribute('data-gloss', m.gloss);
      a.setAttribute('aria-label', m.term + ' — ' + m.gloss + ' (open glossary)');
      frag.appendChild(a);
      cursor = m.index + m.length;
    }
    if (cursor < text.length) frag.appendChild(document.createTextNode(text.slice(cursor)));
    node.parentNode.replaceChild(frag, node);
  }

  function makeTooltip() {
    var tip = document.createElement('div');
    tip.className = 'gl-tip';
    tip.setAttribute('role', 'tooltip');
    document.body.appendChild(tip);
    return tip;
  }

  function positionTip(tip, target) {
    var r = target.getBoundingClientRect();
    tip.style.left = '0px';
    tip.style.top = '0px';
    var tw = tip.offsetWidth;
    var th = tip.offsetHeight;
    var pad = 8;
    var left = r.left + r.width / 2 - tw / 2;
    left = Math.max(pad, Math.min(left, window.innerWidth - tw - pad));
    var top = r.top - th - 8;
    if (top < pad) top = r.bottom + 8; // flip below when no room above
    tip.style.left = left + 'px';
    tip.style.top = top + 'px';
  }

  function bindTooltip(root, tip) {
    var hideTimer = null;
    function show(target) {
      if (hideTimer) {
        clearTimeout(hideTimer);
        hideTimer = null;
      }
      tip.innerHTML =
        '<b>' + escapeHtml(target.textContent) + '</b>' +
        escapeHtml(target.getAttribute('data-gloss')) +
        '<span class="gl-hint">Click to open the glossary →</span>';
      positionTip(tip, target);
      tip.classList.add('show');
    }
    function hide() {
      hideTimer = setTimeout(function () {
        tip.classList.remove('show');
      }, 60);
    }
    root.addEventListener('mouseover', function (e) {
      var t = e.target.closest && e.target.closest('.gl-term');
      if (t) show(t);
    });
    root.addEventListener('mouseout', function (e) {
      if (e.target.closest && e.target.closest('.gl-term')) hide();
    });
    root.addEventListener('focusin', function (e) {
      if (e.target.classList && e.target.classList.contains('gl-term')) show(e.target);
    });
    root.addEventListener('focusout', function (e) {
      if (e.target.classList && e.target.classList.contains('gl-term')) hide();
    });
    window.addEventListener('scroll', function () {
      tip.classList.remove('show');
    }, true);
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function _runInBrowser() {
    function start() {
      var terms = getTerms();
      if (!terms.length) return;
      var root = document.querySelector('.wrap') || document.body;
      var base = glossaryUrl();
      injectStyle();
      var nodes = collectTextNodes(root);
      for (var i = 0; i < nodes.length; i++) wrapNode(nodes[i], base, terms);
      bindTooltip(document.body, makeTooltip());
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', start);
    } else {
      start();
    }
  }

  return { glossifyMatches: glossifyMatches, _runInBrowser: _runInBrowser };
});
