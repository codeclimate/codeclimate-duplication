# This repository is deprecated and archived
This is a repository for a Code Climate Quality plugin which is packaged as a Docker image.

Code Climate Quality is being replaced with the new [Qlty](qlty.sh) code quality platform. Qlty uses a new plugin system which does not require packaging plugins as Docker images.

As a result, this repository is no longer maintained and has been archived.

## Advantages of Qlty plugins
The new Qlty plugins system provides key advantages over the older, Docker-based plugin system:

- Linting runs much faster without the overhead of virtualization
- New versions of linters are available immediately without needing to wait for a re-packaged release
- Plugins can be run with any arbitrary extensions (like extra rules and configs) without requiring pre-packaging
- Eliminates security issues associated with exposing a Docker daemon

## Try out Qlty today free

[Qlty CLI](https://docs.qlty.sh/cli/quickstart) is the fastest linter and auto-formatter for polyglot teams. It is completely free and available for Mac, Windows, and Linux.

  - Install Qlty CLI:
`
curl https://qlty.sh | sh # Mac or Linux
`
or ` <windows install line> `

[Qlty Cloud](https://docs.qlty.sh/cloud/quickstart) is a full code health platform for integrating code quality into development team workflows. It is free for unlimited private contributors.
  - [Try Qlty Cloud today](https://docs.qlty.sh/cloud/quickstart)

**Note**: For existing customers of Quality, please see our [Migration Guide](https://docs.qlty.sh/migration/guide) for more information and resources.
