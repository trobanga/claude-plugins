/* Engine tests for assets/glossify.js — the pure matcher `glossifyMatches`.
   Run with `node --test` from this directory. Topic-agnostic: terms are inline
   fixtures, so these travel with the engine and don't depend on any workspace. */
const test = require('node:test');
const assert = require('node:assert');
const { glossifyMatches } = require('./glossify.js');

const OTP = [{ term: 'OTP', id: 'otp', gloss: 'Open Telecom Platform' }];

test('finds a plain term occurrence and carries its metadata', () => {
  const matches = glossifyMatches('OTP ships a behaviour', OTP);
  assert.deepStrictEqual(matches, [
    { index: 0, length: 3, term: 'OTP', id: 'otp', gloss: 'Open Telecom Platform' },
  ]);
});

test('does not match a term glued inside a larger word', () => {
  assert.deepStrictEqual(glossifyMatches('OTPX and xOTP and stOTPer', OTP), []);
});

test('matches a term bounded by punctuation, not just spaces', () => {
  const matches = glossifyMatches('(OTP).', OTP);
  assert.deepStrictEqual(matches.map((m) => m.index), [1]);
});

test('is case-sensitive so lowercase prose words never match', () => {
  assert.deepStrictEqual(glossifyMatches('the otp libraries', OTP), []);
});

test('matches every occurrence of a term', () => {
  const matches = glossifyMatches('OTP and OTP and OTP', OTP);
  assert.deepStrictEqual(matches.map((m) => m.index), [0, 8, 16]);
});

test('prefers the longest term and does not double-match an overlap', () => {
  const terms = [
    { term: 'CRDT', id: 'crdt', gloss: 'g1' },
    { term: 'delta-CRDT', id: 'delta-crdt', gloss: 'g2' },
  ];
  const matches = glossifyMatches('a delta-CRDT merges', terms);
  assert.deepStrictEqual(matches, [
    { index: 2, length: 10, term: 'delta-CRDT', id: 'delta-crdt', gloss: 'g2' },
  ]);
});

test('still matches a standalone shorter term elsewhere in the text', () => {
  const terms = [
    { term: 'CRDT', id: 'crdt', gloss: 'g1' },
    { term: 'delta-CRDT', id: 'delta-crdt', gloss: 'g2' },
  ];
  const matches = glossifyMatches('a delta-CRDT is a CRDT', terms);
  assert.deepStrictEqual(
    matches.map((m) => [m.index, m.term]),
    [
      [2, 'delta-CRDT'],
      [18, 'CRDT'],
    ],
  );
});

test('returns matches of different terms in text order', () => {
  const terms = [
    { term: 'OTP', id: 'otp', gloss: 'g1' },
    { term: 'BEAM', id: 'beam', gloss: 'g2' },
  ];
  const matches = glossifyMatches('The BEAM runs OTP code', terms);
  assert.deepStrictEqual(
    matches.map((m) => m.term),
    ['BEAM', 'OTP'],
  );
});
