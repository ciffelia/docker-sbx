# docker-sbx

My Docker Sandboxes config

## Usage

Allow this repository as a Kit source once on each machine where you use Docker Sandboxes. If you have customized this setting, keep your existing entries too.

```sh
sbx settings set kit.allowedSources '["docker.io/","dhi.io/","github.com/ciffelia/docker-sbx"]'
```

Run in the project directory:

```sh
curl -fsSL https://raw.githubusercontent.com/ciffelia/docker-sbx/166efe0c42d4261e71d0809ecda9205149ff8c25/init.sh | bash
sbx env run
```

To exclude the generated files locally via Git's `info/exclude`, use `--local`:

```sh
curl -fsSL https://raw.githubusercontent.com/ciffelia/docker-sbx/166efe0c42d4261e71d0809ecda9205149ff8c25/init.sh | bash -s -- --local
```
