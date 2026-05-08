/**
 * i18n middleware — loads JSON locale files and resolves the active locale
 * from the URL prefix (/en/... or /vi/...).
 */
const fs = require('fs');
const path = require('path');

const SUPPORTED_LOCALES = ['en', 'vi'];
const DEFAULT_LOCALE = 'en';
const LOCALE_DIR = path.join(__dirname, '..', 'locales');

const cache = {};

function loadLocale(locale) {
  if (!SUPPORTED_LOCALES.includes(locale)) locale = DEFAULT_LOCALE;
  if (cache[locale]) return cache[locale];
  const filePath = path.join(LOCALE_DIR, `${locale}.json`);
  const raw = fs.readFileSync(filePath, 'utf8');
  const dict = JSON.parse(raw);
  cache[locale] = dict;
  return dict;
}

function detectLocaleFromPath(pathname) {
  const seg = (pathname || '').split('/').filter(Boolean)[0];
  return SUPPORTED_LOCALES.includes(seg) ? seg : null;
}

/**
 * Returns Express middleware that attaches `req.locale` and `req.t`
 * for the matched locale.
 */
function localeMiddleware(locale) {
  return (req, res, next) => {
    req.locale = locale;
    req.t = loadLocale(locale);
    res.locals.locale = locale;
    res.locals.t = req.t;
    res.locals.supportedLocales = SUPPORTED_LOCALES;
    next();
  };
}

module.exports = {
  SUPPORTED_LOCALES,
  DEFAULT_LOCALE,
  loadLocale,
  detectLocaleFromPath,
  localeMiddleware
};
