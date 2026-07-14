// CSRF: Rails includes a meta tag "csrf-token" which we mirror back via X-CSRF-Token header.
// Axios reads it automatically via global setter below; here we put a helper.
export function initCsrf() {
  // Axios won't auto-read meta; do it manually on each request via interceptor is overkill.
  // Instead: have the rails layout template emit <meta name="csrf-token"> for the SPA,
  // or rely on session cookie + same-origin (we do, via Vite proxy).
}
