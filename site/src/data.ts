export const REPO_URL = "https://github.com/einargudnig/jstop";
export const DMG_URL = `${REPO_URL}/releases/latest/download/jstop.dmg`;

export type DemoProcess = {
  pid: number;
  framework: string;
  color: string;
  uptime: string;
  cwd: string;
  command: string;
  ports: number[];
};

export const DEV_SERVERS: DemoProcess[] = [
  { pid: 48213, framework: "Next.js", color: "oklch(0.93 0 0)", uptime: "2h 14m", cwd: "~/code/shop", command: "next dev --turbo", ports: [3000] },
  { pid: 51877, framework: "Vite", color: "oklch(0.62 0.22 295)", uptime: "38m", cwd: "~/personal/blog", command: "bun run dev", ports: [5173] },
  { pid: 50102, framework: "Wrangler", color: "oklch(0.78 0.16 65)", uptime: "1h 02m", cwd: "~/work/api", command: "wrangler dev", ports: [8787, 9229] },
  { pid: 39920, framework: "Storybook", color: "oklch(0.68 0.2 15)", uptime: "3d 4h", cwd: "~/old/design-system", command: "storybook dev", ports: [6006] },
];

export const BACKGROUND_COUNT = 2;

export const FEATURES: { title: string; body: string }[] = [
  { title: "Finds them all", body: "Every running Node.js, Bun and Deno process, with PID, arguments, working directory and uptime." },
  { title: "Sees the ports", body: "Listening TCP ports via `lsof` — including ones owned by child processes, so `bun dev` → `next-server` still shows `:3000`." },
  { title: "Names the framework", body: "Recognises 25+ tools from the command line: Next.js, Vite, Remix, Astro, Nuxt, SvelteKit, Wrangler, Storybook and more." },
  { title: "One-click kill", body: "Sends `SIGTERM` so servers shut down cleanly." },
  { title: "Open in browser", body: "Click a port badge to open `localhost` on that port." },
  { title: "Stays out of the way", body: "Dev servers first, background processes collapsed. Polls every 2s while open and every 10s while idle." },
];
