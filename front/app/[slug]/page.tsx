import { fetchAPI } from "@/lib/api";
import { notFound } from "next/navigation";

async function getPage(slug: string) {
  const data = await fetchAPI("pages", { 
    "filters[slug][$eq]": slug 
  });
  return data?.data?.[0];
}

export default async function StaticPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const page = await getPage(slug);

  if (!page) {
    notFound();
  }

  const { title, content } = page;

  return (
    <div className="container mx-auto px-4 py-20 max-w-4xl">
      <div className="bg-white rounded-[3rem] p-8 md:p-16 shadow-2xl border border-zinc-100 relative overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-4 bg-gradient-to-r from-pink-500 via-yellow-400 to-cyan-400"></div>
        
        <h1 className="text-4xl md:text-6xl font-black mb-12 text-zinc-900 leading-tight">
          {title}
        </h1>
        
        <div className="prose prose-xl prose-zinc max-w-none prose-headings:font-black prose-p:leading-relaxed prose-strong:text-pink-500 prose-a:text-cyan-500 hover:prose-a:text-pink-500 transition-colors">
           <div dangerouslySetInnerHTML={{ __html: content }} />
        </div>
      </div>
    </div>
  );
}
