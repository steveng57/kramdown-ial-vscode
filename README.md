# Kramdown IAL (Markdown Injection)

VS Code extension that injects a TextMate grammar into Markdown to give **Kramdown inline attribute lists** (`{: ... }`) distinct scopes for syntax highlighting.  Also includes compatible dark and light VS Code themes.

Examples it targets:

- `{: .css-classes }`
- `{:target='_blank'}`
- `{: target="_blank" .btn #hero }`
- `{:ref-name: #myid .my-class}` (attribute list definition)
- `{::comment}ignored{:/comment}` (extension)
- `^` (end-of-block marker line)
- `# Heading {#my-id}` (explicit header id)

## What it does

- Adds TextMate scopes inside `{: ... }` so themes / token rules can colour them.
- Injects into Markdown (`text.html.markdown`) and tries to avoid fenced / raw code regions (best-effort).

## What it does not do

- No validation, parsing, IntelliSense, or formatting — this is **syntax highlighting only**, so it will not interfere with any language extensions for markdown or kramdown.

## Included Colour Themes

Not all colour themes support markdown or kramdown syntax.  This extension now includes two color themes that are optimized to work with markdown, kramdown, and the IAL:

- **Kramdown Dark**: A dark theme designed for comfortable reading and editing (recommended).
- **Kramdown Light**: A light theme for bright environments and high contrast.

To use these themes:
1. Open the Command Palette (`Ctrl+Shift+P`).  Type and select `Preferences: Color Theme`.
2. Or use `Ctrl+K,Ctrl+T`.
3. Choose either **Kramdown Dark** or **Kramdown Light** from the list.

These themes are available in addition to the Kramdown IAL syntax highlighting.

## Use (local development)

1. Open this repo folder in VS Code.
2. Press `F5` (Run Extension).
3. In the new “Extension Development Host” window, open a Markdown file containing `{: ... }`.
4. Run `Developer: Inspect Editor Tokens and Scopes` on the `{: ... }` region.

You should see scopes such as:

- `meta.attribute-list.kramdown`
- `meta.attribute-list-definition.kramdown`
- `meta.extension.kramdown`
- `meta.end-of-block-marker.kramdown`
- `meta.header-id.kramdown`
- `punctuation.definition.attribute-list.begin.kramdown`
- `punctuation.definition.attribute-list.end.kramdown`
- `entity.other.attribute-name.class.kramdown` (e.g. `.btn`)
- `entity.other.attribute-name.id.kramdown` (e.g. `#hero`)
- `entity.other.attribute-name.kramdown` and `keyword.operator.assignment.kramdown` (e.g. `key=`)

## Optional: colour rules

Not all themes support markdown or kramdown scopes.  The `Kramdown Dark` and `Kramdown Light` themes included in this extension do, so these rules are not needed if you use theme.

However, tf your theme doesn’t colour these scopes by default, add workspace or user settings like:

```jsonc
"editor.tokenColorCustomizations": {
  "textMateRules": [
    {
      "name": "Kramdown IAL delimiters",
      "scope": [
        "punctuation.definition.attribute-list.begin.kramdown",
        "punctuation.definition.attribute-list.end.kramdown"
      ],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "Kramdown IAL attributes",
      "scope": [
        "entity.other.attribute-name.class.kramdown",
        "entity.other.attribute-name.id.kramdown",
        "entity.other.attribute-name.kramdown",
        "keyword.operator.assignment.kramdown"
      ],
      "settings": { "foreground": "#79C0FF" }
    },
    {
      "name": "Kramdown strings",
      "scope": [
        "string.quoted.double.kramdown",
        "string.quoted.single.kramdown"
      ],
      "settings": { "foreground": "#79C0FF" }
    },
    {
      "name": "Kramdown extension delimiters",
      "scope": [
        "punctuation.definition.extension.begin.kramdown",
        "punctuation.definition.extension.end.kramdown",
        "punctuation.definition.extension.endtag.begin.kramdown",
        "punctuation.definition.extension.endtag.end.kramdown",
        "punctuation.definition.extension.self-close.kramdown"
      ],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "Kramdown extension name",
      "scope": [
        "entity.name.function.kramdown"
      ],
      "settings": { "foreground": "#79C0FF" }
    },
    {
      "name": "Kramdown end-of-block marker",
      "scope": [
        "punctuation.definition.end-of-block-marker.kramdown"
      ],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "Kramdown explicit header id delimiters",
      "scope": [
        "punctuation.definition.header-id.begin.kramdown",
        "punctuation.definition.header-id.end.kramdown"
      ],
      "settings": { "foreground": "#FFA657" }
    }
  ]
}
```

## Install (VSIX)

This repo is set up for local packaging via `vsce`:

1. From this folder, run: `npm run package`
2. In VS Code, run: `Extensions: Install from VSIX...`
3. Pick the generated `.vsix` file (for example `kramdown-ial-injection-0.0.1.vsix`).
4. Run: `Developer: Reload Window`

## CI/CD (GitHub Actions)

This repo includes workflows that can:

- Build and package a `.vsix` on every PR and on pushes to `main` (uploaded as a workflow artifact)
- Publish to the VS Code Marketplace on version tags (or manually)

### Package on PR / main

- Workflow: `.github/workflows/ci.yml`
- Output: a `vsix` artifact containing `*.vsix`

### Publish to Marketplace

- Workflow: `.github/workflows/publish.yml`
- Triggers: push a tag like `v0.1.15`

Prerequisites:

1. Update `publisher` in `package.json` to your actual Marketplace publisher ID (it is currently `local`).
2. Create a Marketplace Personal Access Token (PAT) and add it as a repo secret named `VSCE_PAT`.

Notes:

- Publishing will fail if the extension version in `package.json` is already published.
- Tagging does not automatically bump versions; bump `package.json` first, then tag.
- The publish workflow validates that the tag version matches `package.json`.

### Release script (PowerShell)

If you don't want to remember the tag/push steps, use `release.ps1` from the repo root:

Option A (you already bumped/committed the version):

1. Commit your version bump in `package.json`
2. Run: `./release.ps1`

Option B (auto-bump + commit + tag + push):

- Patch bump: `./release.ps1 -Bump patch`
- Minor bump: `./release.ps1 -Bump minor`
- Major bump: `./release.ps1 -Bump major`

This reads the version from `package.json`, creates the matching tag (e.g. `v0.1.16`), pushes `main`, then pushes the tag to trigger the publish workflow.