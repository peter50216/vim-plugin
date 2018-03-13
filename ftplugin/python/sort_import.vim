" Sort python imports
if !exists('g:vim_sort_import_map')
  let g:vim_sort_import_map = '<Leader>psi'
endif

if g:vim_sort_import_map != ''
  execute "vnoremap <buffer>" g:vim_sort_import_map ":python SortImports()<CR>"
endif

python <<EOF
from __future__ import print_function
import vim

def SortImports():
  text_range = vim.current.range

  # Doing backward is easier when inserting things.
  i = len(text_range) - 1
  while i >= 0:
    line = text_range[i]
    s, _, c = line.partition('#')
    if ')' in s or ',' in s:
      if ')' in s:
        j = i
        s = ''
        c = ''
        while j >= 0:
          ss, _, cc = text_range[j].partition('#')
          s = ss + s
          c = cc + c
          j -= 1
          if '(' in s:
            break
      else:
        j = i - 1
      pre, _, ids = s.partition(' import ')
      ids = [x.strip() for x in ids.replace(')', '').replace('(', '').split(',')]
      pre = pre.strip()
      text_range[j+1:i+1] = ['%s import %s%s' % (pre, x, (' #' + c if c else '')) for x in ids]
      i = j
    else:
      i -= 1
  def _ImportLineToKey(line):
    if line.startswith('import '):
      return line.replace('import ', '').lower()
    return line.replace('from ', '').replace(' import ', '.').lower()
  text_range[:] = sorted(text_range, key=_ImportLineToKey)
EOF

