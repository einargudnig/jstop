import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
  Sequence,
} from "remotion";

// ── Helpers ──

const ease = (t: number) => 1 - Math.pow(1 - t, 3);

const FadeIn: React.FC<{
  children: React.ReactNode;
  delay?: number;
  duration?: number;
}> = ({ children, delay = 0, duration = 20 }) => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame - delay, [0, duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });
  return (
    <div style={{ opacity: progress, transform: `translateY(${(1 - progress) * 20}px)` }}>
      {children}
    </div>
  );
};

/** Wraps a scene with fade-in at start and fade-out at end */
const CrossFade: React.FC<{
  children: React.ReactNode;
  durationInFrames: number;
  fadeFrames?: number;
}> = ({ children, durationInFrames, fadeFrames = 12 }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(
    frame,
    [0, fadeFrames, durationInFrames - fadeFrames, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  return <AbsoluteFill style={{ opacity }}>{children}</AbsoluteFill>;
};

// ── Mock Data ──

const mockProcesses = [
  { framework: "Next.js", pid: 48291, port: 3000, path: "work/my-app", uptime: "2h 15m" },
  { framework: "Vite", pid: 51003, port: 5173, path: "projects/dashboard", uptime: "45m" },
  { framework: "Remix", pid: 52817, port: 3001, path: "clients/storefront", uptime: "12m" },
];

const mockBackground = [
  { framework: "tsx", pid: 49102, port: 0, path: ".npm/_npx/playwright-mcp", uptime: "1h 30m" },
  { framework: "nodemon", pid: 50221, port: 0, path: "tools/api-mock", uptime: "3h 10m" },
];

// ── Styles ──

const colors = {
  bg: "#0a0a0a",
  surface: "#1a1a1a",
  surfaceHover: "#222",
  border: "#2a2a2a",
  text: "#e5e5e5",
  textSecondary: "#888",
  blue: "#3b82f6",
  blueBg: "rgba(59,130,246,0.12)",
  red: "#ef4444",
  redBg: "rgba(239,68,68,0.15)",
  green: "#22c55e",
  badge: "rgba(255,255,255,0.08)",
};

const fontStack = '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif';
const monoStack = '"SF Mono", "Fira Code", "Cascadia Code", monospace';

// ── Scene 1: Title ──

const TitleScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const iconScale = spring({ frame, fps, config: { damping: 12, stiffness: 100 } });
  const titleOpacity = interpolate(frame, [15, 35], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const subtitleOpacity = interpolate(frame, [30, 50], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.bg,
        justifyContent: "center",
        alignItems: "center",
        fontFamily: fontStack,
      }}
    >
      <div
        style={{
          position: "absolute",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)",
          transform: `scale(${iconScale})`,
        }}
      />

      <div style={{ textAlign: "center", zIndex: 1 }}>
        <div
          style={{
            fontSize: 80,
            marginBottom: 30,
            transform: `scale(${iconScale})`,
            display: "inline-block",
          }}
        >
          <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke={colors.blue} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="4 17 10 11 4 5" />
            <line x1="12" y1="19" x2="20" y2="19" />
          </svg>
        </div>

        <div
          style={{
            fontSize: 90,
            fontWeight: 700,
            color: colors.text,
            opacity: titleOpacity,
            letterSpacing: "-2px",
          }}
        >
          jstop
        </div>

        <div
          style={{
            fontSize: 28,
            color: colors.textSecondary,
            opacity: subtitleOpacity,
            marginTop: 16,
            fontWeight: 400,
          }}
        >
          Your JS processes, one click away
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ── Scene 2: The Problem (Activity Monitor chaos) ──

const activityMonitorProcesses = [
  { name: "node", pid: 48291, cpu: "12.3", mem: "245.2 MB", user: "einar" },
  { name: "node", pid: 49102, cpu: "3.1", mem: "189.4 MB", user: "einar" },
  { name: "node", pid: 50887, cpu: "0.8", mem: "156.7 MB", user: "einar" },
  { name: "node", pid: 51003, cpu: "8.7", mem: "312.1 MB", user: "einar" },
  { name: "node", pid: 51209, cpu: "0.2", mem: "98.3 MB", user: "einar" },
  { name: "node", pid: 52100, cpu: "1.4", mem: "201.5 MB", user: "einar" },
  { name: "node", pid: 52817, cpu: "5.6", mem: "178.9 MB", user: "einar" },
  { name: "node", pid: 53001, cpu: "0.1", mem: "87.6 MB", user: "einar" },
  { name: "node", pid: 53444, cpu: "2.9", mem: "134.2 MB", user: "einar" },
  { name: "node", pid: 54102, cpu: "0.5", mem: "112.8 MB", user: "einar" },
  { name: "node", pid: 54399, cpu: "7.2", mem: "267.3 MB", user: "einar" },
  { name: "node", pid: 54801, cpu: "0.3", mem: "95.1 MB", user: "einar" },
  { name: "node", pid: 55120, cpu: "1.1", mem: "143.6 MB", user: "einar" },
];

const ProblemScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Window slides up
  const windowY = spring({ frame: frame - 5, fps, config: { damping: 14, stiffness: 80 } });
  const windowTranslate = interpolate(windowY, [0, 1], [40, 0]);

  // Question mark / frustration appears later
  const questionOpacity = interpolate(frame, [70, 85], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const questionScale = spring({ frame: frame - 70, fps, config: { damping: 10, stiffness: 120 } });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.bg,
        justifyContent: "center",
        alignItems: "center",
        fontFamily: fontStack,
      }}
    >
      {/* Activity Monitor mock window */}
      <div
        style={{
          width: 820,
          borderRadius: 12,
          overflow: "hidden",
          border: `1px solid ${colors.border}`,
          boxShadow: "0 25px 60px rgba(0,0,0,0.6)",
          transform: `translateY(${windowTranslate}px)`,
          opacity: interpolate(windowY, [0, 0.3], [0, 1]),
        }}
      >
        {/* Title bar */}
        <div
          style={{
            backgroundColor: "#2a2a2a",
            padding: "10px 16px",
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          <div style={{ display: "flex", gap: 6 }}>
            <div style={{ width: 12, height: 12, borderRadius: "50%", backgroundColor: "#ff5f57" }} />
            <div style={{ width: 12, height: 12, borderRadius: "50%", backgroundColor: "#febc2e" }} />
            <div style={{ width: 12, height: 12, borderRadius: "50%", backgroundColor: "#28c840" }} />
          </div>
          <span style={{ color: colors.textSecondary, fontSize: 13, marginLeft: 8, fontWeight: 500 }}>
            Activity Monitor — CPU
          </span>
        </div>

        {/* Column headers */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "200px 80px 100px 120px 100px",
            padding: "8px 16px",
            backgroundColor: "#1e1e1e",
            borderBottom: `1px solid ${colors.border}`,
            fontSize: 11,
            fontWeight: 600,
            color: colors.textSecondary,
          }}
        >
          <span>Process Name</span>
          <span>PID</span>
          <span>% CPU</span>
          <span>Memory</span>
          <span>User</span>
        </div>

        {/* Rows */}
        <div style={{ backgroundColor: colors.surface }}>
          {activityMonitorProcesses.map((proc, i) => {
            const rowDelay = 10 + i * 3;
            const rowOpacity = interpolate(frame - rowDelay, [0, 8], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            });

            return (
              <div
                key={proc.pid}
                style={{
                  display: "grid",
                  gridTemplateColumns: "200px 80px 100px 120px 100px",
                  padding: "6px 16px",
                  fontSize: 12,
                  fontFamily: monoStack,
                  color: colors.text,
                  opacity: rowOpacity,
                  borderBottom: `1px solid rgba(255,255,255,0.03)`,
                  backgroundColor: i % 2 === 0 ? "transparent" : "rgba(255,255,255,0.02)",
                }}
              >
                <span>{proc.name}</span>
                <span style={{ color: colors.textSecondary }}>{proc.pid}</span>
                <span>{proc.cpu}</span>
                <span style={{ color: colors.textSecondary }}>{proc.mem}</span>
                <span style={{ color: colors.textSecondary }}>{proc.user}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Frustration overlay */}
      <div
        style={{
          position: "absolute",
          bottom: 80,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: questionOpacity,
          transform: `scale(${questionScale})`,
        }}
      >
        <span style={{ fontSize: 28, color: colors.textSecondary }}>
          Which <span style={{ color: colors.text, fontWeight: 600 }}>node</span> is which?
        </span>
      </div>
    </AbsoluteFill>
  );
};

// ── Scene 3: Menu Bar Demo (with kill animation) ──

const MenuBarScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const barOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const popoverProgress = spring({
    frame: frame - 20,
    fps,
    config: { damping: 14, stiffness: 120 },
  });

  const popoverScale = interpolate(popoverProgress, [0, 1], [0.95, 1]);
  const popoverOpacity = interpolate(popoverProgress, [0, 1], [0, 1]);

  // Kill animation timing:
  // Frame 100: kill button highlights (red glow)
  // Frame 108: red flash on the row
  // Frame 112: row starts sliding out
  // Frame 125: row is gone, count updates
  const killTarget = 2; // Remix process (index 2)
  const killClickFrame = 100;
  const killFlashFrame = 108;
  const killSlideFrame = 112;
  const killDoneFrame = 128;

  const isKilled = frame >= killSlideFrame;

  // Port highlight on Next.js row (before the kill)
  const portHighlightOpacity = interpolate(frame, [70, 75, 90, 95], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Count badge: "5" → "4" as soon as the row starts sliding out
  const processCount = frame >= killSlideFrame ? 4 : 5;
  const devServerCount = frame >= killSlideFrame ? 2 : 3;

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.bg,
        fontFamily: `${fontStack}, ${monoStack}`,
      }}
    >
      {/* macOS-style menu bar */}
      <div
        style={{
          position: "absolute",
          top: 80,
          left: 0,
          right: 0,
          height: 50,
          backgroundColor: "rgba(30,30,30,0.85)",
          display: "flex",
          justifyContent: "flex-end",
          alignItems: "center",
          paddingRight: 80,
          gap: 20,
          opacity: barOpacity,
          borderBottom: `1px solid ${colors.border}`,
        }}
      >
        <div style={{ display: "flex", gap: 16, alignItems: "center", color: colors.textSecondary, fontSize: 14 }}>
          <span>Wi-Fi</span>
          <span>Battery</span>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 4,
              color: colors.text,
              backgroundColor: frame > 15 ? "rgba(255,255,255,0.1)" : "transparent",
              padding: "4px 8px",
              borderRadius: 4,
            }}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="4 17 10 11 4 5" />
              <line x1="12" y1="19" x2="20" y2="19" />
            </svg>
            <span style={{ fontSize: 12, fontWeight: 600 }}>{processCount}</span>
          </div>
          <span>3:42 PM</span>
        </div>
      </div>

      {/* Popover */}
      <div
        style={{
          position: "absolute",
          top: 140,
          right: 180,
          width: 380,
          backgroundColor: colors.surface,
          borderRadius: 12,
          border: `1px solid ${colors.border}`,
          overflow: "hidden",
          transform: `scale(${popoverScale})`,
          opacity: popoverOpacity,
          transformOrigin: "top right",
          boxShadow: "0 25px 60px rgba(0,0,0,0.5)",
        }}
      >
        {/* Header */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            padding: "14px 16px",
            borderBottom: `1px solid ${colors.border}`,
          }}
        >
          <span style={{ color: colors.text, fontWeight: 600, fontSize: 16 }}>jstop</span>
          <span
            style={{
              color: colors.textSecondary,
              fontSize: 12,
              backgroundColor: colors.badge,
              padding: "2px 8px",
              borderRadius: 4,
            }}
          >
            {processCount}
          </span>
        </div>

        {/* Dev Servers section */}
        <div style={{ padding: "8px 0" }}>
          <FadeIn delay={30}>
            <div
              style={{
                padding: "6px 16px",
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: 500,
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}
            >
              Dev Servers
              <span
                style={{
                  backgroundColor: colors.badge,
                  padding: "1px 6px",
                  borderRadius: 3,
                  fontSize: 10,
                }}
              >
                {devServerCount}
              </span>
            </div>
          </FadeIn>

          {mockProcesses.map((proc, i) => {
            const isKillTarget = i === killTarget;
            const killHighlight = isKillTarget && frame >= killClickFrame && frame < killFlashFrame;
            const killFlash = isKillTarget && frame >= killFlashFrame && frame < killSlideFrame;

            // Slide out + fade for killed row
            let rowOpacity = 1;
            let rowHeight = 68; // approximate row height
            let rowTranslateX = 0;

            if (isKillTarget && frame >= killSlideFrame) {
              const slideProgress = interpolate(
                frame,
                [killSlideFrame, killSlideFrame + 12],
                [0, 1],
                { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease }
              );
              rowOpacity = 1 - slideProgress;
              rowTranslateX = slideProgress * 80;
              rowHeight = rowHeight * (1 - slideProgress);
            }

            return (
              <FadeIn key={proc.pid} delay={35 + i * 8}>
                <div
                  style={{
                    overflow: "hidden",
                    maxHeight: rowHeight,
                    opacity: rowOpacity,
                    transform: `translateX(${rowTranslateX}px)`,
                  }}
                >
                  {/* Red flash overlay */}
                  {killFlash && (
                    <div
                      style={{
                        position: "absolute",
                        inset: 0,
                        backgroundColor: "rgba(239,68,68,0.08)",
                        zIndex: 2,
                        pointerEvents: "none",
                      }}
                    />
                  )}
                  <ProcessRow
                    process={proc}
                    highlightKill={killHighlight}
                    highlightPort={i === 0 ? portHighlightOpacity : 0}
                  />
                </div>
              </FadeIn>
            );
          })}

          {/* Background section */}
          <FadeIn delay={65}>
            <div
              style={{
                padding: "6px 16px",
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: 500,
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}
            >
              <span style={{ fontSize: 8, marginRight: 2 }}>▶</span>
              Background
              <span
                style={{
                  backgroundColor: colors.badge,
                  padding: "1px 6px",
                  borderRadius: 3,
                  fontSize: 10,
                }}
              >
                2
              </span>
            </div>
          </FadeIn>
        </div>
      </div>

      {/* Scene label */}
      <FadeIn delay={5}>
        <div
          style={{
            position: "absolute",
            bottom: 80,
            left: 0,
            right: 0,
            textAlign: "center",
          }}
        >
          {frame < killClickFrame - 10 ? (
            <span style={{ fontSize: 22, color: colors.textSecondary }}>
              All your JS processes in the menu bar
            </span>
          ) : (
            <FadeIn delay={killClickFrame - 5} duration={12}>
              <span style={{ fontSize: 22, color: colors.textSecondary }}>
                Kill any process with <span style={{ color: colors.red }}>one click</span>
              </span>
            </FadeIn>
          )}
        </div>
      </FadeIn>
    </AbsoluteFill>
  );
};

