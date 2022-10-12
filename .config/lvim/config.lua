-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "catppuccin"


-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.dap.active = true

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "latex",
  "cpp",
}

--lvim.builtin.treesitter.highlight.disable = {}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true


-- Additional Plugins
lvim.plugins = {
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  { "lervag/vimtex" },
  { 'catppuccin/nvim' },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    module = "persistence",
    config = function()
      require("persistence").setup()
    end,
  },
  { "rcarriga/nvim-dap-ui",
    requires = { "mfussenegger/nvim-dap" } },
  { 'michaelb/sniprun', run = 'bash ./install.sh' },
}



vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha

require("catppuccin").setup()

vim.cmd [[colorscheme catppuccin]]

--Cosas de latex
vim.g.tex_flavor = 'latex'
vim.g.vimtex_view_method = 'zathura'
vim.g.vimtex_quickfix_mode = 0
vim.opt.conceallevel = 1
vim.opt.wrap = true
vim.g.tex_conceal = 'abdmg'


-- vim.api.nvim_set_keymap('v', 'f', '<Plug>SnipRun', { silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>f', '<Plug>SnipRunOperator', { silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>ff', '<Plug>SnipRun', { silent = true })


--To modify a single Lunarvim keymapping
-- lvim.keys.normal_mode["<C-t>"] = ":terminal<CR>Acd $VIM_DIR<CR>"
--To remove keymappings set by Lunarvim
lvim.keys.normal_mode["<S-r>"] = false
-- lvim.keys.normal_mode["<C-t>"] = function()
--   vim.api.nvim_command("ToggleTerm dir=" .. vim.fn.expand("%:h"))
-- end

--Which_key SnipRun menu
lvim.builtin.which_key.mappings["r"] = {
  name = "SnipRun",
  r = { "<cmd>lua require'sniprun'.run()<CR>", "SnipRun" },
}




-- c/cpp/rust debug
local join_paths = require("lvim.utils").join_paths
local function get_install_path(package_name)
  return require("mason-registry").get_package(package_name):get_install_path()
end

local lldb_path = join_paths(get_install_path "codelldb", "extension") or ""
local codelldb_path = join_paths(lldb_path, "adapter/codelldb")
local liblldb_path = join_paths(lldb_path, "lldb/lib/liblldb.so")
if vim.fn.has "mac" == 1 then
  liblldb_path = join_paths(lldb_path, "lldb/lib/liblldb.dylib")
end

local dap = require 'dap'
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  -- host = "127.0.0.1",
  executable = {
    command = codelldb_path,
    args = { "--liblldb", liblldb_path, "--port", "${port}" },
    -- On windows you may have to enable this:
    -- detached = true,
  },
}

local uv = vim.loop

dap.configurations.cpp = {
  {
    name = "Launch c/cpp (codelldb)",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", uv.cwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = true,
    runInTerminal = false,
  },
  {
    name = "Launch c/cpp (codelldb) with args",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", uv.cwd() .. "/", "file")
    end,
    args = function()
      local args = {}
      while true do
        local i = #args + 1
        local arg = vim.fn.input(string.format("Argument [%d]: ", i))
        if arg == "" then
          break
        end
        args[i] = arg
      end
      return args
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = true,
    runInTerminal = false,
  },
}

dap.configurations.c = dap.configurations.cpp

dap.configurations.rust = {
  {
    name = "Launch rust (codelldb)",
    type = "codelldb",
    request = "launch",
    program = function()
      local metadata_json = vim.fn.system "cargo metadata --format-version 1 --no-deps"
      local metadata = vim.json.decode(metadata_json)

      local target_name = metadata.packages[1].targets[1].name
      local target_dir = metadata.target_directory

      return target_dir .. "/debug/" .. target_name
    end,
    env = vim.fn.environ,
    cwd = "${workspaceFolder}",
    stopOnEntry = true,
    runInTerminal = false,
    externalConsole = true,
  },
}
