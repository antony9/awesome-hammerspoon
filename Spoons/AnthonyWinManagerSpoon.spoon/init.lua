---
-- AnthonyWinManagerSpoon
-- 一个用于多窗口管理的Hammerspoon Spoon框架
local obj = {}
obj.__index = obj

-- Spoon元信息
obj.name = "AnthonyWinManagerSpoon"
obj.version = "1.0"
obj.author = "Anthony"
obj.license = "MIT"
obj.homepage = "https://github.com/yourname/AnthonyWinManagerSpoon"

print("FUCK AnthonyWinManagerSpoon init.lua loaded")

-- 1. 航母桌面
-- 	1. ClickUp / Obsidian（日历 + 邮件）
-- 	2. 自动桌面处理
-- 2. 工作浏览器桌面
-- 	1. 浏览器
-- 		1. Hbg / Roas / GTA
-- 		2. PowerBI
-- 		3. Jira
-- 	2. 日历
-- 3. 剧本写作桌面
-- 	1. Cursor + 浏览器
-- 4. 工具优化桌面
-- 	1. VS Code
-- 	2. 浏览器+AI工具
-- 5. 看片桌面
-- 	1. 浏览器 + WPS
-- 6. 市场观察桌面
-- 	1. LastPass浏览器
-- 7. 休闲娱乐桌面

obj.display_config = {
    work_entrance = {
        desktop = 1,
        primary = {
            -- { app = "ClickUp", title = nil },
        },
        secondary = {
            { app = "Obsidian", title = nil },
        },
    },
    work_explore = {
        desktop = 2,
        primary = {
            { app = "Google Chrome", title = nil },
        },
        secondary = {
            --{ app = "Calendar", title = nil },
            { app = "Mail", title = nil },
            { app = "WPS Office", title = nil },
        },
    },
    work_writer = {
        desktop = 3,
        primary = {
            { app = "Final Draft 13", title = nil }, 
        },
        secondary = {
            { app = "Google Chrome", title = nil },
            { app = "WPS Office", title = nil },
        },
    },
    tool_optimize = {
        desktop = 4,
        primary = {
            { app = "Cursor", title = nil },
        },
        secondary = {
            { app = "Google Chrome", title = nil },
            -- { app = "Tencent Yuanbao", title = nil },
            -- { app = "Cherry Studio", title = nil },
        },
    },
    work_short_drama = {
        desktop = 5,
        primary = {
            { app = "Google Chrome", title = nil },
        },
        secondary = {
            -- { app = "WPS Office", title = nil },
            -- { app = "ClickUp", title = nil },
        },
    },
    work_market_research = {
        desktop = 6,
        primary = {
            { app = "Google Chrome", title = nil },
        },
    },
    entertainment_short = {
        desktop = 7,
        primary = {
            { app = "Google Chrome", title = nil },
        },
    },
}

function obj:test()
    obj:apply_work_entrance_layout()
end

-- 简化的窗口查找函数
local function find_window_by_app_and_title(app_name, title)
    local app = hs.application.get(app_name)
    if not app then
        return nil
    end
    
    local windows = app:allWindows()
    if not title then
        -- 如果没有指定标题，返回第一个窗口
        return windows and windows[1] or nil
    end
    
    -- 如果指定了标题，进行模糊匹配
    for _, win in ipairs(windows) do
        local win_title = win:title()
        if win_title and string.find(string.lower(win_title), string.lower(title), 1, true) then
            return win
        end
    end
    
    return nil
end

-- 跳转到指定桌面
local function goto_desktop(screen, desktop_index)
    local uuid = screen:getUUID()
    local space_names = hs.spaces.missionControlSpaceNames()[uuid]
    if not space_names then
        hs.alert.show("无法获取屏幕 " .. screen:name() .. " 的桌面信息")
        return false
    end
    
    local desktop_name = "Desktop " .. tostring(desktop_index)
    for space_id, name in pairs(space_names) do
        if name == desktop_name then
            hs.spaces.gotoSpace(space_id)
            return true
        end
    end
    
    hs.alert.show("找不到桌面: " .. desktop_name)
    return false
end

