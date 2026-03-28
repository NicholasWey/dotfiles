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
        -- Transparent in both terminal and Neovide; system blur/acrylic provides
        -- the frosted glass effect in both cases.
        transparent_background = true,
        -- Match Windows Terminal Orb background (#070A12)
        color_overrides = {
          mocha = {
            base   = '#070A12',
            mantle = '#050810',
            crust  = '#04060E',
          },
        },
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

      -- Orb highlight groups: levels 2-9, dark navy → bright cyan
      -- matches orb.py's orb_color(v): r=v*160+(1-v)*20, g=v*220+(1-v)*30, b=v*255+(1-v)*120
      local orb_ns = vim.api.nvim_create_namespace 'orb_dashboard'

      local function set_orb_hls()
        for i = 2, 9 do
          local v = (i - 1) / 8.0
          local r = math.floor(v * 160 + (1 - v) * 20)
          local g = math.floor(v * 220 + (1 - v) * 30)
          local b = math.floor(v * 255 + (1 - v) * 120)
          vim.api.nvim_set_hl(0, 'OrbHl' .. i, { fg = string.format('#%02x%02x%02x', r, g, b) })
        end
      end
      set_orb_hls()
      -- Re-apply if colorscheme reloads
      vim.api.nvim_create_autocmd('ColorScheme', { callback = set_orb_hls })

      -- Orb renderer (ported from orb.py)
      local ORB_CHARS = ' .:-=+*#@'
      local ORB_W, ORB_CX, ORB_CY, ORB_R = 45, 22, 9, 14.0
      local ORB_ROWS = 13 -- render loop y=3..15

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

      -- Returns text rows and per-char brightness indices (1-9)
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

      -- Static initial frame for alpha setup (alpha evaluates val once at setup)
      local orb_t = 0.0
      local init_rows, _ = render_orb(orb_t)
      dashboard.section.header.val = init_rows

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
      local timer = vim.uv.new_timer()

      -- Find the header: first block of ORB_ROWS consecutive lines that
      -- (a) contain only orb chars, (b) are all non-empty (padding rows are
      -- empty strings ""; blank orb rows written by alpha have centering spaces
      -- so they are non-empty), and (c) have at least one non-space orb char.
      local function find_header_start(buf)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for i = 1, #lines - ORB_ROWS + 1 do
          local ok, has_content = true, false
          for j = 0, ORB_ROWS - 1 do
            local line = lines[i + j]
            if #line == 0 then ok = false; break end          -- empty = padding
            if line:match('[^ .:%-%=+*#@]') then ok = false; break end
            if line:match('[.:%-%=+*#@]') then has_content = true end
          end
          if ok and has_content then return i - 1 end
        end
        return nil
      end

      local function tick()
        if vim.bo.filetype ~= 'alpha' then
          timer:stop()
          return
        end
        if not orb_buf or not vim.api.nvim_buf_is_valid(orb_buf) then return end

        orb_t = orb_t + 0.05
        local rows, bright = render_orb(orb_t)

        -- Locate header once, then cache
        if not orb_header_start then
          orb_header_start = find_header_start(orb_buf)
          if not orb_header_start then return end
        end

        -- Center rows to match alpha's initial layout
        local pad_n = math.max(0, math.floor((vim.api.nvim_win_get_width(0) - ORB_W) / 2))
        local pad = string.rep(' ', pad_n)
        local centered = {}
        for _, row in ipairs(rows) do
          centered[#centered + 1] = pad .. row
        end

        -- Directly update buffer text (bypass alpha redraw entirely)
        local ma = vim.bo[orb_buf].modifiable
        vim.bo[orb_buf].modifiable = true
        vim.api.nvim_buf_set_lines(orb_buf, orb_header_start, orb_header_start + #rows, false, centered)
        vim.bo[orb_buf].modifiable = ma

        -- Apply per-character colors via extmarks (offset by centering pad)
        vim.api.nvim_buf_clear_namespace(orb_buf, orb_ns, orb_header_start, orb_header_start + #rows)
        for row_i, brow in ipairs(bright) do
          local line = orb_header_start + row_i - 1
          for col_i, level in ipairs(brow) do
            if level > 1 then
              vim.api.nvim_buf_set_extmark(orb_buf, orb_ns, line, pad_n + col_i - 1, {
                end_col = pad_n + col_i,
                hl_group = 'OrbHl' .. level,
                priority = 200,
              })
            end
          end
        end
      end

      local function start_orb()
        orb_buf = vim.api.nvim_get_current_buf()
        -- Keep cached orb_header_start across BufEnter trips (Telescope, etc.)
        -- Only VimResized clears it, since alpha re-renders on window size changes
        if not timer:is_active() then
          timer:start(0, 50, vim.schedule_wrap(tick))
        end
      end

      -- FileType fires on first load (pattern matches filetype here)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'alpha',
        callback = start_orb,
      })
      -- BufEnter fires when returning from Telescope/Neotree/etc.
      -- pattern = 'alpha' matches buffer names, not filetypes — use callback check instead
      vim.api.nvim_create_autocmd('BufEnter', {
        callback = function()
          if vim.bo.filetype == 'alpha' then start_orb() end
        end,
      })
      -- Window resize changes alpha's layout; drop the cached header position
      vim.api.nvim_create_autocmd('VimResized', {
        callback = function()
          if vim.bo.filetype == 'alpha' then orb_header_start = nil end
        end,
      })
    end,
  },
}
