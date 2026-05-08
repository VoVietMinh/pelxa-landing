/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './views/**/*.ejs',
    './public/js/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        // Brand tokens — see public/assets/color-palette.md
        'pelxa-blue': '#0066FF',
        'deep-ocean': '#0052E0',
        'sky-pulse': '#0099FF',
        'cyan-spark': '#00C2FF',
        midnight: '#001A4D',
        navy: '#0A2540',
        slate: {
          DEFAULT: '#3D4F66',
          50: '#F4F8FE',
          100: '#E0F0FF',
          200: '#D6E2F0',
          300: '#7A8AA0',
          500: '#3D4F66',
          700: '#3D4F66'
        },
        'cool-gray': '#7A8AA0',
        frost: '#F4F8FE',
        'ice-blue': '#E0F0FF',
        'soft-border': '#D6E2F0',
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444'
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
        display: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif']
      },
      borderRadius: {
        '4xl': '32px'
      },
      backgroundImage: {
        'primary-gradient': 'linear-gradient(135deg, #0066FF 0%, #0099FF 100%)',
        'smart-gradient': 'linear-gradient(135deg, #0099FF 0%, #00C2FF 100%)',
        'future-gradient': 'linear-gradient(135deg, #001A4D 0%, #0052E0 50%, #00B4FF 100%)',
        'subtle-gradient': 'linear-gradient(180deg, #FFFFFF 0%, #F4F8FE 100%)'
      },
      boxShadow: {
        pelxa: '0 8px 24px rgba(0,102,255,0.15), 0 4px 16px rgba(10,37,64,0.06)',
        'card-soft': '0 4px 16px rgba(10, 37, 64, 0.06)',
        'btn-blue': '0 8px 24px rgba(0,102,255,0.25)'
      }
    }
  },
  plugins: []
};
