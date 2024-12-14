-- ENVY

function public.setup(env, mp)
    if mp then table.insert(mp_marked, env["!guid"]) end

    if env == nil then
        env = envy.getfenv(2)
    end
    local wrapper = {}
    for k, v in pairs(class_refs) do
        wrapper[k] = v
    end
    return wrapper
end


function public.auto(mp)
    local env = envy.getfenv(2)
    local wrapper = public.setup(env, mp)
    envy.import_all(env, wrapper)

    Language.register_autoload(env)
end


for k, v in pairs(class_refs) do
    public[k] = v
end