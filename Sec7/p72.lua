local input_file_dir = arg[1]
local output_file_dir = arg[2]

local input_file = nil
local output_file = nil
if input_file_dir then
    input_file = io.open(input_file_dir, "r")
    if not input_file then
        io.write("File not found\n")
        os.exit()
    end
    io.input(input_file)
else
    io.write("Enter your input content (press Ctrl+Z then Enter to finish on Windows, or Ctrl+D on Unix):\n")
    io.input(io.stdin)
end

local lines = {}
for line in io.lines() do
    table.insert(lines, line)
end
if input_file then
    input_file:close()
end

table.sort(lines)

if output_file_dir then
    local file_exists = io.open(output_file_dir, "r")
    if file_exists then
        file_exists:close()
        io.write("Output file '" .. output_file_dir .. "' already exists. Overwrite? (y/n): ")
        local response = io.read()
        if response ~= "y" and response ~= "Y" then
            io.write("Operation cancelled.\n")
            os.exit()
        end
    end
    
    output_file = io.open(output_file_dir, "w")
    if not output_file then
        io.write("Cannot create output file\n")
        os.exit()
    end
    io.output(output_file)
else
    io.output(io.stdout)
end

for _, line in ipairs(lines) do
    io.write(line .. "\n")
end

if output_file then
    output_file:close()
end


