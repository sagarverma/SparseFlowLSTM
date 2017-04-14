function myasssert(cond)
    if ~cond
        fprintf('%s Assertion failed!',log_line_prefix)
    end
end