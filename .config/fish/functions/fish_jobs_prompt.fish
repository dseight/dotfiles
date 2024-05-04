function fish_jobs_prompt --description 'Show background jobs in prompt'
    if jobs -q
        set -l jobs_status (jobs | string split -f4 \t | string split -f1 ' ' | string join \|)
        echo -n -s (set_color magenta) " [$jobs_status]" (set_color normal)
    end
end