-- 在secondary屏幕上排列窗口
local function arrange_secondary_windows(windows, screen)
    if #windows == 0 then return end
    
    if #windows == 1 then
        -- 只有一个窗口，最大化
        windows[1]:moveToScreen(screen)
        hs.timer.doAfter(0.1, function()
            windows[1]:maximize()
        end)
    elseif #windows == 2 then
        -- 两个窗口，左右分屏
        local screen_frame = screen:frame()
        -- local left_frame = {
        --     x = screen_frame.x,
        --     y = screen_frame.y,
        --     w = screen_frame.w / 2,
        --     h = screen_frame.h
        -- }
        -- local right_frame = {
        --     x = screen_frame.x + screen_frame.w / 2,
        --     y = screen_frame.y,
        --     w = screen_frame.w / 2,
        --     h = screen_frame.h
        -- }
        
        windows[1]:moveToScreen(screen)
        windows[2]:moveToScreen(screen)
        
        -- hs.timer.doAfter(0.1, function()
        --     windows[1]:setFrame(left_frame)
        --     windows[1]:setSize(hs.geometry.size(left_frame.w, left_frame.h))
        --     windows[2]:setFrame(right_frame)
        --     windows[2]:setSize(hs.geometry.size(right_frame.w, right_frame.h))
        -- end)
    else
        -- 多个窗口，只移动到屏幕，不做特殊排列
        for _, win in ipairs(windows) do
            win:moveToScreen(screen)
        end
    end
end

-- 应用布局的主函数
function obj:_apply_layout(layout_config)
    local desktop_index = layout_config.desktop or 1
    
    -- 步骤1: 跳转到指定桌面
    if not goto_desktop(obj.primary, desktop_index) then
        hs.alert.show("无法跳转到指定桌面，布局应用失败")
        return
    end
    
    -- 等待桌面切换完成
    hs.timer.doAfter(0.5, function()
        local primary_processed = 0
        local secondary_processed = 0
        
        -- 步骤2: 处理primary应用
        if layout_config.primary and obj.primary then
            for _, spec in ipairs(layout_config.primary) do
                local win = find_window_by_app_and_title(spec.app, spec.title)
                if win then
                    win:moveToScreen(obj.primary)
                    hs.timer.doAfter(0.1, function()
                        win:maximize()
                    end)
                    primary_processed = primary_processed + 1
                else
                    print("警告: 找不到应用窗口: " .. spec.app .. (spec.title and (" - " .. spec.title) or "") .. "，跳过此应用")
                end
            end
            
            if primary_processed == 0 and #layout_config.primary > 0 then
                hs.alert.show("主屏幕: 所有应用窗口都未找到")
            elseif primary_processed > 0 then
                print("主屏幕: 成功处理 " .. primary_processed .. " 个应用窗口")
            end
        end
        
        -- 步骤3: 处理secondary应用
        if layout_config.secondary and obj.secondary and obj.has_secondary then
            local secondary_windows = {}
            local missing_apps = {}
            
            for _, spec in ipairs(layout_config.secondary) do
                local win = find_window_by_app_and_title(spec.app, spec.title)
                if win then
                    table.insert(secondary_windows, win)
                    secondary_processed = secondary_processed + 1
                else
                    table.insert(missing_apps, spec.app .. (spec.title and (" - " .. spec.title) or ""))
                    print("警告: 找不到应用窗口: " .. spec.app .. (spec.title and (" - " .. spec.title) or "") .. "，跳过此应用")
                end
            end
            
            -- 统一显示副屏幕处理结果
            if #missing_apps > 0 and #secondary_windows == 0 then
                hs.alert.show("副屏幕: 所有应用窗口都未找到")
            elseif #missing_apps > 0 then
                hs.alert.show("副屏幕: 找到 " .. #secondary_windows .. " 个窗口，" .. #missing_apps .. " 个应用未找到")
            elseif #secondary_windows > 0 then
                print("副屏幕: 成功处理 " .. #secondary_windows .. " 个应用窗口")
            end
            
            -- 排列secondary窗口
            if #secondary_windows > 0 then
                hs.timer.doAfter(0.2, function()
                    arrange_secondary_windows(secondary_windows, obj.secondary)
                end)
            end
        end
        
        -- 显示总体处理结果
        hs.timer.doAfter(1.0, function()
            local total_processed = primary_processed + secondary_processed
            local total_expected = (layout_config.primary and #layout_config.primary or 0) + 
                                  (layout_config.secondary and #layout_config.secondary or 0)
            
            if total_processed == total_expected then
                hs.alert.show("布局应用完成: 所有 " .. total_processed .. " 个窗口已处理")
            elseif total_processed > 0 then
                hs.alert.show("布局应用完成: " .. total_processed .. "/" .. total_expected .. " 个窗口已处理")
            else
                hs.alert.show("布局应用失败: 未找到任何指定的应用窗口")
            end
        end)
    end)
end

function obj:apply_work_entrance_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.work_entrance)
end

function obj:apply_work_explore_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.work_explore)
end

function obj:apply_work_writer_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.work_writer)
end

function obj:apply_tool_optimize_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.tool_optimize)
end

