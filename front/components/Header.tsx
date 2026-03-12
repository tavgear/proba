import Link from 'next/link';

export default function Header({ siteName = "Fun Website", menuLinks = [] }: { siteName?: string, menuLinks?: any[] }) {
  return (
    <header className="sticky top-0 z-50 w-full bg-white/70 backdrop-blur-md border-b border-pink-100 shadow-sm">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link href="/" className="text-2xl font-black bg-gradient-to-r from-pink-500 to-yellow-500 bg-clip-text text-transparent hover:scale-105 transition-transform">
          {siteName}
        </Link>
        <nav className="hidden md:flex gap-8">
          {menuLinks.length > 0 ? (
            menuLinks.map((link: any) => (
              <Link 
                key={link.id} 
                href={link.href}
                className="font-bold text-gray-700 hover:text-pink-500 transition-colors uppercase tracking-wider text-sm"
              >
                {link.label}
              </Link>
            ))
          ) : (
            <>
              <Link href="/about" className="font-bold text-gray-700 hover:text-pink-500 transition-colors">О проекте</Link>
              <Link href="/faq" className="font-bold text-gray-700 hover:text-pink-500 transition-colors">FAQ</Link>
            </>
          )}
        </nav>
        <div className="md:hidden">
          {/* Mobile menu button could go here */}
          <div className="w-8 h-8 flex flex-col justify-between p-1 bg-yellow-400 rounded-md cursor-pointer">
            <span className="w-full h-1 bg-white rounded"></span>
            <span className="w-full h-1 bg-white rounded"></span>
            <span className="w-full h-1 bg-white rounded"></span>
          </div>
        </div>
      </div>
    </header>
  );
}
