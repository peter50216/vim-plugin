" Change python import to import only module.
if !exists('g:vim_change_import_map')
  let g:vim_change_import_map = '<Leader>pci'
endif

if g:vim_change_import_map != ''
  execute "nmap <buffer>" g:vim_change_import_map "<Plug>PythonChangeImport"
endif
nnoremap <silent> <Plug>PythonChangeImport :python ChangeImports()<CR>

python <<EOF
from __future__ import print_function
import vim
import re

def ChangeImports():
  (ridx, _) = vim.current.window.cursor
  import_row = vim.current.buffer[ridx-1]

  if ' import ' not in import_row or not import_row.startswith('from '):
    return
  pre, func = import_row.rsplit(' import ', 1)
  func, unused_sep, unused_comment = func.partition('#')
  func = func.strip()
  warn = False
  if not func[0].isupper():
    warn = True

  if '.' not in pre:
    mod = pre.replace('from ', '')
    pre = ''
  else:
    pre, mod = pre.rsplit('.', 1)
    pre = pre + ' '

  cnt = 0
  conf_import = 0
  new_row = '%simport %s' % (pre, mod)
  for row in vim.current.buffer:
    cnt += len(re.findall('\\b%s\\b' % func, row))
    if row != new_row:
      conf_import += len(re.findall('(import|as) %s$' % mod, row))

  new_mod = mod
  if conf_import:
    new_mod = 'new_' + mod

  vim.command('silent! %%s/\\v<%s>/%s.%s/g' % (func, new_mod, func))

  if new_mod != mod:
    new_row += ' as %s' % new_mod
  if warn:
    new_row += "  # WARN: function doesn't start with uppercase letter!"
  vim.current.buffer[ridx-1] = new_row

  vim.current.window.cursor = (ridx, 0)
  if ridx > 1 and vim.current.buffer[ridx-1] == vim.current.buffer[ridx-2]:
    vim.command('normal dd')
  else:
    vim.current.window.cursor = (ridx+1, 0)

  print('%d occurrence of %r are replaced.%s' % (
      cnt - 1, func, '' if new_mod == mod else ' (CONFLICT IMPORT)'))
  vim.command('silent! call repeat#set("\<Plug>PythonChangeImport", -1)')
EOF

