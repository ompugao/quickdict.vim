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

let &cpo = s:save_cpo


