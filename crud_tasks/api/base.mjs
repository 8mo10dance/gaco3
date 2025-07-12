const BASE_URL = 'http://localhost:3000';

export async function apiRequest(path, options = {}) {
  const url = `${BASE_URL}${path}`
  const response = await fetch(url, options);
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(`HTTP error! status: ${response.status}, message: ${errorData.message || JSON.stringify(errorData)}`);
  }
  if (response.status === 204) return true // No Content for successful deletion
  return response.json();
}
