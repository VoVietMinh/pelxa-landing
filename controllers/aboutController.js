exports.index = (req, res) => {
  const locale = req.locale;
  const t = req.t;
  res.render('pages/about', {
    pageMeta: {
      title: t.about.metaTitle,
      description: t.about.metaDescription,
      url: `https://pelxa.com/${locale}/${locale === 'vi' ? 've-chung-toi' : 'about'}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow'
    }
  });
};