// ── Process Row ──

const ProcessRow: React.FC<{
  process: (typeof mockProcesses)[0];
  highlightKill?: boolean;
  highlightPort?: number;
}> = ({ process, highlightKill, highlightPort = 0 }) => {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "10px 16px",
        borderBottom: `1px solid ${colors.border}`,
        position: "relative",
      }}
    >
      <div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span
            style={{
              color: colors.text,
              fontFamily: monoStack,
              fontWeight: 600,
              fontSize: 14,
            }}
          >
            {process.framework}
          </span>
          <span
            style={{
              color: colors.textSecondary,
              fontSize: 11,
              backgroundColor: colors.badge,
              padding: "1px 6px",
              borderRadius: 3,
            }}
          >
            PID {process.pid}
          </span>
          {process.port > 0 && (
            <span
              style={{
                color: colors.blue,
                fontSize: 12,
                fontFamily: monoStack,
                backgroundColor:
                  highlightPort > 0
                    ? `rgba(59,130,246,${0.12 + highlightPort * 0.18})`
                    : colors.blueBg,
                padding: "1px 6px",
                borderRadius: 3,
                boxShadow:
                  highlightPort > 0
                    ? `0 0 ${12 * highlightPort}px rgba(59,130,246,${0.4 * highlightPort})`
                    : "none",
              }}
            >
              :{process.port}
            </span>
          )}
        </div>
        <div
          style={{
            color: colors.textSecondary,
            fontSize: 11,
            marginTop: 3,
            display: "flex",
            gap: 6,
          }}
        >
          <span>{process.path}</span>
          <span style={{ opacity: 0.6 }}>· {process.uptime}</span>
        </div>
      </div>

      <div
        style={{
          width: 22,
          height: 22,
          borderRadius: "50%",
          backgroundColor: highlightKill ? colors.redBg : "transparent",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: highlightKill ? colors.red : "rgba(239,68,68,0.6)",
          fontSize: 16,
          transform: highlightKill ? "scale(1.3)" : "scale(1)",
          boxShadow: highlightKill ? `0 0 16px ${colors.red}` : "none",
        }}
      >
        ✕
      </div>
    </div>
  );
};

