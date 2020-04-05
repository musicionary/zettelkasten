############# Zettelkasten stuff ######################
note() {
  if [[ -z $1 ]]; then
    zk-search
  else
    local args="$@"
    nvim -c ":set autochdir" "$HOME/Documents/Zettelkasten/$(date +"%Y%m%d%H%M") $args.md"
  fi
}

zk-tags-raw() {
  rg -o "#[\w\-_]{3,}" -t md -N --no-filename "$HOME/Documents/Zettelkasten" |
    rg -v "^#(notes-|import-)" | \
    awk ' { tot[$0]++ } END { for (i in tot) print tot[i], "\t", i } ' | \
    sort -r --numeric-sort
}

# can't get rg to work here for some reason..
# https://github.com/junegunn/fzf/issues/1846 for why no preview (can't nest!)
zk-tags() {
  zk-tags-raw | fzf --height 100% --no-info --no-multi \
    --bind "ctrl-o:execute-silent[tmux send-keys -t \{left\} Escape :read Space ! Space echo Space && \
            tmux send-keys -t \{left\} -l '\"\\'{2}'\"' && \
            tmux send-keys -t \{left\} Enter]" \
    --bind "ctrl-y:execute-silent(echo {2} | pbcopy),enter:execute[ \
      fgrep --color=always -i {2} *.md -l | \
        fzf --ansi --height 100% --preview-window=top:65% \
          --bind 'enter:execute-silent$ \
            tmux send-keys -t \{left\} Escape :e Space && \
            tmux send-keys -t \{left\} -l \{} && \
            tmux send-keys -t \{left\} Enter \
          $' \
          --preview 'bat --color always --language md --style plain \{}' \
    ]"
}
alias zkt="zk-tags"

zk-search() {
  cd $HOME/Documents/Zettelkasten
  
  local file="backup/$(date "+%Y-%m-%d")-index.db"
  if [[ ! -f  $file ]]; then
    cp index.db $file
  # elif ( `gstat --format=%Y $file` -le `date "+%s"` - 60 ); then 
  #   cp index.db $file
  fi

  fzf --ansi --height 100% --preview 'python scripts/search2.py -f {} {q} | bat --language md --style=plain --color always' \
    --bind "ctrl-o:execute-silent@tmux send-keys -t \{left\} Escape :read Space ! Space echo Space && \
            tmux send-keys -t \{left\} -l '\"'[[{}]]'\"' && \
            tmux send-keys -t \{left\} Enter@" \
    --bind "enter:execute-silent[ \
      tmux send-keys -t \{left\} Escape :e Space && \
      tmux send-keys -t \{left\} -l {} && \
      tmux send-keys -t \{left\} Enter \
    ]" \
    --bind "change:reload:python scripts/search2.py '{q}'" \
    --phony --preview-window=top:65% --no-info --no-multi
}
alias zks=zk-search

zkf() {
  cd $HOME/Documents/Zettelkasten
  rg --files -t md | fzf --ansi --height 100% --preview "bat --color always --language md --style plain {}" --preview-window=top:65%
}

file-list-tags() {
  rg --sort path --files --glob '!target' > .file_list_tags
}

ctags-build() {
  file-list-tags
  ctags -f tags -L .file_list_tags
}

zk-uniq() {
  rg --files -t md | rg -o "\A\d+" | sort | uniq -c | sort
}
############# End Zettelkasten stuff#########################
