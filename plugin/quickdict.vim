if exists('g:loaded_quickdict_vim')
  finish
endif
let g:loaded_quickdict_vim = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:lookupaword(word) abort
	let encodedword = webapi#http#encodeURI(a:word)
	let res = webapi#http#get('https://ejje.weblio.jp/content/' . encodedword)
	if res.status != 200
		echomsg res
		return ''
	endif
	if res.content == ''
		echomsg 'empty content'
		return ''
	endif
	let c = webapi#html#parse(res.content)
	let class_candidates = ['content-explanation ej', 'content-explanation je']
	for klass in class_candidates
		let n = c.find('td', {'class': klass})
		if n == {}
			continue
		endif
		return n.child[0]
	endfor
	return ''
endfunction

function! s:echo(word) abort
	echomsg s:lookupaword(a:word)
endfunction

function! s:appendword(word) abort
	let s = s:lookupaword(a:word)
	if s != ''
		call append(line('.'), s)
	endif
endfunction

function! s:insertlast(word) abort
	let s = s:lookupaword(a:word)
	if s != ''
		execute "normal A : " . s
	endif
endfunction

command! -nargs=+ QuickDictEcho call <sid>echo(<q-args>)
command! -nargs=+ QuickDictAppend call <sid>appendword(<q-args>)
command! -nargs=+ QuickDictInsertLast call <sid>insertlast(<q-args>)

let s:bufname = 'quickdict'
let s:quickdict_local_word = ''
let s:quickdict_lines = []

if !exists('g:quickdict_path')
	let s:script_dir = expand('<sfile>:p:h')
	let g:quickdict_path = s:script_dir . '/../dict/EIJIRO-1446_nkf_utf8.txt'
endif

function! s:openwindow()
	if bufwinnr(s:bufname) == -1
		execute ':split ' . s:bufname
		setlocal nobuflisted
		setlocal buftype=nofile noswapfile
		setlocal bufhidden=delete
		setlocal nonumber
		setlocal norelativenumber
		setlocal filetype=quickdict
		execute "augroup QuickDictBuf"
		execute "autocmd!"
		execute "autocmd BufEnter " . s:bufname . " map <buffer> q <C-w>c<CR>"
		execute "augroup END"
	endif
	execute bufwinnr(s:bufname) . 'wincmd w'
endfunction

function! s:outcb(chan, msg) abort
	call add(s:quickdict_lines, a:msg)
endfunction

function! s:exitcb(job, job_status) abort
	call s:openwindow()
	setlocal modifiable noreadonly
	silent! file `=bufname`
	execute ":1,$d"
	let lines = join(s:quickdict_lines, "\n")
	execute 'silent :1 put = lines | 1 delete _'
	setlocal nomodifiable readonly
	"let match = search('^' . s:quickdict_local_word)
	try
		execute ":ijump /^" . s:quickdict_local_word . "/"
	catch /E387/
	endtry
	let @/='\<' . s:quickdict_local_word . '\>'
	"let @/='.*' . s:quickdict_local_word . ' .*:'
endfunction

function! s:quickdict_grep(...) abort
	if !filereadable(g:quickdict_path)
		echo 'dictionary file not found'
		return
	endif
	if a:0 != 0 && a:1 == ''
		let s:quickdict_local_word = expand('<cword>')
	else
		let s:quickdict_local_word = a:1
	endif
	if executable('rg')
		let l:command = 'rg -N '
	elseif executable('ag')
		let l:command = 'ag --nonumbers '
	else
		let l:command = 'grep -nH '
	endif
	if s:quickdict_local_word != ''
		let s:quickdict_lines = []
		let s:buf = job_start(l:command . ' "' . s:quickdict_local_word . '" ' . g:quickdict_path, {'out_cb': function('s:outcb'), 'in_io': 'null', 'exit_cb': function('s:exitcb')})
	endif
endfunction

command! -nargs=? QuickDictLocal call <sid>quickdict_grep(<q-args>)
nnoremap <Space>rl :<C-u>QuickDictLocal<CR>

let &cpo = s:save_cpo
