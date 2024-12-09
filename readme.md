# exec.nvim

Executes the current file and inserts the output into a split buffer. Also searches for an `.env` file in the same directory as the script and passes all variables to the execution context.

## Installation & Usage

```lua
require('lazy').setup({
   "perryrh0dan/exec.nvim'
})
```

### Keymaps

```lua
vim.keymap.set('n', '<leader>e', function()
        require('exec').exec()
    end, { desc = "[E]xecute current file" })
```

## Roadmap

- [ ] Execute only visual selected text
