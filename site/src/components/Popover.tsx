import type { CSSProperties } from "react";
import type { DemoProcess } from "../data";
import { BACKGROUND_COUNT } from "../data";

type Props = {
  processes: DemoProcess[];
  killed: ReadonlySet<number>;
  total: number;
  onKill: (pid: number) => void;
  onReset: () => void;
};

const ProcessRow = ({ process: p, gone, onKill }: { process: DemoProcess; gone: boolean; onKill: () => void }) => (
  <li className={gone ? "row gone" : "row"} style={{ "--c": p.color } as CSSProperties} inert={gone}>
    <div>
      <div className="row-inner">
        <i className="dot" />
        <div className="meta">
          <div className="name">
            {p.framework}{" "}
            <small>
              pid {p.pid} · {p.uptime}
            </small>
          </div>
          <div className="args">
            {p.cwd} · {p.command}
          </div>
          <div className="ports">
            {p.ports.map((port) => (
              <a key={port} className="port" href={`http://localhost:${port}`} target="_blank" rel="noopener">
                :{port}
              </a>
            ))}
          </div>
        </div>
        <button className="kill" aria-label={`Kill ${p.framework}`} onClick={onKill}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </div>
    </div>
  </li>
);

export const Popover = ({ processes, killed, total, onKill, onReset }: Props) => {
  const isEmpty = processes.every((p) => killed.has(p.pid));

  return (
    <div className={isEmpty ? "popover is-empty" : "popover"}>
      <div className="pop-head">
        <strong>JS Processes</strong>
        <span>{total} running</span>
      </div>

      <div className="pop-section">
        <span>Dev servers</span>
      </div>
      <ul className="rows">
        {processes.map((p) => (
          <ProcessRow key={p.pid} process={p} gone={killed.has(p.pid)} onKill={() => onKill(p.pid)} />
        ))}
      </ul>

      <div className="empty">
        All quiet. Your fans thank you.
        <br />
        <button type="button" onClick={onReset}>
          Start them again
        </button>
      </div>

      <div className="bg-toggle">
        <span>Background</span>
        <span>{BACKGROUND_COUNT} ›</span>
      </div>
    </div>
  );
};
