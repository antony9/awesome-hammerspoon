--- === BingDaily ===
---
--- Use Bing daily picture as your wallpaper, automatically.
--- Updated to rotate wallpapers across 6 desktop spaces sequentially.
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/BingDaily.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/BingDaily.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "BingDaily"
obj.version = "2.0"
obj.author = "ashfinal <ashfinal@gmail.com>, updated by limoyun"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Configuration for 6 desktop spaces
obj.desktop_spaces = {1, 2, 4, 5, 6, 7}  -- Based on AnthonyWinManagerSpoon configuration
obj.current_space_index = 1  -- Start with the first space
obj.wallpaper_dir = os.getenv("HOME") .. "/.wallpaper/bing_daily/"
obj.space_wallpaper_map = {}  -- Track wallpaper for each space

-- Ensure wallpaper directory exists
local function ensureWallpaperDirectory()
    local shell_cmd = "mkdir -p " .. obj.wallpaper_dir
    hs.execute(shell_cmd)
end

-- Get current desktop index for tracking
local function getCurrentSpaceIndex()
    local current_space = obj.current_space_index
    if current_space > #obj.desktop_spaces then
        obj.current_space_index = 1
        current_space = 1
    end
    return current_space
end

-- Get the space ID for the current rotation index
local function getCurrentSpaceID()
    local current_index = getCurrentSpaceIndex()
    return obj.desktop_spaces[current_index]
end

-- Set wallpaper for all screens in the current space
local function setWallpaperForAllScreensInSpace(imagePath)
    -- Wait briefly to ensure space transition is complete
    hs.timer.doAfter(0.5, function()
        local screens = hs.screen.allScreens()
        for i, screen in ipairs(screens) do
            screen:desktopImageURL("file://" .. imagePath)
        end
        print("Wallpaper set for all screens in space " .. getCurrentSpaceID() .. " (" .. #screens .. " screen(s))")
    end)
end

-- Callback function after downloading wallpaper
local function curl_callback(exitCode, stdOut, stdErr)
    if exitCode == 0 then
        obj.task = nil
        local localpath = obj.wallpaper_dir .. hs.http.urlParts(obj.full_url).lastPathComponent
        local current_space_id = getCurrentSpaceID()

        -- Store the wallpaper path for this space
        obj.space_wallpaper_map[current_space_id] = localpath

        -- Set wallpaper for all screens in the current space
        setWallpaperForAllScreensInSpace(localpath)

        -- Increment to next space for the next update
        obj.current_space_index = obj.current_space_index + 1
        if obj.current_space_index > #obj.desktop_spaces then
            obj.current_space_index = 1
        end

        print("BingDaily: Updated wallpaper for space " .. current_space_id .. ", next update will target space " .. obj.desktop_spaces[obj.current_space_index])
    else
        print("Download failed:", stdOut, stdErr)
        obj.task = nil
    end
end

-- Function to request Bing image data
local function bingRequest()
    local user_agent_str = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4"
    local json_req_url = "http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1"

    hs.http.asyncGet(json_req_url, {["User-Agent"]=user_agent_str}, function(stat, body, header)
        if stat == 200 then
            if pcall(function() hs.json.decode(body) end) then
                local decode_data = hs.json.decode(body)
                local pic_url = decode_data.images[1].url
                print("Bing image URL:", pic_url)

                local pic_name = hs.http.urlParts(pic_url).lastPathComponent
                local full_url = "https://www.bing.com" .. pic_url
                local localpath = obj.wallpaper_dir .. pic_name

                -- Check if we already have this image for this space
                local current_space_id = getCurrentSpaceID()
                if obj.space_wallpaper_map[current_space_id] and obj.space_wallpaper_map[current_space_id] == localpath then
                    print("Same image already set for space " .. current_space_id .. ", skipping download")
                    return
                end

                -- Terminate any existing task
                if obj.task then
                    obj.task:terminate()
                    obj.task = nil
                end

                -- Start download task
                obj.full_url = full_url
                obj.task = hs.task.new("/usr/bin/curl", curl_callback, {"-A", user_agent_str, full_url, "-o", localpath})
                obj.task:start()
            end
        else
            print("Bing URL request failed!")
        end
    end)
end

-- Function to update wallpaper for current space
local function updateCurrentSpaceWallpaper()
    print("Updating wallpaper for space " .. getCurrentSpaceID() .. " (index " .. getCurrentSpaceIndex() .. ")")
    bingRequest()
end

function obj:init()
    ensureWallpaperDirectory()

    if obj.timer == nil then
        obj.timer = hs.timer.doEvery(3*60*60, function()
            updateCurrentSpaceWallpaper()
        end)
        obj.timer:setNextTrigger(5)
    else
        obj.timer:start()
    end

    print("BingDaily initialized: Will rotate wallpapers across 6 spaces sequentially")
    print("Spaces in rotation: " .. table.concat(obj.desktop_spaces, ", "))
    print("Current space index: " .. obj.current_space_index .. " (space " .. obj.desktop_spaces[obj.current_space_index] .. ")")
end

-- Public method to manually trigger update for current space
function obj:updateCurrentSpace()
    updateCurrentSpaceWallpaper()
end

-- Public method to get current space info
function obj:getCurrentSpaceInfo()
    return {
        index = getCurrentSpaceIndex(),
        id = getCurrentSpaceID(),
        total_spaces = #obj.desktop_spaces,
        all_spaces = obj.desktop_spaces
    }
end

-- Public method to reset space index
function obj:resetSpaceIndex(index)
    index = index or 1
    if index >= 1 and index <= #obj.desktop_spaces then
        obj.current_space_index = index
        print("Space index reset to " .. index .. " (space " .. obj.desktop_spaces[index] .. ")")
    else
        print("Invalid space index: " .. index)
    end
end

return obj