// ── Scene 4: Features ──

const FeaturesScene: React.FC = () => {
  const frame = useCurrentFrame();

  const features = [
    { icon: "🔍", title: "Auto-detect", desc: "Node, Bun & Deno processes" },
    { icon: "🌐", title: "Port detection", desc: "See listening ports instantly" },
    { icon: "⚡", title: "One-click kill", desc: "Graceful SIGTERM shutdown" },
    { icon: "🚀", title: "Open in browser", desc: "Click any port to preview" },
  ];

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.bg,
        justifyContent: "center",
        alignItems: "center",
        fontFamily: fontStack,
      }}
    >
      <div
        style={{
          display: "flex",
          gap: 40,
          flexWrap: "wrap",
          justifyContent: "center",
          maxWidth: 1200,
        }}
      >
        {features.map((f, i) => {
          const delay = i * 12;
          const progress = interpolate(frame - delay, [0, 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: ease,
          });

          return (
            <div
              key={f.title}
              style={{
                width: 240,
                padding: 30,
                backgroundColor: colors.surface,
                borderRadius: 16,
                border: `1px solid ${colors.border}`,
                textAlign: "center",
                opacity: progress,
                transform: `translateY(${(1 - progress) * 30}px)`,
              }}
            >
              <div style={{ fontSize: 40, marginBottom: 16 }}>{f.icon}</div>
              <div style={{ color: colors.text, fontSize: 20, fontWeight: 600, marginBottom: 8 }}>
                {f.title}
              </div>
              <div style={{ color: colors.textSecondary, fontSize: 14 }}>{f.desc}</div>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// ── Scene 5: Framework Detection ──

const FrameworkScene: React.FC = () => {
  const frame = useCurrentFrame();

  const frameworks = [
    "Next.js", "Vite", "Remix", "Astro", "Nuxt", "SvelteKit",
    "Express", "Fastify", "NestJS", "Expo", "Storybook", "Webpack",
    "Turborepo", "Playwright", "Vitest", "Jest", "Wrangler", "Electron",
  ];

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.bg,
        justifyContent: "center",
        alignItems: "center",
        fontFamily: fontStack,
      }}
    >
      <FadeIn delay={0} duration={15}>
        <div style={{ color: colors.text, fontSize: 36, fontWeight: 600, marginBottom: 40, textAlign: "center" }}>
          Detects 25+ frameworks
        </div>
      </FadeIn>

      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: 12,
          justifyContent: "center",
          maxWidth: 900,
        }}
      >
        {frameworks.map((fw, i) => {
          const delay = 10 + i * 3;
          const progress = interpolate(frame - delay, [0, 12], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: ease,
          });

          return (
            <div
              key={fw}
              style={{
                padding: "10px 20px",
                backgroundColor: colors.surface,
                border: `1px solid ${colors.border}`,
                borderRadius: 8,
                color: colors.text,
                fontSize: 16,
                fontFamily: monoStack,
                fontWeight: 500,
                opacity: progress,
                transform: `scale(${interpolate(progress, [0, 1], [0.8, 1])})`,
              }}
            >
              {fw}
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// ── Scene 6: Closing ──

const ClosingScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = spring({ frame, fps, config: { damping: 12, stiffness: 80 } });
  const taglineOpacity = interpolate(frame, [20, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const githubOpacity = interpolate(frame, [40, 55], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.bg,
        justifyContent: "center",
        alignItems: "center",
        fontFamily: fontStack,
      }}
    >
      <div
        style={{
          position: "absolute",
          width: 500,
          height: 500,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(59,130,246,0.06) 0%, transparent 70%)",
          transform: `scale(${scale})`,
        }}
      />

      <div style={{ textAlign: "center", zIndex: 1 }}>
        <div
          style={{
            fontSize: 80,
            fontWeight: 700,
            color: colors.text,
            letterSpacing: "-2px",
            transform: `scale(${scale})`,
          }}
        >
          jstop
        </div>
        <div
          style={{
            fontSize: 24,
            color: colors.textSecondary,
            marginTop: 16,
            opacity: taglineOpacity,
          }}
        >
          Native macOS menu bar app for JS developers
        </div>
        <div
          style={{
            fontSize: 18,
            color: colors.blue,
            marginTop: 24,
            opacity: githubOpacity,
            fontFamily: monoStack,
          }}
        >
          github.com/einargudnig/jstop
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ── Main Composition ──

export const JstopShowcase: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {/* Scene 1: Title (0–90) */}
      <Sequence from={0} durationInFrames={100}>
        <CrossFade durationInFrames={100} fadeFrames={12}>
          <TitleScene />
        </CrossFade>
      </Sequence>

      {/* Scene 2: The Problem — Activity Monitor (90–200) */}
      <Sequence from={90} durationInFrames={120}>
        <CrossFade durationInFrames={120} fadeFrames={12}>
          <ProblemScene />
        </CrossFade>
      </Sequence>

      {/* Scene 3: Menu Bar Demo + Kill (200–360) */}
      <Sequence from={200} durationInFrames={170}>
        <CrossFade durationInFrames={170} fadeFrames={12}>
          <MenuBarScene />
        </CrossFade>
      </Sequence>

      {/* Scene 4: Features (360–440) */}
      <Sequence from={355} durationInFrames={90}>
        <CrossFade durationInFrames={90} fadeFrames={12}>
          <FeaturesScene />
        </CrossFade>
      </Sequence>

      {/* Scene 5: Framework Detection (440–530) */}
      <Sequence from={435} durationInFrames={95}>
        <CrossFade durationInFrames={95} fadeFrames={12}>
          <FrameworkScene />
        </CrossFade>
      </Sequence>

      {/* Scene 6: Closing (530–620) */}
      <Sequence from={520} durationInFrames={100}>
        <CrossFade durationInFrames={100} fadeFrames={15}>
          <ClosingScene />
        </CrossFade>
      </Sequence>
    </AbsoluteFill>
  );
};
