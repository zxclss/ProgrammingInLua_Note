function AddSparseMatrix(A, B)
    local C = {}

    -- copy non-zero entries from A into C
    for i, rowA in pairs(A or {}) do
        if rowA ~= nil then
            local rowC = {}
            for j, va in pairs(rowA) do
                if va ~= 0 then
                    rowC[j] = va
                end
            end
            if next(rowC) ~= nil then
                C[i] = rowC
            end
        end
    end

    -- add entries from B into C
    for i, rowB in pairs(B or {}) do
        if rowB ~= nil then
            local rowC = C[i]
            if rowC == nil then
                rowC = {}
                C[i] = rowC
            end
            for j, vb in pairs(rowB) do
                local sum = (rowC[j] or 0) + vb
                if sum ~= 0 then
                    rowC[j] = sum
                else
                    rowC[j] = nil
                end
            end
            if next(rowC) == nil then
                C[i] = nil
            end
        end
    end

    return C
end