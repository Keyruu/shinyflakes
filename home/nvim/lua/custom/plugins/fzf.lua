return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- calling `setup` is optional for customization
    require('fzf-lua').setup {}

    local fzf = require 'fzf-lua'

    vim.keymap.set('n', '<leader>ff', fzf.files, { desc = '[F]ind [f]iles' })
    vim.keymap.set('n', '<leader>fg', fzf.live_grep, { desc = '[F]ind live [g]rep' })
    vim.keymap.set('n', '<leader>fb', fzf.buffers, { desc = '[F]ind [b]uffers' })
    vim.keymap.set('n', '<leader>fh', fzf.helptags, { desc = '[F]ind [h]elp tags' })
    vim.keymap.set('n', '<leader>fk', fzf.keymaps, { desc = '[F]ind [K]eymaps' })
    vim.keymap.set('n', '<leader>fw', fzf.grep_cword, { desc = '[F]ind current [W]ord' })
    vim.keymap.set('n', '<leader>fd', fzf.diagnostics_document, { desc = '[F]ind [D]iagnostics' })
    vim.keymap.set('n', '<leader>fj', fzf.jumps, { desc = '[F]ind [J]umplist' })
    vim.keymap.set('n', '<leader>fr', fzf.resume, { desc = '[F]ind [R]esume' })
    vim.keymap.set('n', '<leader>f.', fzf.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', fzf.buffers, { desc = '[ ] Find existing buffers' })

    -- Slightly advanced example of overriding default behavior and them.
    vim.keymap.set('n', '<leader>/', fzf.lgrep_curbuf, { desc = '[/] Fuzzily find in current buffer' })
  end,
}
