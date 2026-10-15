import { useState } from "react";
import { BACKGROUND_COUNT, DEV_SERVERS, DMG_URL, REPO_URL } from "./data";
import { DownloadButton } from "./components/DownloadButton";
import { Features } from "./components/Features";
import { Install } from "./components/Install";
import { MenuBar } from "./components/MenuBar";
import { Popover } from "./components/Popover";

export const App = () => {
  const [killed, setKilled] = useState<ReadonlySet<number>>(new Set());

  const alive = DEV_SERVERS.filter((p) => !killed.has(p.pid));
  const total = alive.length + BACKGROUND_COUNT;

  const kill = (pid: number) => setKilled((prev) => new Set(prev).add(pid));
  const reset = () => setKilled(new Set());

  return (
    <>
      <MenuBar count={total} />
      <main>
        <section className="wrap hero">
          <div>
            <div className="eyebrow rise">
              <img src="/icon.svg" alt="" />
              <b>jstop</b> for macOS
            </div>
            <h1 className="rise">
              Every dev server you <em>forgot</em> was running.
            </h1>
            <p className="lede rise">
              jstop sits in your menu bar and lists every <code>node</code>, <code>bun</code> and{" "}
              <code>deno</code> process on your Mac — with its port, its framework, and a button to make
              it stop. No more <code>lsof -i :3000</code>.
            </p>
            <div className="ctas rise">
              <DownloadButton href={DMG_URL}>Download for Mac</DownloadButton>
              <a className="link" href={REPO_URL}>
                View source on GitHub
              </a>
            </div>
            <p className="fine rise">Free and open source · macOS 13 or later</p>
          </div>

          <div className="stage">
            <Popover processes={DEV_SERVERS} killed={killed} total={total} onKill={kill} onReset={reset} />
            <p className="hint">go on, kill one ↑</p>
          </div>
        </section>

        <section className="wrap film">
          <video
            src="/jstop-showcase.mp4"
            autoPlay
            muted
            loop
            playsInline
            preload="metadata"
            aria-label="jstop showcase video"
          />
        </section>

        <Features />
        <Install />
      </main>

      <footer>
        <div className="wrap">
          <span>
            MIT licensed · made by <a href="https://github.com/einargudnig">einargudnig</a>
          </span>
          <a href={`${REPO_URL}/releases`}>Release notes</a>
        </div>
      </footer>
    </>
  );
};
