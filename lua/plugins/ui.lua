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

      -- Orb renderer (ported from orb.py)
      -- Renders rows 3-15 of the original 19-row frame (the non-empty orb body)
      local ORB_CHARS = ' .:-=+*#@'
      local ORB_W, ORB_CX, ORB_CY, ORB_R = 45, 22, 9, 14.0

      local function noise2d(x, y, t)
        return (
          math.sin(x * 0.8 + t * 1.1) * math.cos(y * 1.2 - t * 0.7)
          + math.sin(x * 1.5 - t * 0.9) * math.cos(y * 0.6 + t * 1.3) * 0.5
          + math.sin(x * 0.4 + y * 0.8 + t * 0.5) * 0.25
        ) / 1.75
      end

      local function orb_sample(x, y, t)
        local dx = x - ORB_CX
        local dy = (y - ORB_CY) * 2.1
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist >= ORB_R then return 0.0 end
        local nx = dx / ORB_R
        local ny = dy / ORB_R
        local nz = math.sqrt(math.max(0.0, 1.0 - nx * nx - ny * ny))
        local lx = math.sin(t * 0.7) * math.cos(t * 0.31) * 0.85 + math.sin(t * 1.13 + 1.7) * 0.15
        local ly = math.cos(t * 0.53) * math.sin(t * 0.19 + 0.9) * 0.45 + math.cos(t * 0.83) * 0.1
        local lz = 0.5 + math.sin(t * 0.41) * 0.2
        local diffuse = math.max(0.0, nx * lx + ny * ly + nz * lz)
        local n = noise2d(nx * 3 + t * 0.3, ny * 3 - t * 0.2, t) * 0.3
        local edge = (1.0 - dist / ORB_R) ^ 0.4
        return math.max(0.0, math.min(1.0, diffuse * 0.75 + n * edge + edge * 0.1))
      end

      local function render_orb(t)
        local rows = {}
        for y = 3, 15 do
          local cols = {}
          for x = 0, ORB_W - 1 do
            local v = orb_sample(x, y, t)
            local idx = math.floor(v * (#ORB_CHARS - 1)) + 1
            cols[#cols + 1] = ORB_CHARS:sub(idx, idx)
          end
          rows[#rows + 1] = table.concat(cols)
        end
        return rows
      end

      -- Animated header: val is a function so alpha re-calls it on each redraw
      local orb_t = 0.0
      dashboard.section.header.val = function()
        return render_orb(orb_t)
      end

      dashboard.section.buttons.val = {
        dashboard.button('f', '  Find file',     '<cmd>Telescope find_files<cr>'),
        dashboard.button('r', '  Recent files',  '<cmd>Telescope oldfiles<cr>'),
        dashboard.button('g', '  Live grep',     '<cmd>Telescope live_grep<cr>'),
        dashboard.button('e', '  File explorer', '<cmd>Neotree toggle<cr>'),
        dashboard.button('q', '  Quit',          '<cmd>qa<cr>'),
      }

      alpha.setup(dashboard.opts)

      -- Drive animation: tick every 50ms (20fps), only while dashboard is visible
      local timer = vim.uv.new_timer()

      local function tick()
        if vim.bo.filetype ~= 'alpha' then
          timer:stop()
          return
        end
        orb_t = orb_t + 0.05
        pcall(require('alpha').redraw)
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'alpha',
        callback = function()
          timer:start(0, 50, vim.schedule_wrap(tick))
        end,
      })
    end,
  },
}
