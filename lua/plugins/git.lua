-- lua/plugins/git.lua
return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'sindrets/diffview.nvim', cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose', 'DiffviewToggleFiles' } },
      'nvim-telescope/telescope.nvim',
    },
    cmd = 'Neogit',
    keys = {
      { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Open Neo[g]it' },
    },
    config = function()
      require('neogit').setup {
        integrations = {
          diffview = true,
          telescope = true,
        },
      }
    end,
  },
}
