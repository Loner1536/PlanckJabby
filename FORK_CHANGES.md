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

## Planned schedule labels

Schedule labels such as `PreRender` and `Heartbeat` are intentionally not described as released behavior yet. When implemented, this document should record the exact metadata contract and automatic Planck event discovery behavior.

## Distribution

The repository is packaged at its root so Bun can install it directly:

```json
"@rbxts/planck-jabby": "github:Loner1536/PlanckJabby#main"
```

The package retains the standard `@rbxts/planck-jabby` dependency key and import path inside consuming projects.
