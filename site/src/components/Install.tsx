import { DMG_URL, REPO_URL } from "../data";
import { DownloadButton } from "./DownloadButton";

export const Install = () => (
  <section className="install">
    <div className="wrap">
      <div>
        <h2>Get jstop.</h2>
        <p>Download the latest release, drag it to Applications, and look up at your menu bar. Or build it from source:</p>
        <pre>
          <span>$ </span>git clone {REPO_URL}
          {"\n"}
          <span>$ </span>cd jstop &amp;&amp; ./scripts/install.sh
        </pre>
      </div>
      <DownloadButton href={DMG_URL}>Download jstop.dmg</DownloadButton>
    </div>
  </section>
);
