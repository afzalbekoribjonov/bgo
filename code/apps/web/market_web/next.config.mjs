/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**' },
      // ImageKit sozlanmagan bo'lsa backend rasmni lokal diskka saqlab oddiy
      // HTTP orqali xizmat qiladi (dev muhitida) — next/image shuni ham
      // optimallashtira olishi uchun.
      { protocol: 'http', hostname: 'localhost' },
    ],
  },
};

export default nextConfig;
