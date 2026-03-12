const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:1337';

export async function fetchAPI(endpoint: string, query?: Record<string, any>) {
  const queryString = query ? '?' + new URLSearchParams(query).toString() : '';

  try {
    const res = await fetch(`${API_URL}/api/${endpoint}${queryString}`, {
      next: { revalidate: 60 }, // Revalidate every minute
    });

    if (!res.ok) {
      console.error(`Failed to fetch API: ${res.statusText}`);
      return null;
    }

    return await res.json();
  } catch (error) {
    console.error(`Fetch API Error (${endpoint}):`, error instanceof Error ? error.message : error);
    return null; // Return null instead of throwing to allow build/SSR to continue gracefully
  }
}

export function getStrapiURL(path = "") {
  return `${API_URL}${path}`;
}
