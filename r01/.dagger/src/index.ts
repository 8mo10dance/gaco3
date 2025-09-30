import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
export class R01 {
  /**
   * Run RSpec tests in a Ruby container
   */
  @func()
  async rspec(
    source?: Directory,
    rubyVersion = '3.2.0', 
    railsEnv = 'test', 
    awsAccessKeyId = 'dummy', 
    awsSecretAccessKey = 'dummy'
  ): Promise<string> {
    const bundleCache = dag.cacheVolume("bundle-cache");
    const sourceDir = source || dag.currentModule().source().directory("..");

    return await dag
      .container()
      .from(`dockerdxm/ruby:${rubyVersion}`)
      .withDirectory("/r01", sourceDir)
      .withWorkdir("/r01")
      .withMountedCache("/usr/local/bundle", bundleCache)
      .withEnvVariable("RAILS_ENV", railsEnv)
      .withEnvVariable("AWS_ACCESS_KEY_ID", awsAccessKeyId)
      .withEnvVariable("AWS_SECRET_ACCESS_KEY", awsSecretAccessKey)
      .withExec(["gem", "install", "bundler:2.4.1"])
      .withExec(["bundle", "install", "--jobs", "4", "--retry", "3"])
      .withExec(["bundle", "exec", "rake", "db:migrate"])
      .withExec(["bundle", "exec", "rspec"])
      .stdout();
  }

  /**
   * Run RSpec tests with default source directory
   */
  @func()
  async test(): Promise<string> {
    return this.rspec();
  }
}
