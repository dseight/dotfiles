if exists("did_load_filetypes")
    finish
endif
augroup filetypedetect
    au! BufRead,BufNewFile *.dtso           setfiletype dts
    au! BufRead,BufNewFile *.qml            setfiletype qmljs
    au! BufRead,BufNewFile *.vapi           setfiletype vala
    au! BufRead,BufNewFile *.jenkinsfile    setfiletype groovy
    au! BufRead,BufNewFile _aggregate       setfiletype xml
    au! BufRead,BufNewFile _service         setfiletype xml
augroup END
