" Change python multiline string to implicit string join with newline
if !exists('g:vim_change_string_map')
  let g:vim_change_string_map = '<Leader>pcs'
endif

if g:vim_change_string_map != ''
  execute "vmap <buffer>" g:vim_change_string_map "<Plug>PythonChangeString"
endif
vnoremap <silent> <Plug>PythonChangeString :python ChangeString()<CR>

python <<EOF
from __future__ import print_function
import vim

def ChangeString():
  text_range = vim.current.range

  if len(text_range) < 2:
    print("Select at least 2 lines...")
    return

  # Doing backward is easier when inserting things.
  if text_range[0].count('"""') != 1 or text_range[-1].count('"""') != 1:
    print("First line / last line doesn't contains exactly one \"\"\" :(")
    return
  pre, s0 = text_range[0].split('"""')
  text_range[0] = "%s'%s\\n'" % (pre, s0)
  sn, post = text_range[-1].split('"""')
  text_range[-1] = "'%s'%s" % (sn, post)
  for i in range(1, len(text_range) - 1):
    text_range[i] = "'%s\\n'" % text_range[i]

  vim.command('normal gv=')
  vim.command('silent! call repeat#set("\<Plug>PythonChangeString", -1)')
EOF

