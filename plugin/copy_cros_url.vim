if (exists("g:loaded_darkpi_copy_cros_url") || &cp)
  finish
endif
let g:loaded_darkpi_copy_cros_url = 1

nnoremap <silent> <Plug>CopyCrosURL :call CopyCrosURL(0)<CR>
nnoremap <silent> <Plug>CopyCrosURLWithHash :call CopyCrosURL(1)<CR>

let s:base_path_dict = {}
let s:info_dict = {}
let s:upstream_dict = {}
let s:remote_dict = {}

function! CopyCrosURL(use_hash)
  let l:file = expand('%:p')
  if has_key(s:base_path_dict, l:file)
    let l:base_path = s:base_path_dict[l:file]
  else
    exec "lcd " . expand('%:p:h')
    let l:base_path = trim(system("repo list -p -f " . shellescape(expand('%'))))
    lcd -
    if v:shell_error != 0
      echoerr l:base_path
      return
    endif
    let s:base_path_dict[l:file] = l:base_path
  endif

  exec "lcd " . l:base_path

  let l:rel_path = expand('%')

  if a:use_hash > 0
    let l:ref = trim(system("git rev-parse HEAD"))
    if v:shell_error != 0
      echoerr l:ref
      lcd -
      return
    endif
  else
    if has_key(s:info_dict, l:base_path)
      let l:info = s:info_dict[l:base_path]
    else
      let l:info = trim(system("repo list " . shellescape(l:base_path)))
      if v:shell_error != 0
        echoerr l:info
        lcd -
        return
      endif
      let s:info_dict[l:base_path] = l:info
    endif

    let [l:path, l:project] = split(l:info, " : ")

    if has_key(s:upstream_dict, l:path)
      let l:upstream = s:upstream_dict[l:path]
    else
      let l:upstream = trim(system("repo manifest --json 2>/dev/null | jq -r '.project | .[] | select(.path == \"" . l:path . "\") | .upstream'"))
      if v:shell_error != 0
        echoerr l:upstream
        lcd -
        return
      endif
      let s:upstream_dict[l:path] = l:upstream
    endif
    let l:ref = l:upstream
  endif

  if has_key(s:remote_dict, l:base_path)
    let l:remote = s:remote_dict[l:base_path]
  else
    let l:remote = trim(system("git remote get-url cros"))
    if v:shell_error != 0
      let l:remote = trim(system("git remote get-url cros-internal"))
      if v:shell_error != 0
        echoerr l:remote
        lcd -
        return
      endif
    endif
    let s:remote_dict[l:base_path] = l:remote
  endif

  let l:url = l:remote . "/+/" . l:ref . "/" . l:rel_path . "#" . getcurpos()[1]

  echom l:url
  let @+ = l:url

  lcd -
endfunction
