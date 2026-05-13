import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";

import { ClientShell } from "@/components/client-shell";
import { ThemeProvider } from "@/components/theme-provider";

import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "CarDEX",
  description: "CarDEX — Araç Veri Yönetim Sistemi",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="tr"
      className={`${geistSans.variable} ${geistMono.variable}`}
      suppressHydrationWarning
    >
      <body className="bg-background text-foreground antialiased">
        <ThemeProvider>
          <ClientShell>{children}</ClientShell>
        </ThemeProvider>
      </body>
    </html>
  );
}
