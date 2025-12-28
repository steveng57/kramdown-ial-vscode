# Kramdown IAL (Markdown Injection)

VS Code extension that injects a TextMate grammar into Markdown to give **Kramdown inline attribute lists** (`{: ... }`) distinct scopes for syntax highlighting.

Examples it targets:

- `{: .sjg-list }`
- `{:target='_blank'}`
- `{: target="_blank" .btn #hero }`

## What it does

- Adds TextMate scopes inside `{: ... }` so themes / token rules can color them.
- Injects into Markdown (`text.html.markdown`) and tries to avoid fenced / raw code regions (best-effort).

## What it does not do

- No validation, parsing, IntelliSense, or formatting — this is **syntax highlighting only**.

## Use (local development)

1. Open this repo folder in VS Code.
2. Press `F5` (Run Extension).
3. In the new “Extension Development Host” window, open a Markdown file containing `{: ... }`.
4. Run `Developer: Inspect Editor Tokens and Scopes` on the `{: ... }` region.

You should see scopes such as:

- `meta.attribute-list.kramdown`
- `punctuation.definition.attribute-list.begin.kramdown`
- `punctuation.definition.attribute-list.end.kramdown`
- `entity.other.attribute-name.class.kramdown` (e.g. `.btn`)
- `entity.other.attribute-name.id.kramdown` (e.g. `#hero`)
- `entity.other.attribute-name.kramdown` and `keyword.operator.assignment.kramdown` (e.g. `key=`)

## Optional: color rules

If your theme doesn’t color these scopes by default, add workspace or user settings like:

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