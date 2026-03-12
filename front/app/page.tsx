import NewsCard from "@/components/NewsCard";
import { fetchAPI } from "@/lib/api";

async function getArticles() {
  const data = await fetchAPI("articles", { sort: "publishedAt:desc" });
  return data?.data || [];
}

export default async function Home() {
  const articles = await getArticles();

  return (
    <div className="container mx-auto px-4 py-16">
      <section className="mb-20 text-center">
        <h1 className="text-6xl md:text-8xl font-black mb-6 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-500 bg-clip-text text-transparent animate-gradient-x">
          Новости проекта
        </h1>
        <p className="text-xl text-zinc-600 max-w-2xl mx-auto font-medium">
          Самые свежие обновления, крутые фичи и важные объявления. 
          Будьте в курсе всего самого интересного! ✨
        </p>
      </section>

      {articles.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">
          {articles.map((article: any) => (
            <NewsCard key={article.id} article={article} />
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-20 bg-white rounded-[3rem] border-4 border-dashed border-zinc-200">
          <span className="text-6xl mb-4">🎈</span>
          <h3 className="text-2xl font-bold text-zinc-400">Пока новостей нет, но скоро они появятся!</h3>
        </div>
      )}
    </div>
  );
}
