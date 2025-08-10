-- lua5.3
-- local function insertAt(ori_t, tar_t, index)
--     table.move(ori_t, 1, #ori_t, index, tar_t)
-- end

-- local ori_t = {1, 2, 3, 4, 5}
-- local tar_t = {6, 7, 8, 9, 10}
-- local index = 3
-- insertAt(ori_t, tar_t, index)
-- print(table.concat(tar_t, " "))

-- lua 5.1
local function insertAt(ori_t, tar_t, index)
    if index > #tar_t then
        return nil
    end
    for i = #tar_t + #ori_t, index + #ori_t, -1 do
        tar_t[i] = tar_t[i - #ori_t]
    end
    for i = 1, #ori_t do
        tar_t[i + index - 1] = ori_t[i]
    end
end

local ori_t = {1, 2, 3, 4, 5}
local tar_t = {6, 7, 8, 9, 10}
local index = 3
insertAt(ori_t, tar_t, index)
print(table.concat(tar_t, " "))