# Use bash-completion
[[ -f /usr/share/bash-completion/bash_completion ]] && \
    . /usr/share/bash-completion/bash_completion
# Source kubectl
[[ -f /usr/local/bin/kubectl ]] && \
    source <(kubectl completion bash)
# Source azure-cli
[[ -f /usr/bin/az.completion.sh ]] && \
    source /usr/bin/az.completion.sh
# Change Prompt
export PS1="\w \$ "

