/* EXAMPLE term bank — copy to a workspace as reference/glossary-terms.js and
   replace the entries with the workspace's own glossary terms.

   This is the topic-specific half of the glossify pair; assets/glossify.js is
   the generic engine copied verbatim. Keep this file in sync with the rendered
   reference/glossary.html: every `id` must match a <dt id="…"> anchor there.

   surface (term) = exact, CASE-SENSITIVE string to match in lesson prose.
   id             = the glossary <dt> anchor it links to (glossary.html#id).
   gloss          = one-line tooltip; abbreviations spelled out. The full
                    definition lives in the glossary, so keep this short.

   Guidance:
   - Add a surface only for terms distinctive enough not to false-match ordinary
     English. Skip common words (e.g. "set", "load", "map"); prefer abbreviations
     (RPE, OTP) and proper/compound terms.
   - Matching is case-sensitive, so "RPE" matches but "rpe" does not.
   - Multiple surfaces may share one id (an abbreviation and its expansion, a
     short and a fully-qualified name). List longer surfaces too — the engine
     prefers the longest match, so "delta-CRDT" wins over the "CRDT" inside it. */
(function (root) {
  'use strict';
  var TERMS = [
    { term: 'RPE', id: 'rpe', gloss: 'Rate of Perceived Exertion — a 1–10 self-rating of set difficulty.' },
    { term: 'Progressive overload', id: 'progressive-overload', gloss: 'Systematically increasing demand on a muscle over time.' },
    { term: 'Hypertrophy', id: 'hypertrophy', gloss: 'Muscle growth driven by mechanical tension and metabolic stress.' },
  ];
  if (typeof module !== 'undefined' && module.exports) module.exports = TERMS; // Node / tests
  root.GLOSSIFY_TERMS = TERMS;                                                 // browser
})(typeof self !== 'undefined' ? self : this);
