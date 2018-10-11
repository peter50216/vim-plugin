if (exists("g:loaded_darkpi_localvimrc") || &cp)
  finish
endif
let g:loaded_darkpi_localvimrc = 1

augroup localvimrc
  autocmd!
  autocmd BufWinEnter * call s:LoadLocalVimrc()
augroup END

let s:path = expand('<sfile>:p:h')

function! s:LoadLocalVimrc()
  let l:dir = expand('%:p:h')
  if empty(l:dir)
    let l:dir = getcwd()
  endif
  python <<EOF
import os
import sys
import vim

sys.path.insert(0, vim.eval('s:path'))
import sign_lvimrc

d = os.path.abspath(vim.eval('l:dir'))
while d != '/':
  path = os.path.join(d, '.lvimrc')
  if os.path.exists(path):
    with open(path, 'r') as f:
      content, sign = sign_lvimrc.SplitSign(f.read())
    if sign is not None and sign_lvimrc.Verify(content, sign):
      vim.command('source %s' % path)
      break
    elif sign is None:
      print 'lvimrc %s is not signed, ignore.' % path
    else:
      print 'lvimrc %s has incorrect sign, ignore.' % path
  d = os.path.dirname(d)
EOF
endfunction
