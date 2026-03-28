-- lua/plugins/ui.lua
return {
  -- Colorscheme
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha',
        integrations = {
          telescope = { enabled = true },
          neotree = true,
          mason = true,
          gitsigns = true,
          which_key = true,
          treesitter = true,
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'catppuccin/nvim' },
    config = function()
      require('lualine').setup {
        options = {
          theme = 'catppuccin-mocha',
          globalstatus = true,
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
      }
    end,
  },

  -- Dashboard splash screen
  {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    cond = function()
      return vim.fn.argc() == 0
    end,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local alpha = require 'alpha'
      local dashboard = require 'alpha.themes.dashboard'

      dashboard.section.header.val = {
        '███╗   ██╗██╗   ██╗██╗███╗   ███╗',
        '████╗  ██║██║   ██║██║████╗ ████║',
        '██╔██╗ ██║██║   ██║██║██╔████╔██║',
        '██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║',
        '██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║',
        '╚═╝  ╚═══╝  ╚═══╝  ╚═╝ ╚═╝    ╚═╝',
      }

      dashboard.section.buttons.val = {
        dashboard.button('f', '  Find file',     '<cmd>Telescope find_files<cr>'),
        dashboard.button('r', '  Recent files',  '<cmd>Telescope oldfiles<cr>'),
        dashboard.button('g', '  Live grep',     '<cmd>Telescope live_grep<cr>'),
        dashboard.button('e', '  File explorer', '<cmd>Neotree toggle<cr>'),
        dashboard.button('q', '  Quit',          '<cmd>qa<cr>'),
      }

      alpha.setup(dashboard.opts)
    end,
  },
}
