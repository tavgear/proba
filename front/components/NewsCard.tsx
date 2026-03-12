import Link from 'next/link';

export default function NewsCard({ article }: { article: any }) {
  const { title, description, slug, publishedAtCustom, createdAt } = article;
  const date = publishedAtCustom || createdAt;
  const formattedDate = new Date(date).toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });

  return (
    <article className="group relative bg-white rounded-3xl p-8 border border-zinc-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:-translate-y-2 flex flex-col gap-4 overflow-hidden">
      <div className="absolute top-0 right-0 w-32 h-32 bg-yellow-100/50 rounded-full -mr-16 -mt-16 group-hover:scale-150 transition-transform duration-500"></div>
      
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-pink-500"></span>
        <time className="text-xs font-bold text-zinc-400 uppercase tracking-widest italic">
          {formattedDate}
        </time>
      </div>

      <h2 className="text-2xl font-black text-zinc-900 group-hover:text-pink-600 transition-colors leading-tight">
        {title}
      </h2>

      {description && (
        <p className="text-zinc-600 leading-relaxed line-clamp-3">
          {description}
        </p>
      )}

      <Link 
        href={`/news/${slug}`} 
        className="mt-auto inline-flex items-center gap-2 text-sm font-black text-pink-500 hover:text-pink-700 transition-colors group/link"
      >
        ЧИТАТЬ ПОЛНОСТЬЮ 
        <span className="group-hover/link:translate-x-1 transition-transform">→</span>
      </Link>
    </article>
  );
}
