import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif']
      }
    }
  },
  safelist: [
    'bg-green-50', 'border-green-200', 'text-green-800',
    'bg-yellow-50', 'border-yellow-200', 'text-yellow-800',
    'bg-red-50', 'border-red-200', 'text-red-800',
    'bg-slate-50', 'border-slate-200', 'text-slate-800',
    'bg-indigo-50', 'border-indigo-200', 'text-indigo-800',
    'bg-amber-50', 'border-amber-200', 'text-amber-700'
  ],
  plugins: []
} satisfies Config;
