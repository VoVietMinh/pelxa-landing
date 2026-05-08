/**
 * Routes — locale-aware clean URLs.
 *
 *   /en, /en/solutions, /en/partners, /en/resources, /en/resources/:slug, /en/about, /en/contact
 *   /vi, /vi/giai-phap, /vi/doi-tac, /vi/tai-nguyen, /vi/tai-nguyen/:slug, /vi/ve-chung-toi, /vi/lien-he
 *
 * Slug pairs map to the same controller — each has a "currentRoute"
 * key so the header can highlight the active link in either locale.
 */
const express = require('express');

const { localeMiddleware, SUPPORTED_LOCALES } = require('../middleware/i18n');

const home = require('../controllers/homeController');
const solutions = require('../controllers/solutionsController');
const partners = require('../controllers/partnersController');
const resources = require('../controllers/resourcesController');
const about = require('../controllers/aboutController');
const contact = require('../controllers/contactController');
const seo = require('../controllers/seoController');

// Map: route key → { en: path, vi: path }
const ROUTE_MAP = {
  home:        { en: '',          vi: '' },
  solutions:   { en: 'solutions', vi: 'giai-phap' },
  partners:    { en: 'partners',  vi: 'doi-tac' },
  resources:   { en: 'resources', vi: 'tai-nguyen' },
  about:       { en: 'about',     vi: 've-chung-toi' },
  contact:     { en: 'contact',   vi: 'lien-he' }
};

function buildLocaleRouter(locale) {
  const r = express.Router({ mergeParams: true });
  r.use(localeMiddleware(locale));

  // View helpers
  r.use((req, res, next) => {
    res.locals.pathFor = (key, otherLocale) => {
      const lc = otherLocale || locale;
      const seg = (ROUTE_MAP[key] || {})[lc];
      return seg ? `/${lc}/${seg}` : `/${lc}`;
    };
    res.locals.routeMap = ROUTE_MAP;
    next();
  });

  // Helper: register both pretty path and any locale alias
  const reg = (key, handler) => {
    const p = ROUTE_MAP[key][locale];
    const url = p ? `/${p}` : '/';
    r.get(url, (req, res, next) => {
      res.locals.currentRoute = key;
      res.locals.routeMap = ROUTE_MAP;
      handler(req, res, next);
    });
  };

  reg('home', home.index);
  reg('solutions', solutions.index);
  reg('partners', partners.index);
  reg('resources', resources.index);
  reg('about', about.index);
  reg('contact', contact.index);

  // Resource detail
  const resourcesPath = ROUTE_MAP.resources[locale];
  r.get(`/${resourcesPath}/:slug`, (req, res, next) => {
    res.locals.currentRoute = 'resources';
    res.locals.routeMap = ROUTE_MAP;
    resources.show(req, res, next);
  });

  return r;
}

module.exports = function buildRoutes() {
  const root = express.Router();

  for (const locale of SUPPORTED_LOCALES) {
    root.use(`/${locale}`, buildLocaleRouter(locale));
  }

  // SEO routes (no locale prefix)
  root.get('/sitemap.xml', seo.sitemap(ROUTE_MAP));
  root.get('/robots.txt', seo.robots);

  return root;
};

module.exports.ROUTE_MAP = ROUTE_MAP;
