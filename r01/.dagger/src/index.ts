import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
export class R01 {
  /**
   * Returns a container that echoes whatever string argument is provided
   */
  @func()
  rspec(rubyVersion = '3.2.0', railsEnv = 'test', awsAccessKeyId = 'dummy', awsSecretAccessKey = 'dummy'): Container {
    const hostDir = client.host().directory(".");
    const bundleCache = client.cacheVolume("bundle-cache");

    return dag
      .container()
      .from(`dockerdxm/ruby:${rubyVersion}`)
      .withDirectory("/r01", hostDir)
      .withWorkdir("/r01")
      .withMountedCache("/usr/local/bundle", bundleCache)
      .withEnvVariable("RAILS_ENV", railsEnv)
      .withEnvVariable("AWS_ACCESS_KEY_ID", awsAccessKeyId)
      .withEnvVariable("AWS_SECRET_ACCESS_KEY", awsSecretAccessKey)
      .withExec(["gem", "install", "bundler:2.4.1"])
      .withExec(["bundle", "install", "--jobs", "4", "--retry", "3"])
      .withExec(["bundle", "exec", "rake", "db:migrate"]);
  }
}
