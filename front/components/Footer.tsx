export default function Footer({ footerText }: { footerText?: string }) {
  const currentYear = new Date().getFullYear();
  
  return (
    <footer className="bg-zinc-900 text-white py-12">
      <div className="container mx-auto px-4 flex flex-col items-center gap-4">
        <div className="text-2xl font-black bg-gradient-to-r from-cyan-400 to-emerald-400 bg-clip-text text-transparent mb-4">
          Stay Awesome! 🚀
        </div>
        {footerText && <p className="text-zinc-400 max-w-md text-center">{footerText}</p>}
        <div className="w-16 h-1 bg-gradient-to-r from-pink-500 to-yellow-500 rounded-full my-4"></div>
        <p className="text-sm font-medium text-zinc-500 uppercase tracking-widest">
          © {currentYear} • Сделано с любовью
        </p>
      </div>
    </footer>
  );
}
