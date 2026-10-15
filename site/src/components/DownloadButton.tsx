import type { ReactNode } from "react";

export const DownloadButton = ({ href, children }: { href: string; children: ReactNode }) => (
  <a className="btn" href={href}>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4v12" />
      <path d="m6 11 6 6 6-6" />
      <path d="M5 20h14" />
    </svg>
    {children}
  </a>
);
