const blogStore = require('../data/blogStore');

exports.index = (req, res) => {
  const locale = req.locale;
  const t = req.t;
  const recentPosts = blogStore.list(locale).slice(0, 3);

  res.render('pages/home', {
    pageMeta: {
      title: t.home.metaTitle,
      description: t.home.metaDescription,
      url: `https://pelxa.com/${locale}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow'
    },
    recentPosts
  });
};
