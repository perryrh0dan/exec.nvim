local group = vim.api.nvim_create_augroup('exec', {})

local M = {}

M.state = {
    buffer = nil,
    hidden = true,
}

M.exec = function()
    local progress = require('fidget').progress
    local progress_handle = progress.handle.create({ message = 'Running scipt', percentage = 0, lsp_client = { name = 'Execute' } })

    local function get_directory(path)
        local t = {}
        for str in string.gmatch(path, "([^" .. '/' .. "]+)") do
            table.insert(t, str)
        end
        return table.concat(t, '/', 1, #t - 1)
    end

    local function read_env_file(path)
        local parentPath = get_directory(path)
        local envPath = '/' .. parentPath .. '/.env'

        local variables = ''
        local file = io.open(envPath, 'r')
        if file ~= nil then
            for line in file:lines() do
                if string.find(line, '#') == nil then
                    variables = variables .. line .. ' '
                end
            end
        end

        return variables
    end

    local function buffer_exists(bufnr)
        local buffers = vim.api.nvim_list_bufs()
        for _, value in ipairs(buffers) do
            if value == bufnr then
                return vim.api.nvim_buf_is_loaded(value)
            end
        end
        return false
    end

    local filePath = vim.fn.expand('%:p')
    local variables = read_env_file(filePath)

    progress_handle:report({ percentage = 50 })

    vim.api.nvim_command('silent! write!')

    local env_command = "chmod +x " .. filePath .. " && " .. variables .. filePath

    local handle = io.popen(env_command)
    local stdout = handle:read("*a")
    handle:close()

    local output = {}
    for token in string.gmatch(stdout, "[^%c]+") do
        table.insert(output, token)
    end

    if M.state.bufnr == nil or not buffer_exists(M.state.bufnr) then
        vim.cmd('vnew')
        M.state.bufnr = vim.api.nvim_get_current_buf()
        if vim.fn.exists('&winfixbuf') == 1 then
            vim.cmd('set winfixbuf')
        end
        vim.keymap.set('n', 'q', function() vim.cmd('bdelete! ' .. M.state.bufnr) end,
            { buffer = M.state.bufnr, desc = 'Delete buffer' })
    elseif M.state.bufnr ~= nil and buffer_exists(M.state.bufnr) and M.state.hidden then
        vim.cmd('vert sb' .. M.state.bufnr)
    end

    M.state.hidden = false

    vim.api.nvim_buf_set_lines(M.state.bufnr, 0, vim.api.nvim_buf_line_count(M.state.bufnr), false, {})
    vim.api.nvim_buf_set_lines(M.state.bufnr, 0, #output, false, output)

    vim.api.nvim_create_autocmd({ 'BufHidden' }, {
        callback = function(data)
            if data.buf == M.state.bufnr then
                M.state.hidden = true
            end
        end,
        group = group,
        pattern = '*',
    })

    vim.api.nvim_create_autocmd({ 'BufDelete' }, {
        callback = function(data)
            if data.buf == M.state.bufnr then
                M.state.bufnr = nil
                M.state.hidden = true
            end
        end,
        group = group,
        pattern = '*',
    })

    progress_handle:finish()
end

return M
