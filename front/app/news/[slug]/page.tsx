import { fetchAPI } from "@/lib/api";
import { notFound } from "next/navigation";

async function getArticle(slug: string) {
  const data = await fetchAPI("articles", { 
    "filters[slug][$eq]": slug 
  });
  return data?.data?.[0];
}

export default async function NewsArticlePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const article = await getArticle(slug);

  if (!article) {
    notFound();
  }

  const { title, content, createdAt, publishedAtCustom } = article;
  const date = publishedAtCustom || createdAt;
  const formattedDate = new Date(date).toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });

  return (
    <div className="container mx-auto px-4 py-20 max-w-4xl">
      <div className="bg-white rounded-[3rem] p-8 md:p-16 shadow-2xl border border-zinc-100">
        <div className="flex items-center gap-3 mb-8">
           <div className="bg-pink-100 text-pink-600 px-4 py-1 rounded-full font-bold text-sm">
             НОВОСТИ
           </div>
           <time className="text-zinc-400 font-medium italic">
             {formattedDate}
           </time>
        </div>
        
        <h1 className="text-4xl md:text-6xl font-black mb-10 text-zinc-900 leading-tight">
          {title}
        </h1>
        
        <div className="prose prose-xl prose-zinc max-w-none prose-headings:font-black prose-p:leading-relaxed prose-strong:text-pink-500">
          {/* Strapi content might be Blocks or RichText, simplified for now */}
          <div dangerouslySetInnerHTML={{ __html: content }} />
        </div>
      </div>
    </div>
  );
}
