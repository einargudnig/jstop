import { FEATURES } from "../data";

// Renders `backtick` spans in feature copy as <code>.
const withCode = (text: string) =>
  text.split(/(`[^`]+`)/).map((part, i) =>
    part.startsWith("`") ? <code key={i}>{part.slice(1, -1)}</code> : part,
  );

export const Features = () => (
  <section className="wrap features">
    <h2>
      Small app. <em>Knows</em> a lot about your processes.
    </h2>
    <dl>
      {FEATURES.map((f) => (
        <div key={f.title}>
          <dt>{f.title}</dt>
          <dd>{withCode(f.body)}</dd>
        </div>
      ))}
    </dl>
  </section>
);
