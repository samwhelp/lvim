local lsp_installer_servers = require("nvim-lsp-installer.servers")
local global = require("core.global")

local M = {}

M.setup_lsp = function(server_name, start_fn)
    local ok, server = lsp_installer_servers.get_server(server_name)
    if ok then
        server:on_ready(start_fn)
        if not server:is_installed() then
            server:install()
        end
    else
        print("Error starting lsp server " .. server_name)
    end
end

M.config_diagnostic = {
    virtual_text = false,
    update_in_insert = true,
    underline = true,
    severity_sort = true
}

M.config_lsp_signature = {
    bind = true,
    handler_opts = {border = "none"},
    hint_prefix = "   ",
    padding = " ",
    zindex = 200,
    transpancy = 0
}

M.icons = {
    error = "",
    warn = "",
    hint = "",
    info = ""
}

M.setup_diagnostic = function(custom_config_diagnostic)
    local local_config_diagnostic
    if custom_config_diagnostic ~= nil then
        local_config_diagnostic = custom_config_diagnostic
    else
        local_config_diagnostic = M.config_diagnostic
    end
    if vim.fn.has "nvim-0.5.1" > 0 then
        vim.lsp.handlers["textDocument/publishDiagnostics"] = function(_, result, ctx)
            local uri = result.uri
            local bufnr = vim.uri_to_bufnr(uri)
            if not bufnr then
                return
            end
            local diagnostics = result.diagnostics
            local ok, vim_diag = pcall(require, "vim.diagnostic")
            if ok then
                for i, diagnostic in ipairs(diagnostics) do
                    local rng = diagnostic.range
                    diagnostics[i].lnum = rng["start"].line
                    diagnostics[i].end_lnum = rng["end"].line
                    diagnostics[i].col = rng["start"].character
                    diagnostics[i].end_col = rng["end"].character
                end
                local namespace = vim.lsp.diagnostic.get_namespace(ctx.client_id)
                vim_diag.set(namespace, bufnr, diagnostics, local_config_diagnostic)
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    return
                end
                vim.fn.sign_define(
                    "DiagnosticSignError",
                    {
                        texthl = "DiagnosticSignError",
                        text = M.icons.error,
                        numhl = "DiagnosticSignError"
                    }
                )
                vim.fn.sign_define(
                    "DiagnosticSignWarn",
                    {
                        texthl = "DiagnosticSignWarn",
                        text = M.icons.warn,
                        numhl = "DiagnosticSignWarn"
                    }
                )
                vim.fn.sign_define(
                    "DiagnosticSignHint",
                    {
                        texthl = "DiagnosticSignHint",
                        text = M.icons.hint,
                        numhl = "DiagnosticSignHint"
                    }
                )
                vim.fn.sign_define(
                    "DiagnosticSignInfo",
                    {
                        texthl = "DiagnosticSignInfo",
                        text = M.icons.info,
                        numhl = "DiagnosticSignInfo"
                    }
                )
                vim_diag.show(namespace, bufnr, diagnostics, local_config_diagnostic)
            else
                vim.lsp.diagnostic.save(diagnostics, bufnr, ctx.client_id)
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    return
                end
                vim.fn.sign_define(
                    "LspDiagnosticsSignError",
                    {
                        texthl = "DiagnosticSignError",
                        text = M.icons.error,
                        numhl = "DiagnosticSignError"
                    }
                )
                vim.fn.sign_define(
                    "LspDiagnosticsSignWarning",
                    {
                        texthl = "DiagnosticSignWarn",
                        text = M.icons.warn,
                        numhl = "DiagnosticSignWarn"
                    }
                )
                vim.fn.sign_define(
                    "LspDiagnosticsSignHint",
                    {
                        texthl = "DiagnosticSignHint",
                        text = M.icons.hint,
                        numhl = "DiagnosticSignHint"
                    }
                )
                vim.fn.sign_define(
                    "LspDiagnosticsSignInformation",
                    {
                        texthl = "DiagnosticSignInfo",
                        text = M.icons.info,
                        numhl = "DiagnosticSignInfo"
                    }
                )
                vim.lsp.diagnostic.display(diagnostics, bufnr, ctx.client_id, local_config_diagnostic)
            end
        end
    else
        vim.lsp.handlers["textDocument/publishDiagnostics"] = function(_, _, params, client_id, _)
            local uri = params.uri
            local bufnr = vim.uri_to_bufnr(uri)
            if not bufnr then
                return
            end
            local diagnostics = params.diagnostics
            vim.lsp.diagnostic.save(diagnostics, bufnr, client_id)
            if not vim.api.nvim_buf_is_loaded(bufnr) then
                return
            end
            vim.fn.sign_define(
                "LspDiagnosticsSignError",
                {
                    texthl = "LspDiagnosticsSignError",
                    text = M.icons.error,
                    numhl = "LspDiagnosticsSignError"
                }
            )
            vim.fn.sign_define(
                "LspDiagnosticsSignWarning",
                {
                    texthl = "LspDiagnosticsSignWarning",
                    text = M.icons.warn,
                    numhl = "LspDiagnosticsSignWarning"
                }
            )
            vim.fn.sign_define(
                "LspDiagnosticsSignHint",
                {
                    texthl = "DiagnosticSignHint",
                    text = M.icons.hint,
                    numhl = "DiagnosticSignHint"
                }
            )
            vim.fn.sign_define(
                "LspDiagnosticsSignInformation",
                {
                    texthl = "DiagnosticSignInformation",
                    text = M.icons.info,
                    numhl = "DiagnosticSignInformation"
                }
            )
            vim.lsp.diagnostic.display(diagnostics, bufnr, client_id, local_config_diagnostic)
        end
    end
end

M.document_highlight = function(client)
    if client.resolved_capabilities.document_highlight then
        vim.api.nvim_exec(
            [[
            hi LspReferenceRead cterm=bold guibg=#41495A
            hi LspReferenceText cterm=bold guibg=#41495A
            hi LspReferenceWrite cterm=bold guibg=#41495A
            augroup lsp_document_highlight
                autocmd! * <buffer>
                autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
                autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
            augroup END
            ]],
            false
        )
    end
end

M.get_capabilities = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
            "documentation",
            "detail",
            "additionalTextEdits"
        }
    }
    local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if status_ok then
        capabilities = cmp_nvim_lsp.update_capabilities(capabilities)
    end
    return capabilities
end

M.toggle_virtual_text = function()
    if global.virtual_text == "no" then
        local config_diagnostic = {
            virtual_text = {
                prefix = "",
                spacing = 4
            },
            update_in_insert = true,
            underline = true,
            severity_sort = true
        }
        M.setup_diagnostic(config_diagnostic)
        if vim.api.nvim_buf_get_option(0, "modifiable") then
            vim.cmd("w")
        end
        global.virtual_text = "yes"
    else
        M.setup_diagnostic()
        if vim.api.nvim_buf_get_option(0, "modifiable") then
            vim.cmd("w")
        end
        global.virtual_text = "no"
    end
end

return M
