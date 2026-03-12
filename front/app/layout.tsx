import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { fetchAPI } from "@/lib/api";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Fun Strapi Website",
  description: "Веселый сайт на Strapi и Next.js",
};

async function getGlobalData() {
  const data = await fetchAPI("global", { populate: "menuLinks" });
  return data?.data || {};
}

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const globalData = await getGlobalData();
  const { siteName, menuLinks, footerText } = globalData;

  return (
    <html lang="ru">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased min-h-screen flex flex-col bg-zinc-50`}
      >
        <Header siteName={siteName} menuLinks={menuLinks} />
        <main className="flex-grow">
          {children}
        </main>
        <Footer footerText={footerText} />
      </body>
    </html>
  );
}
