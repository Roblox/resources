# Roblox Code Samples

A collection of creator-facing code samples published by Roblox: reference experiences, Studio templates, and reusable packages. These are the same samples featured in the [Roblox documentation](https://create.roblox.com/docs).

## What's in this repo

- `experiences/` — reference experiences and Studio templates
- `packages/` — reusable Luau packages

## Get started with this repo

1. Install [rokit](https://github.com/rojo-rbx/rokit)
1. `rokit install`

   You probably have to individually trust all repositories. If this command fails with a 403 or rate limiting error, you might need to add a PAT from GitHub using `rokit authenticate github --token YOUR_TOKEN_HERE`.

### Packages

1. `cd packages`
1. `mkdir your-package`
1. Copy the desired directory from a working experience running Rojo.
1. Copy and modify an existing `default.project.json` and `dev.project.json` from another package in this repository.
1. Run `rojo serve dev.project.json` from the project directory and make sure the code loads as-expected into a new Roblox experience.

### Experiences

1. `cd experiences`
1. `mkdir your-experience`
1. Copy the contents of your Rojo directory into this new folder.
1. Run `rojo serve` from the project directory and make sure it works as-expected.

## Contributing

We welcome community contributions! When you open a pull request, Developer Advocates from the Roblox Creator Solutions team will review it and either:

- Guide you on best practices and work the change in, or
- Direct you to file a bug report on the [Developer Forum](https://devforum.roblox.com) if the issue requires internal handling.

Please do not open issues for private bugs or security vulnerabilities—use the DevForum for those.

## License

[MIT License](LICENSE.md)
