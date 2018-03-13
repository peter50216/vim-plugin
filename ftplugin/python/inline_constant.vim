" Inline constant, remove AAA = xxxxxx and change all AAA to xxxxxx.
if !exists('g:vim_inline_constant_map')
  let g:vim_inline_constant_map = '<Leader>pic'
endif

if g:vim_inline_constant_map != ''
  execute "nmap <buffer>" g:vim_inline_constant_map "<Plug>PythonInlineConstant"
endif
nnoremap <silent> <Plug>PythonInlineConstant :python InlineConstant()<CR>

python <<EOF
from __future__ import print_function
import vim
import re

def InlineConstant():
  (ridx, _) = vim.current.window.cursor
  current_row = vim.current.buffer[ridx-1]

  if ' = ' not in current_row:
    return

  if current_row[0] == ' ':
    print('Only top level constant is supported.')
    return

  const, val = current_row.split(' = ')

  if not (const[0].isupper or const[0] == '_') or '.' in const:
    return

  val += '\n'
  del vim.current.buffer[ridx-1]

  while vim.current.buffer[ridx-1].startswith(' '):
    val += vim.current.buffer[ridx-1] + '\n'
    del vim.current.buffer[ridx-1]

  cnt = 0
  first_row = None
  for i, row in enumerate(vim.current.buffer):
    cc = len(re.findall('\\b%s\\b' % const, row))
    if cc and first_row is None:
      first_row = i
    cnt += cc

  for i in xrange(len(vim.current.buffer)-1, -1, -1):
    line = vim.current.buffer[i]
    new_line = re.sub('\\b%s\\b' % const, val.strip(), line)
    if new_line != line:
      vim.current.buffer[i:i+1] = new_line.splitlines()
  if first_row is not None:
    vim.current.window.cursor = (first_row+1, 0)
  else:
    vim.current.window.cursor = (ridx, 0)

  print('%d occurrence of %r are replaced.' % (cnt, const))
  vim.command('silent! call repeat#set("\<Plug>PythonInlineConstant", -1)')
EOF

