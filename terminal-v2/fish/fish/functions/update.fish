function update --wraps='sudo dnf upgrade --refresh' --description 'alias update=sudo dnf upgrade --refresh'
    sudo dnf upgrade --refresh $argv
end
