import { SanoApp } from "../sano/SanoApp";
import { SanoProvider } from "../sano/store";

const Index = () => {
  return (
    <SanoProvider>
      <SanoApp />
    </SanoProvider>
  );
};

export default Index;
