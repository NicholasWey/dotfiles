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

      -- Orb highlight groups: 8 brightness levels, dark navy → bright cyan
      -- mirrors orb.py's orb_color(v): r=v*160+(1-v)*20, g=v*220+(1-v)*30, b=v*255+(1-v)*120
      local orb_ns = vim.api.nvim_create_namespace 'orb_dashboard'
      for i = 2, 9 do
        local v = (i - 1) / 8.0
        local r = math.floor(v * 160 + (1 - v) * 20)
        local g = math.floor(v * 220 + (1 - v) * 30)
        local b = math.floor(v * 255 + (1 - v) * 120)
        vim.api.nvim_set_hl(0, 'OrbHl' .. i, { fg = string.format('#%02x%02x%02x', r, g, b) })
      end

      -- Orb renderer (ported from orb.py)
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

      -- Returns rows (strings) and brightness matrix (index 1-9 per char)
      local function render_orb(t)
        local rows, bright = {}, {}
        for y = 3, 15 do
          local cols, brow = {}, {}
          for x = 0, ORB_W - 1 do
            local v = orb_sample(x, y, t)
            local idx = math.floor(v * (#ORB_CHARS - 1)) + 1
            cols[#cols + 1] = ORB_CHARS:sub(idx, idx)
            brow[#brow + 1] = idx
          end
          rows[#rows + 1] = table.concat(cols)
          bright[#bright + 1] = brow
        end
        return rows, bright
      end

      local orb_t = 0.0
      local last_rows, last_bright = {}, {}

      -- val is a function so alpha re-calls it on each redraw
      dashboard.section.header.val = function()
        local rows, bright = render_orb(orb_t)
        last_rows = rows
        last_bright = bright
        return rows
      end

      dashboard.section.buttons.val = {
        dashboard.button('f', '  Find file',     '<cmd>Telescope find_files<cr>'),
        dashboard.button('r', '  Recent files',  '<cmd>Telescope oldfiles<cr>'),
        dashboard.button('g', '  Live grep',     '<cmd>Telescope live_grep<cr>'),
        dashboard.button('e', '  File explorer', '<cmd>Neotree toggle<cr>'),
        dashboard.button('q', '  Quit',          '<cmd>qa<cr>'),
      }

      alpha.setup(dashboard.opts)

      local orb_buf = nil
      local orb_header_start = nil

      local function find_header_start(buf)
        if #last_rows == 0 then return nil end
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for i, line in ipairs(lines) do
          if line == last_rows[1] then return i - 1 end  -- 0-indexed
        end
        return nil
      end

      local function apply_colors()
        if not orb_buf or not vim.api.nvim_buf_is_valid(orb_buf) then return end
        if not orb_header_start then
          orb_header_start = find_header_start(orb_buf)
        end
        if not orb_header_start then return end
        vim.api.nvim_buf_clear_namespace(orb_buf, orb_ns, 0, -1)
        for row_i, brow in ipairs(last_bright) do
          local line = orb_header_start + row_i - 1
          for col_i, level in ipairs(brow) do
            if level > 1 then
              vim.api.nvim_buf_set_extmark(orb_buf, orb_ns, line, col_i - 1, {
                end_col = col_i,
                hl_group = 'OrbHl' .. level,
                priority = 200,
              })
            end
          end
        end
      end

      -- Drive animation: tick every 50ms (20fps), only while dashboard is visible
      local timer = vim.uv.new_timer()

      local function tick()
        if vim.bo.filetype ~= 'alpha' then
          timer:stop()
          return
        end
        orb_t = orb_t + 0.05
        pcall(require('alpha').redraw)
        apply_colors()
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'alpha',
        callback = function()
          orb_buf = vim.api.nvim_get_current_buf()
          orb_header_start = nil
          timer:start(0, 50, vim.schedule_wrap(tick))
        end,
      })
    end,
  },
}
