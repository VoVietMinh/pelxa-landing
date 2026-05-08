exports.index = (req, res) => {
  const locale = req.locale;
  const t = req.t;
  res.render('pages/contact', {
    pageMeta: {
      title: t.contact.metaTitle,
      description: t.contact.metaDescription,
      url: `https://pelxa.com/${locale}/${locale === 'vi' ? 'lien-he' : 'contact'}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow'
    }
  });
};
