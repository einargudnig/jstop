import { useEffect, useState } from "react";

const formatClock = (d: Date) =>
  d.toLocaleString("en-GB", { weekday: "short", hour: "2-digit", minute: "2-digit" }).replace(",", "");

const useClock = () => {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(id);
  }, []);
  return formatClock(now);
};

export const MenuBar = ({ count }: { count: number }) => {
  const clock = useClock();

  return (
    <div className="menubar" aria-hidden="true">
      <div className="menubar-left">
        <span></span>
        <b>Terminal</b>
        <span>Shell</span>
        <span>Edit</span>
        <span>View</span>
        <span>Window</span>
      </div>
      <div className="menubar-right">
        <span className="tray">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="5,7 10,12 5,17" />
            <line x1="13" y1="17" x2="19" y2="17" />
          </svg>
          <span>{count}</span>
        </span>
        <span className="clock">{clock}</span>
      </div>
    </div>
  );
};
