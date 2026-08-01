# GH-issues.nvim
Easy reading of issues and pull request reviews.
After opening the pull request reviews list, populates the comments into their respective files

# Installation
1) Install the github CLI tool and login to the relevant accounts.
2) Load gh-issues with your favourite plugin manager.

Packer:
```lua
use("jjholt/gh-issues.nvim")
```
3) create a `gh-issues.lua` file in `~/.config/nvim/after/plugin/` or whever you keep your plugin after files.
```lua
require("gh-issues").setup()
```
## Setup
These are the default values
```lua
require("gh-issues").setup({
    keybinds = {
        issues = "<leader>gi",
        pull_request = "<leader>gpr",
        clear_markers = "<leader>gc",
        add_to_quickfix = "<C-a>",
        nav_review_comments = {"]c", "[c"},

    },
    repository = "origin",
    accounts = nil
})
```

`accounts` is an optional field for if you use ssh aliases.

For example, I use one key for personal projects and one for work project, so all my repos have an address like `personal:owner/repo.git` instead of the usual `git@github.com:owner/repo.git`.
I can assign the alias to an account, so we can seamlessly request the token from the github cli from any of the users, 
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

Find other branches with changes that overlap your chosen branch  
<img width="1280" height="705" alt="image" src="https://github.com/user-attachments/assets/a8d1db27-a50f-4656-998b-a29de2e44ef9" />

Open diff highlighting the hunks (work in progress)
<img width="1280" height="705" alt="image" src="https://github.com/user-attachments/assets/8afc629f-7aba-45ef-a1a4-9eb1d5dd9171" />
