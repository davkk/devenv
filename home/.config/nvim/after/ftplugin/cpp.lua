local set = vim.opt_local
set.shiftwidth = 2
set.tabstop = 2
set.softtabstop = 2
set.iskeyword = vim.api.nvim_get_option_info2("iskeyword", {}).default

local snippet = require "core.snippet"
snippet.add(
    "main",
    [[
#include <iostream>

int main() {
  std::cout << "Hello World!";
  return 0;
}
]],
    { buffer = 0 }
)
