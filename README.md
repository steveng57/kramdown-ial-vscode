# Kramdown IAL (Markdown Injection)

This is a tiny local VS Code extension that injects a TextMate grammar into Markdown to give **Kramdown inline attribute lists** distinct scopes.

Examples it targets:

- `{: .sjg-list }`
- `{:target='_blank'}`
- `{: target="_blank" .btn #hero }`

## What it does

- Adds TextMate scopes to `{: ... }` blocks so themes / workspace token rules can color them.
- Avoids fenced code blocks and raw blocks (best-effort) via the injection selector.

## What it does NOT do

- No validation / IntelliSense / parsing — this is syntax highlighting only.

## Use (local development)

1. Open this folder in VS Code: `tools/vscode-kramdown-ial`
2. Press `F5` (Run Extension)
3. In the new "Extension Development Host" window, open one of your posts under `_posts/.../*.md`
4. Run `Developer: Inspect Editor Tokens and Scopes` on the `{: ... }` region to confirm you see `meta.attribute-list.kramdown` scopes.

## Optional: color rules

If your theme doesn’t color these scopes by default, add workspace rules like:

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
      "name": "Kramdown IAL class/id",
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

## Install into your normal VS Code (VSIX)

If you don't want to use the Extension Development Host window, you can package and install this as a VSIX:

1. Open a terminal in this folder: `tools/vscode-kramdown-ial`
2. Run: `npx @vscode/vsce package --no-dependencies`
3. In VS Code: `Extensions: Install from VSIX...` and pick the generated `.vsix`
4. `Developer: Reload Window`