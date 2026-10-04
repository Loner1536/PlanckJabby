# Fork changes

This file documents behavior added by the Loner1536 fork separately from the original PlanckJabby adapter.

## Hierarchical Jabby categories

The original adapter sends a Planck phase through Jabby's `phase` field. This fork targets a scheduler-agnostic Jabby model instead:

- The Planck phase becomes the Jabby `category`.
- A custom `category` field on the Planck system becomes the Jabby `subcategory`.
- The Planck system name remains the Jabby system name.

Conceptually, registration becomes:

```luau
jabbyScheduler:register_system({
    category = tostring(systemInfo.phase),
    subcategory = systemInfo.category,
    name = systemInfo.name,
})
```

This mapping is applied consistently when existing systems are discovered, new systems are added, and systems are replaced.

Planck 1.x normally drops custom `SystemTable` fields while registering a
system. Because the adapter is installed before registration, it captures
`category` and `subcategory` automatically and refreshes Jabby's metadata.
Consumers do not need an additional binding call.

## Automatic schedule labels

The adapter inspects Planck's event dependency graphs and supplies every
system with the event names associated with its phase:

```luau
{
    category = "Visual",
    subcategory = "Camera",
    name = "FirstPerson",
    schedules = { "PreRender" }
}
```

Phases nested inside pipelines are resolved recursively. If a phase belongs to
multiple event graphs, the adapter supplies every distinct event name in sorted
order. Systems in Planck's default, manually-run graph receive no schedule
label.

## Distribution

The repository is packaged at its root so Bun can install it directly:

```json
"@rbxts/planck-jabby": "github:Loner1536/PlanckJabby#main"
```

The package retains the standard `@rbxts/planck-jabby` dependency key and import path inside consuming projects.
Jabby is a peer dependency so Git branch installs cannot create a stale nested
copy; applications provide their single top-level `@rbxts/jabby` installation.
