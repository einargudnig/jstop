import { Composition } from "remotion";
import { JstopShowcase } from "./JstopShowcase";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="JstopShowcase"
      component={JstopShowcase}
      durationInFrames={620}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
