if exists("did_load_filetypes")
    finish
endif
augroup filetypedetect
    au! BufRead,BufNewFile *.qml      setfiletype qmljs
    au! BufRead,BufNewFile _aggregate setfiletype xml
    au! BufRead,BufNewFile _service   setfiletype xml
augroup END
