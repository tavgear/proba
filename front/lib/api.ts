const STRAPI_URL = process.env.STRAPI_URL || process.env.NEXT_PUBLIC_STRAPI_URL || 'http://localhost:1337';

export async function fetchAPI(endpoint: string, query?: Record<string, any>) {
  const queryString = query ? '?' + new URLSearchParams(query).toString() : '';
  const res = await fetch(`${STRAPI_URL}/api/${endpoint}${queryString}`, {
    next: { revalidate: 60 }, // Revalidate every minute
  });

  if (!res.ok) {
    console.error(`Failed to fetch API: ${res.statusText}`);
    return null;
  }

  return res.json();
}

export function getStrapiURL(path = "") {
  return `${STRAPI_URL}${path}`;
}
