local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

-- Prefer the multi-project root (where the wrapper and settings live) over the
-- nearest subproject, so Gradle imports the whole build with its wrapper.
local root_dir = vim.fs.root(0, {
  { "gradlew", "mvnw", "settings.gradle", "settings.gradle.kts" },
  { "build.gradle", "build.gradle.kts", "pom.xml" },
})
if not root_dir then
  return
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_ok, cmp = pcall(require, "cmp_nvim_lsp")
if cmp_ok then
  capabilities = cmp.default_capabilities(capabilities)
end

local mason_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
local jdtls_cmd = vim.fn.exepath("jdtls")
if jdtls_cmd == "" then
  jdtls_cmd = mason_path .. "/bin/jdtls"
end
if vim.fn.executable(jdtls_cmd) == 0 then
  return
end

-- Ask the `java` on PATH for its home instead of hardcoding a path; this also
-- sees through the macOS `/usr/bin/java` stub and version-manager shims.
-- Cached because ftplugin runs for every Java buffer.
local function java_home()
  if vim.g.jdtls_java_home == nil then
    local home = ""
    if vim.fn.executable("java") == 1 then
      local out = vim.fn.system({ "java", "-XshowSettings:properties", "-version" })
      home = vim.v.shell_error == 0 and out:match("java%.home = ([^\r\n]+)") or ""
    end
    vim.g.jdtls_java_home = home
  end
  return vim.g.jdtls_java_home ~= "" and vim.g.jdtls_java_home or nil
end

-- Include a hash of the full path so worktrees with the same directory name
-- do not share (and corrupt) one workspace.
local project_name = vim.fn.fnamemodify(root_dir, ":t") .. "-" .. vim.fn.sha256(root_dir):sub(1, 8)
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name

jdtls.start_or_attach({
  capabilities = capabilities,
  cmd = {
    jdtls_cmd,
    -- jdtls sets no max heap, so the JVM default (1/4 of RAM) applies to every
    -- instance; cap it since each nvim runs its own server.
    "--jvm-arg=-Xmx2g",
    "-data",
    workspace_dir,
  },
  root_dir = root_dir,
  settings = {
    java = {
      import = {
        gradle = {
          -- Pin the JDK Gradle runs on, so daemons are not split by JDK.
          java = { home = java_home() },
        },
      },
    },
  },
})
