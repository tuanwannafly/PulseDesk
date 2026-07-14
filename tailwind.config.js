const plugin = require('tailwindcss')
const autoprefixer = require('autoprefixer')

module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/assets/stylesheets/**/*.css',
    './config/routes.rb'
  ],
  // Safelist for dynamic class names built from enums in views
  safelist: [
    {
      pattern: /^bg-(indigo|yellow|green|red|orange|slate|gray)-(100|700)$/
    },
    {
      pattern: /^text-(indigo|yellow|green|red|orange|slate|gray)-(600|700)$/
    }
  ],
  theme: {
    extend: {
      colors: {
        sentiment_positive: '#16a34a',
        sentiment_neutral:  '#737373',
        sentiment_negative: '#dc2626'
      }
    }
  },
  plugins: [plugin, autoprefixer]
}