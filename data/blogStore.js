/**
 * Blog store — reads /data/blog.json once and exposes simple lookups.
 * No DB. Posts are split per locale and indexed by slug.
 */
const path = require('path');
const fs = require('fs');

const DATA_PATH = path.join(__dirname, 'blog.json');
const raw = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));

function list(locale) {
  return (raw[locale] || []).slice().sort((a, b) => (a.date < b.date ? 1 : -1));
}

function findBySlug(locale, slug) {
  return (raw[locale] || []).find((p) => p.slug === slug) || null;
}

function related(locale, slug, limit = 3) {
  return list(locale).filter((p) => p.slug !== slug).slice(0, limit);
}

module.exports = { list, findBySlug, related };
