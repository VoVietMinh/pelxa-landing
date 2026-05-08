/**
 * Pelxa — Node.js MVC website
 * Express + EJS + express-ejs-layouts + Tailwind CSS
 * No database. Blog content sourced from /data/blog.json.
 */

const path = require('path');
const express = require('express');
const expressLayouts = require('express-ejs-layouts');

const i18n = require('./middleware/i18n');
const { SUPPORTED_LOCALES, DEFAULT_LOCALE } = require('./middleware/i18n');
const buildRoutes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3002;

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(expressLayouts);
app.set('layout', 'layout');
app.set('layout extractScripts', true);

// Static
app.use(express.static(path.join(__dirname, 'public'), { maxAge: '7d' }));
app.use(express.urlencoded({ extended: false }));
app.use(express.json());

// Trust proxy in case of reverse proxy
app.set('trust proxy', 1);

// Mount locale-aware routes
app.use('/', buildRoutes());

// Root redirect → default locale
app.get('/', (req, res) => res.redirect(302, `/${DEFAULT_LOCALE}`));

// 404
app.use((req, res) => {
  const locale = i18n.detectLocaleFromPath(req.path) || DEFAULT_LOCALE;
  const t = i18n.loadLocale(locale);
  res.status(404).render('pages/404', {
    layout: 'layout',
    locale,
    t,
    supportedLocales: SUPPORTED_LOCALES,
    pageMeta: {
      title: t.notFound.title + ' — Pelxa',
      description: t.notFound.description,
      url: `https://pelxa.com${req.originalUrl}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'noindex, nofollow',
    },
    currentPath: req.path,
    currentRoute: '404',
  });
});

// 500
app.use((err, req, res, next) => {
  console.error('[Pelxa] Error:', err);
  const locale = i18n.detectLocaleFromPath(req.path) || DEFAULT_LOCALE;
  const t = i18n.loadLocale(locale);
  res.status(500).render('pages/500', {
    layout: 'layout',
    locale,
    t,
    supportedLocales: SUPPORTED_LOCALES,
    pageMeta: {
      title: 'Server Error — Pelxa',
      description: 'Internal server error',
      url: `https://pelxa.com${req.originalUrl}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'noindex',
    },
    currentPath: req.path,
    currentRoute: '500',
  });
});

app.listen(PORT, () => {
  console.log(`\n  Pelxa website running on http://localhost:${PORT}`);
  console.log(`  Locales: ${SUPPORTED_LOCALES.join(', ')}\n`);
});

module.exports = app;
