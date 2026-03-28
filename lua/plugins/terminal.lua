-- lua/plugins/terminal.lua
return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    keys = {
      { [[<c-\>]], desc = 'Toggle terminal' },
    },
    config = function()
      require('toggleterm').setup {
        open_mapping = [[<c-\>]],
        direction = 'float',
        float_opts = {
          border = 'curved',
          winblend = 10,
        },
        -- Use Git Bash on Windows
        shell = vim.fn.has 'win32' == 1 and 'bash' or vim.o.shell,
        on_open = function(term)
          vim.cmd 'startinsert!'
          vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<Esc>', [[<C-\><C-n>]], { noremap = true, silent = true })
        end,
      }
    end,
  },
}
