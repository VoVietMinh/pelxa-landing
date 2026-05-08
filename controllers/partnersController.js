exports.index = (req, res) => {
  const locale = req.locale;
  const t = req.t;
  res.render('pages/partners', {
    pageMeta: {
      title: t.partners.metaTitle,
      description: t.partners.metaDescription,
      url: `https://pelxa.com/${locale}/${locale === 'vi' ? 'doi-tac' : 'partners'}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow'
    }
  });
};
