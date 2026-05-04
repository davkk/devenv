if vim.fn.executable "eslint_d" == 1 and vim.fs.root(0, { ".eslintrc", "eslint.config.js" }) then
    vim.opt_local.formatprg = "eslint_d --stdin --stdin-filename % --fix-to-stdout"
end
