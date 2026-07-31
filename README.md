# GH-issues.nvim
Easy reading of issues and pull request reviews.
After opening the pull request reviews list, populates the comments into their respective files

# Installation
Load it with your favourite plugin manager.
create a `gh-issues.lua` file in `~/.config/nvim/after/plugin/`

## Setup
These are the default values
```lua
require("gh-issues").setup({
    keybinds = {
        issues = "<leader>gi",
        pull_request = "<leader>gpr",
        clean_cache = "<leader>gc",
        add_to_quickfix = "<C-a>",
    },
    repository = "origin",
    accounts = nil
})
```

`accounts` is an optional field for if you use ssh aliases
```lua
    accounts = {
        personal = "my_personal_user",
        work = "my_work_user",
    },
```

# Usage
Call `:GhIssues` or `:GhPullRequest` to populate a quickfix list with issues or PRs.
Optionally provide a remote:
```vim
:GhPullRequest upstream
```
press `<CR>` to open the ui.
<img width="1280" height="705" alt="image" src="https://github.com/user-attachments/assets/3b70a263-8bb3-4f8c-acfa-ed38053a8ac8" />

In the pull request window, press `<C-a>` to populate the review comments in quickfix.
use your cnext/cprev keybinds to quickly navigate through them and see your review comments in place

Comments become diagnostics in the source files, which you can navigate either with diagnostics mapping or using cnext/cprev
<img width="1280" height="705" alt="image" src="https://github.com/user-attachments/assets/93c56141-e81d-4398-ad70-a370bdc8707b" />
