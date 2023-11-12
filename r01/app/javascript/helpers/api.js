export function apiRequest(url, options) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  return fetch(url, { ...options, headers: { 'X-CSRF-Token': csrfToken, ...options.headers } })
}
