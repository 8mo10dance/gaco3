import { connect } from "@dagger.io/dagger";

const RUBY_VERSION = "3.2.0";
const RAILS_ENV = process.env.RAILS_ENV || 'test';
const AWS_ACCESS_KEY_ID = process.env.AWS_ACCESS_KEY_ID || 'dummy';
const AWS_SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY || 'dummy';

export default function withApp(client) {
  const hostDir = client.host().directory(".");
  const bundleCache = client.cacheVolume("bundle-cache");

  return client
    .container()
    .from(`ghcr.io/8mo10dance/gaco3/ruby:${RUBY_VERSION}`)
    .withDirectory("/r01", hostDir)
    .withWorkdir("/r01")
    .withMountedCache("/usr/local/bundle", bundleCache)
    .withEnvVariable("RAILS_ENV", RAILS_ENV)
    .withEnvVariable("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    .withEnvVariable("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    .withExec(["gem", "install", "bundler:2.4.1"])
    .withExec(["bundle", "install", "--jobs", "4", "--retry", "3"])
    .withExec(["bundle", "exec", "rake", "db:migrate"]);
}
