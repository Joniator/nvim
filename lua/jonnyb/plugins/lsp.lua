return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "williamboman/mason-lspconfig.nvim",
    "folke/neodev.nvim",
  },
  config = function()
    require("mason").setup()

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local function lspmap(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-T>.
        lspmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        lspmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        lspmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        lspmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        lspmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

        -- Fuzzy find all the symbols in your current workspace
        --  Similar to document symbols, except searches over your whole project.
        lspmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- Rename the variable under your cursor
        --  Most Language Servers support renaming across files, etc.
        lspmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        lspmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        -- Opens a popup that displays documentation about the word under your cursor
        --  See `:help K` for why this keymap
        lspmap("K", vim.lsp.buf.hover, "Hover Documentation")

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header
        lspmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = {
                "${3rd}/luv/library",
                unpack(vim.api.nvim_get_runtime_file("", true)),
              },
            },
            completion = {
              callSnippet = "Replace",
            },
            diagnostics = { disable = { "missing-fields" } },
          },
        },
      },
    }

    local ensure_installed = vim.tbl_keys(servers)
    vim.list_extend(ensure_installed, {
      "stylua",
      "jdtls",
    })
    require("mason-tool-installer").setup({
      ensure_installed = ensure_installed,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    ---@diagnostic disable-next-line: cast-local-type
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

    require("mason-lspconfig").setup({
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    })
  end,
}
