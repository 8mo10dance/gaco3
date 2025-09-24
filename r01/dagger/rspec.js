import { connect } from "@dagger.io/dagger";

import withApp from "./app.js";

connect(async (client) => {
  const container = withApp(client)
    .withExec(["bundle", "exec", "rspec"]);
  const stdout = await container.stdout();

  console.log(stdout);
}, { LogOutput: process.stdout });
