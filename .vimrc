" BASIC
set nocompatible " No vi compatility, this first because it resets some options
let mapleader="," " Mapleader
filetype off
set encoding=utf-8
set history=1000  " Keep more history, default is 20
set mouse=v " Allow copy-pasting

set statusline=
set statusline+=%f:%l:%c\ %m
set statusline+=%{tagbar#currenttag('\ [%s]\ ','','')}
set statusline+=%=
set statusline+=%{FugitiveStatusline()}

call plug#begin('~/.vim/plugged')

" {{{
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

function! FzfSpellSink(word)
  exe 'normal! "_ciw'.a:word
endfunction

function! FzfSpell()
  let suggestions = spellsuggest(expand("<cword>"))
  return fzf#run(fzf#wrap({'source': suggestions, 'sink': function("FzfSpellSink"), 'window': { 'width': 0.6, 'height': 0.3 }}))
endfunction

nnoremap z= :call FzfSpell()<CR>

let g:fzf_tags_command = 'bash -c "build-ctags"'

let g:fzf_history_dir = '~/.fzf-history'
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --hidden --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let options = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  if a:fullscreen
    let options = fzf#vim#with_preview(options)
  endif
  call fzf#vim#grep(initial_command, 1, options, a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
" Completely use RG, don't use fzf's fuzzy-matching
map <C-g> :RG<CR>
map <Space>/ :execute 'Rg ' . expand('<cword>')<CR>
map <leader>/ :execute 'Rg ' . input('Rg/')<CR>

" map <C-g> :Rg<CR>
" map <leader>/ :execute 'RG ' . input('Rg/')<CR>
" map <Space>/ :execute 'RG ' . input('Rg/', expand('<cword>'))<CR>

command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, {'options': ['--tiebreak=begin']}, <bang>0)
map <C-t> :Files<CR>

map <C-j> :Buffers<CR>
map <A-c> :Commands<CR>

map <C-l> :Tags<CR>
map <Space>l :call fzf#vim#tags(expand('<cword>'))<CR>
map <A-l> :BTags<CR>
map <Space><A-l> :call fzf#vim#buffer_tags(expand('<cword>'))<CR>

function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

command! SqlFormat :%!sqlformat --reindent --keywords upper --identifiers lower -

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-o': ':r !basename',
  \ 'alt-o':  ':r !echo',
  \ 'ctrl-v': 'vsplit' }
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:toggle-all'
" }}}

Plug 'benmills/vimux'
" {{{
let g:VimuxTmuxCommand = "/usr/local/bin/tmux"
let g:VimuxOrientation = "h"
let g:VimuxHeight = "40"
let g:VimuxUseNearest = 1

function! RepeatLastTmuxCommand()
  call VimuxRunCommand('Up')
endfunction
map <C-e> :call RepeatLastTmuxCommand()<CR>

function! RunSomethingInTmux()
  if &filetype ==# 'markdown'
    call VimuxRunCommand(expand('%'))
  end
endfunction
map <A-e> :call RunSomethingInTmux()<CR>

Plug 'crusoexia/vim-monokai'
Plug 'plasticboy/vim-markdown'

" {{
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_no_extensions_in_markdown = 1
let g:vim_markdown_follow_anchor = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_autowrite = 1

" https://agilesysadmin.net/how-to-manage-long-lines-in-vim/
autocmd FileType markdown setlocal spell
autocmd FileType markdown setlocal linebreak " wrap on words, not characters

call plug#end()

"filetype plugin indent on # doublequote-here-if-uncommenting Enable after Vundle loaded, #dunnolol

set t_Co=256  " 2000s plz
set textwidth=80  " Switch line at 80 characters
set scrolloff=5   " Keep some distance to the bottom"
set showmatch     " Show matching of: () [] {}
set ignorecase    " Required for smartcase to work
set smartcase     " Case sensitive when uppercase is present
set incsearch     " Search as you type
set smartindent   " Be smart about indentation
set expandtab     " Tabs are spaces
set smarttab
set tabstop=2 " Tabs are 2 spaces
set backspace=2 " Backspace deletes 2 spaces
set shiftwidth=2 " Even if there are tabs, preview as 2 spaces



syntax enable
colorscheme monokai


set tags=./tags,tags;
function! BuildCtags()
  silent execute ":!bash -lc ctags-build"
endfunction
command! -nargs=* BuildCtags call BuildCtags()



function! SNote(...)
  let path = strftime("%Y%m%d%H%M")." ".trim(join(a:000)).".md"
  execute ":sp " . fnameescape(path)
endfunction
command! -nargs=* SNote call SNote(<f-args>)


function! Note(...)
  let path = strftime("%Y%m%d%H%M")." ".trim(join(a:000)).".md"
  execute ":e " . fnameescape(path)
endfunction
command! -nargs=* Note call Note(<f-args>)



function! ZettelkastenSetup()
  syn region mkdFootnotes matchgroup=mkdDelimiter start="\[\["    end="\]\]"

  inoremap <expr> <plug>(fzf-complete-path-custom) fzf#vim#complete#path("rg --files -t md \| sed 's/^/[[/g' \| sed 's/$/]]/'")
  imap <buffer> [[ <plug>(fzf-complete-path-custom)

  function! s:CompleteTagsReducer(lines)
    if len(a:lines) == 1
      return "#" . a:lines[0]
    else
      return split(a:lines[1], '\t ')[1]
    end
  endfunction

  inoremap <expr> <plug>(fzf-complete-tags) fzf#vim#complete(fzf#wrap({
        \ 'source': 'bash -lc "zk-tags-raw"',
        \ 'options': '--ansi --nth 2 --print-query --exact --header "Enter without a selection creates new tag"',
        \ 'reducer': function('<sid>CompleteTagsReducer')
        \ }))
  imap <buffer> # <plug>(fzf-complete-tags)


  " setlocal formatoptions+=a
  imap <imap> -- —
endfunction

" Don't know why I can't get FZF to return {2}
function! InsertSecondColumn(line)
  " execute 'read !echo ' .. split(a:e[0], '\t')[1]
  exe 'normal! o' .. split(a:line, '\t')[1]
endfunction

command! ZKR call fzf#run(fzf#wrap({
        \ 'source': 'ruby scripts/tag-related.rb "' .. bufname("%") .. '"',
        \ 'options': '--ansi --exact --nth 2',
        \ 'sink':    function("InsertSecondColumn")
      \}))

autocmd BufNew,BufNewFile,BufRead ~/Documents/Zettelkasten/*.md call ZettelkastenSetup()
