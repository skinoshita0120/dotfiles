return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = {
        "ts_ls",
        "vue_ls",
        "eslint",
        "lua_ls",
        "pyright",
        "ruff",
        "rust_analyzer",
        "jdtls",
      },
      automatic_enable = {
        -- `jdtls` is started by nvim-jdtls in `after/ftplugin/java.lua`;
        -- enabling it here as well would spawn a second server per buffer.
        exclude = { "rust_analyzer", "jdtls" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("lsp.config")
    end
  },
}
