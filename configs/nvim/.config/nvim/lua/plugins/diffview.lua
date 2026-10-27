return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewFileHistory",
  },
  init = function()
    function _G.dvx()
      local toplevel = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
      if vim.v.shell_error ~= 0 then
        return ""
      end

      local attributes = toplevel .. "/.gitattributes"
      if vim.fn.filereadable(attributes) == 0 then
        return ""
      end

      local specs = {}
      for _, line in ipairs(vim.fn.readfile(attributes)) do
        local pattern, attrs = line:match("^%s*([^#%s]%S*)%s+(.*)$")
        -- linguist treats both `linguist-generated` and `linguist-generated=true` as generated
        local generated = pattern
          and vim.iter(vim.split(attrs, "%s+", { trimempty = true })):any(function(attr)
            return attr == "linguist-generated" or attr == "linguist-generated=true"
          end)
        if generated then
          -- gitattributes patterns without a slash match at any depth
          if pattern:find("/", 1, true) then
            pattern = pattern:gsub("^/", "")
          else
            pattern = "**/" .. pattern
          end
          table.insert(specs, ("':(exclude,glob)%s'"):format(pattern))
        end
      end

      return table.concat(specs, " ")
    end
  end,
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Open git diff view" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close git diff view" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Open file git history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Open git history" },
  },
  opts = {
    file_panel = {
      win_config = {
        position = "bottom",
        height = 16,
      },
    },
  },
}
