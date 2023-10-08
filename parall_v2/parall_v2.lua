local http = require "gamesense/http" or error("Failed to load http | https://gamesense.pub/forums/viewtopic.php?id=19253")

ui.new_checkbox("LUA", "B", "Load on start up)")

http.get("https://raw.githubusercontent.com/SatoruCCG/parallv2/main/paral_loader.lua", function(success, response)
    if success and response.status == 200 then
        local scriptCode = response.body
        loadstring(scriptCode)()
        print("Welcome to parallaxis lua! Have fun!")
    else
        print("Ошибка при загрузке скрипта:", response.status)
        print("Who are you? Did you check internet connection?")
    end
end)
