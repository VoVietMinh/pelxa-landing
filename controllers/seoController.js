/**
 * SEO controller — sitemap.xml + robots.txt.
 */
const blogStore = require('../data/blogStore');
const { SUPPORTED_LOCALES } = require('../middleware/i18n');

const SITE = 'https://pelxa.com';

exports.sitemap = (ROUTE_MAP) => (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const urls = [];

  for (const locale of SUPPORTED_LOCALES) {
    for (const key of Object.keys(ROUTE_MAP)) {
      const seg = ROUTE_MAP[key][locale];
      const path = seg ? `/${locale}/${seg}` : `/${locale}`;
      urls.push({
        loc: `${SITE}${path}`,
        lastmod: today,
        changefreq: key === 'home' ? 'weekly' : 'monthly',
        priority: key === 'home' ? '1.0' : '0.8'
      });
    }

    // Blog posts
    const posts = blogStore.list(locale);
    const slugBase = ROUTE_MAP.resources[locale];
    for (const post of posts) {
      urls.push({
        loc: `${SITE}/${locale}/${slugBase}/${post.slug}`,
        lastmod: post.date || today,
        changefreq: 'monthly',
        priority: '0.6'
      });
    }
  }

  const xml =
    `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    urls
      .map(
        (u) =>
          `  <url>\n    <loc>${u.loc}</loc>\n    <lastmod>${u.lastmod}</lastmod>\n    <changefreq>${u.changefreq}</changefreq>\n    <priority>${u.priority}</priority>\n  </url>`
      )
      .join('\n') +
    `\n</urlset>\n`;

  res.set('Content-Type', 'application/xml');
  res.send(xml);
};

exports.robots = (req, res) => {
  const body =
    `User-agent: *\n` +
    `Allow: /\n` +
    `Disallow: /api/\n\n` +
    `Sitemap: ${SITE}/sitemap.xml\n`;
  res.set('Content-Type', 'text/plain');
  res.send(body);
};
