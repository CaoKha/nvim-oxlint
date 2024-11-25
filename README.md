## nvim-oxlint
- a lazy vim plugin making use of oxling via lsp server

## references
- referenced from https://github.com/esmuellert/nvim-eslint/blob/main/lua/nvim-eslint/init.lua
- https://github.com/oxc-project/coc-oxc/blob/main/src/index.ts
- https://github.com/oxc-project/oxc/blob/main/crates/oxc_language_server/README.md

## installation
- lazy
```
{
  "soulsam480/nvim-oxlint",
  opts = {}
}
```

## Config
- same config as https://github.com/oxc-project/coc-oxc#configurations
- filetypes <- trigger
```lua
--- default
{
			"javascript",
			"javascriptreact",
			"javascript.jsx",
			"typescript",
			"typescriptreact",
			"typescript.tsx",
}
```
- root_dir <- default is `.git` parent
- capabilities <- default is default client capabilities
- handlers <- default is config change 
