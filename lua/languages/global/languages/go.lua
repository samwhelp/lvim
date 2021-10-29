-- Install Lsp server
-- :LspInstall gopls

-- Install debugger
-- :DIInstall go_delve

local global = require("core.global")
local funcs = require("core.funcs")
local languages_setup = require("languages.global.utils")
local nvim_lsp = require("lspconfig")
local nvim_lsp_util = require("lspconfig/util")
local lsp_signature = require("lsp_signature")
local default_debouce_time = 150
local lsp_installer = require("nvim-lsp-installer")
local lsp_installer_servers = require("nvim-lsp-installer.servers")
local dap = require("dap")

local language_configs = {}

language_configs["lsp"] = function()
    local function start_gopls()
        nvim_lsp.gopls.setup {
            cmd = {global.lsp_path .. "lsp_servers/go/gopls"},
            flags = {
                debounce_text_changes = default_debouce_time
            },
            autostart = true,
            filetypes = {"go", "gomod"},
            on_attach = function(client, bufnr)
                table.insert(global["languages"]["go"]["pid"], client.rpc.pid)
                if client.resolved_capabilities.document_formatting then
                    vim.api.nvim_exec(
                        [[
                    augroup LspAutocommands
                        autocmd! * <buffer>
                        autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()
                    augroup END
                    ]],
                        true
                    )
                end
                vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
                lsp_signature.on_attach(languages_setup.config_lsp_signature)
                languages_setup.document_highlight(client, bufnr)
            end,
            on_init = function(client)
            end,
            capabilities = languages_setup.get_capabilities(),
            root_dir = nvim_lsp_util.root_pattern("."),
            handlers = languages_setup.show_line_diagnostics()
        }
    end
    local ok, gopls = lsp_installer_servers.get_server("gopls")
    if ok then
        if not gopls:is_installed() then
            gopls:install()
            lsp_installer.on_server_ready(
                function()
                    start_gopls()
                end
            )
        else
            start_gopls()
        end
    end
end

language_configs["dap"] = function()
    if funcs.dir_exists(global.lsp_path .. "dapinstall/go_delve/") ~= true then
        vim.cmd("DIInstall go_delve")
    end
    dap.adapters.go = function(callback, config)
        local handle
        local pid_or_err
        local port = 38697
        handle, pid_or_err =
            vim.loop.spawn(
            "dlv",
            {
                args = {"dap", "-l", "127.0.0.1:" .. port},
                detached = true
            },
            function(code)
                handle:close()
                print("Delve exited with exit code: " .. code)
            end
        )
        vim.defer_fn(
            function()
                callback({type = "server", host = "127.0.0.1", port = port})
            end,
            100
        )
    end
    dap.configurations.go = {
        {
            type = "go",
            name = "Launch",
            request = "launch",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end
        },
        {
            type = "go",
            name = "Launch test",
            request = "launch",
            mode = "test",
            program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end
        }
    }
end

return language_configs
