if exists('g:loaded_nhttp') | finish | endif        " prevent loading file twice

let s:save_cpo = &cpo                               " save user coptions
set cpo&vim                                         " reset them to defaults

command! NHttp lua require'nhttp'.execute_command()
command! NHttpCmd lua require'nhttp'.show_command()

let &cpo = s:save_cpo                               " and restore after
unlet s:save_cpo

" set default configurations
let g:nhttp_switch_to_output_window = 'false'        " switch to output window after request completes
let g:nhttp_split = 'vertical'                      " specifies whether to split output window vertically or horizontally
let g:nhttp_env = 'prod'                            " the default environment to get http configuration from
"let g:nhttp_cmd = 'jpath -u . ?'                    " Any post processing command that you'd like to process the output
let g:nhttp_cmd = ''                                " Any post processing command that you'd like to process the output, ? in place of output content

let g:loaded_nhttp = 1
