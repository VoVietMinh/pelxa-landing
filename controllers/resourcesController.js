const blogStore = require('../data/blogStore');

exports.index = (req, res) => {
  const locale = req.locale;
  const t = req.t;
  const posts = blogStore.list(locale);
  const slugBase = locale === 'vi' ? 'tai-nguyen' : 'resources';

  res.render('pages/resources', {
    pageMeta: {
      title: t.resources.metaTitle,
      description: t.resources.metaDescription,
      url: `https://pelxa.com/${locale}/${slugBase}`,
      image: 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow'
    },
    posts
  });
};

exports.show = (req, res, next) => {
  const locale = req.locale;
  const t = req.t;
  const slug = req.params.slug;
  const post = blogStore.findBySlug(locale, slug);
  if (!post) return next();

  const slugBase = locale === 'vi' ? 'tai-nguyen' : 'resources';

  res.render('pages/resource-detail', {
    pageMeta: {
      title: `${post.title} — Pelxa`,
      description: post.excerpt,
      url: `https://pelxa.com/${locale}/${slugBase}/${post.slug}`,
      image: post.cover ? `https://pelxa.com${post.cover}` : 'https://pelxa.com/assets/social-cover.png',
      robots: 'index, follow',
      ogType: 'article'
    },
    post,
    related: blogStore.related(locale, post.slug)
  });
};
