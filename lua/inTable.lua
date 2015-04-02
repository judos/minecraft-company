function inTable(array, item)
    for key, value in pairs(array) do
        if value == item then return true end
    end
    return false
end