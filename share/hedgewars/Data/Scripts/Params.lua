-- Library for parameters handling

params = {}

function parseParams()
    if ScriptParam ~= nil then
        for k, v in string.gmatch(ScriptParam, "(%w+)=([^,]+)") do
            params[k] = v
        end
    end
end
