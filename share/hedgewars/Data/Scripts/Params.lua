-- Library for parameters handling

params = {}

function parseParams()
    for k, v in string.gmatch(ScriptParam, "(%w+)=([^,]+)") do
        params[k] = v
    end
end
