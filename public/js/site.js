/**
 * Pelxa — minimal client JS
 * - Mobile menu toggle
 * - Sticky header shadow on scroll
 */
(function () {
  'use strict';

  // Mobile menu toggle
  var btn = document.getElementById('mobile-menu-toggle');
  var menu = document.getElementById('mobile-menu');
  if (btn && menu) {
    btn.addEventListener('click', function () {
      var isOpen = !menu.classList.contains('hidden');
      menu.classList.toggle('hidden');
      btn.setAttribute('aria-expanded', String(!isOpen));
    });
  }

  // Header shadow on scroll
  var header = document.getElementById('site-header');
  if (header) {
    var update = function () {
      if (window.scrollY > 8) header.classList.add('shadow-card-soft');
      else header.classList.remove('shadow-card-soft');
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
  }
})();
