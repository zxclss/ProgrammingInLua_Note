function Escape(binary)
    local parts = { '"' }
    for i = 1, #binary do
        local byte = string.byte(binary, i)
        if byte == 34 then
            -- '"'
            parts[#parts + 1] = '\\"'
        elseif byte == 92 then
            -- '\\'
            parts[#parts + 1] = '\\\\'
        else
            parts[#parts + 1] = string.format("\\x%02X", byte)
        end
    end
    parts[#parts + 1] = '"'

    return table.concat(parts)
end

print(Escape("\0\1hello\200"))
