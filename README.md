# PlanckJabby

A Planck 1.x adapter for the [Loner1536 Jabby fork](https://github.com/Loner1536/jabby).

This repository is a directly installable extraction of `@rbxts/planck-jabby@1.0.0`, originally developed as part of [YetAnotherClown/planck](https://github.com/YetAnotherClown/planck). It exists separately because the upstream repository is a monorepo and its current `planck-jabby` package targets a different Planck API generation.

## Installation

Install the adapter from GitHub while keeping the normal `@rbxts/planck-jabby` import:

```json
{
  "dependencies": {
    "@rbxts/jabby": "github:Loner1536/jabby#main",
    "@rbxts/planck": "^1.0.0",
    "@rbxts/planck-jabby": "github:Loner1536/PlanckJabby#main"
  }
}
```

```ts
import JabbyPlugin from "@rbxts/planck-jabby";

scheduler.addPlugin(new JabbyPlugin());
```

## Fork-specific behavior

This adapter translates Planck scheduler metadata into the generic hierarchy used by the Loner1536 Jabby fork:

```text
Planck phase   -> Jabby category
system category -> Jabby subcategory
system name    -> Jabby system
```

For example, a `FirstPerson` system in Planck's `Visual` phase and `Camera` category renders as:

```text
Visual
└── Camera
    └── FirstPerson
```

See [FORK_CHANGES.md](./FORK_CHANGES.md) for a focused list of differences from the original adapter.

## Compatibility

This branch intentionally targets `@rbxts/planck@1.x`, including the `_addHook` plugin API used by BladeBound. It is not a repackaging of the current Planck `0.3.0-rc` monorepo adapter.

## Attribution

The original PlanckJabby adapter was created by YetAnotherClown and contributors in [YetAnotherClown/planck](https://github.com/YetAnotherClown/planck). This repository preserves the original ISC license declared by `@rbxts/planck-jabby@1.0.0`.
