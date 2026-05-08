exports.index = (req, res) => {
  const locale = req.locale;
  const t = req.t;
  res.render('pages/solutions', {
    pageMeta: {
      title: t.solutions.metaTitle,
      description: t.solutions.metaDescription,
      url: `https://pelxa.com/${locale}/${locale === 'vi' ? 'giai-phap' : 'solutions'}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow'
    }
  });
};
