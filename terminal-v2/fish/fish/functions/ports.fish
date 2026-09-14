function ports --wraps='ss -tuln' --description 'alias ports=ss -tuln'
    ss -tuln $argv
end