function obj:apply_work_short_drama_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.work_short_drama)
end

function obj:apply_work_market_research_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.work_market_research)
end

function obj:apply_entertainment_short_layout()
    self:refresh_display_config()
    self:_apply_layout(self.display_config.entertainment_short)
end

function obj:test_move_right()
    hs.alert.show("测试: 向右移动窗口")
    -- 这个功能保留，但简化实现
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        local screens = hs.screen.allScreens()
        local next_screen = nil
        for i, s in ipairs(screens) do
            if s == screen and i < #screens then
                next_screen = screens[i + 1]
                break
            end
        end
        if next_screen then
            win:moveToScreen(next_screen)
        else
            hs.alert.show("已经是最后一个屏幕")
        end
    end
end

function obj:refresh_display_config()
    -- 更新屏幕数量
    local all_screens = hs.screen.allScreens()
    obj.orig_screen_count = obj.current_screen_count
    obj.current_screen_count = #all_screens

    if obj.current_screen_count == 0 then
        obj.primary = nil
        obj.secondary = nil
        obj.has_secondary = false
        print("未检测到显示器。")
        return
    elseif obj.current_screen_count == 1 then
        obj.primary = all_screens[1]
        obj.secondary = nil
        obj.has_secondary = false
    else
        -- 当有多个显示器时，根据分辨率来决定主副屏
        local screen_info = {}
        for _, screen in ipairs(all_screens) do
            local res = screen:frame().w * screen:frame().h
            table.insert(screen_info, {screen = screen, resolution = res})
        end

        -- 按分辨率从高到低排序
        table.sort(screen_info, function(a, b)
            return a.resolution > b.resolution
        end)

        obj.primary = screen_info[1].screen
        obj.secondary = screen_info[2].screen
        obj.has_secondary = true
    end

    -- 更新状态并打印
    if obj.has_secondary then
        print("屏幕配置已刷新 (分辨率优先): 主屏 -> " .. obj.primary:name() .. " (" .. obj.primary:frame().w .. "x" .. obj.primary:frame().h .. "), 副屏 -> " .. obj.secondary:name() .. " (" .. obj.secondary:frame().w .. "x" .. obj.secondary:frame().h .. ")")
    elseif obj.primary then
        print("屏幕配置已刷新 (分辨率优先): 主屏 -> " .. obj.primary:name() .. " (" .. obj.primary:frame().w .. "x" .. obj.primary:frame().h .. "), 无副屏")
    end
end

-- 初始化方法
function obj:init()
    -- 这里可以初始化你的Spoon
    local screens = hs.screen.allScreens()
    obj.orig_screen_count = #screens
    obj.current_screen_count = obj.orig_screen_count
    print("Screens详细信息：" .. hs.inspect(screens))
    for k, screen in pairs(screens) do
        print(string.format("屏幕 %d:", k))
        print("  ID: " .. screen:id())
        print("  名称: " .. screen:name())
        print("  分辨率: " .. screen:frame().w .. "x" .. screen:frame().h)
        print("  位置: x=" .. screen:frame().x .. ", y=" .. screen:frame().y)
    end

    local spaces = hs.spaces.spacesForScreen("Primary")
    print("Spaces详细信息：" .. hs.inspect(spaces))
    obj:refresh_display_config()
    hs.screen.watcher.new(function()
        obj:refresh_display_config()
    end):start()
end

-- 启动方法
function obj:start()
    print("AnthonyWinManagerSpoon 已启动！")
end

-- 停止方法
function obj:stop()
    print("AnthonyWinManagerSpoon 已停止！")
end

return obj 