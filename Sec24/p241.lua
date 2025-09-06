function send(x, prod)
    coroutine.resume(prod, x)
end

function receive()
    return coroutine.yield()
end

function consumer()
    return coroutine.create(function (x)
        while true do
            io.write(x, "\n")
            x = receive()
        end
    end)
end

function producer(prod)
    while true do
        local x = io.read()
        send(x, prod)
    end
end

producer(consumer())