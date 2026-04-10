local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local httpService = game:GetService("HttpService")

local Mobile = not RunService:IsStudio() and table.find({ Enum.Platform.IOS, Enum.Platform.Android }, UserInputService:GetPlatform()) ~= nil

local InterfaceManager = {}
InterfaceManager.Folder = "FluentSettings"
InterfaceManager.Settings = {
    Theme = "Dark",
    Acrylic = true,
    Transparency = true,
    WindowTransparency = 1,
    MenuKeybind = "LeftControl",
    Locale = "auto"
}

InterfaceManager.LocaleValues = {
    "Auto (System)",
    "Arabic (ar-001)",
    "Chinese Simplified (zh-cn)",
    "Chinese Traditional (zh-tw)",
    "Dutch (nl-nl)",
    "English (en-us)",
    "French (fr-fr)",
    "German (de-de)",
    "Hindi (hi-in)",
    "Indonesian (id-id)",
    "Italian (it-it)",
    "Japanese (ja-jp)",
    "Korean (ko-kr)",
    "Polish (pl-pl)",
    "Portuguese (pt-br)",
    "Russian (ru-ru)",
    "Spanish (es-es)",
    "Spanish LATAM (es-419)",
    "Thai (th-th)",
    "Turkish (tr-tr)",
    "Ukrainian (uk-ua)",
    "Vietnamese (vi-vn)"
}

function InterfaceManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function InterfaceManager:SetLibrary(library)
    self.Library = library
end

function InterfaceManager:GetLocaleValue(selection)
    if self.Library and self.Library.GetLocaleValue then
        return self.Library:GetLocaleValue(selection)
    end
    return tostring(selection or "auto")
end

function InterfaceManager:GetLocaleLabel(localeId)
    if self.Library and self.Library.GetLocaleLabel then
        return self.Library:GetLocaleLabel(localeId)
    end
    return tostring(localeId or "auto")
end

function InterfaceManager:BuildFolderTree()
    local paths = {}
    local parts = self.Folder:split("/")
    for idx = 1, #parts do
        paths[#paths + 1] = table.concat(parts, "/", 1, idx)
    end

    table.insert(paths, self.Folder)
    table.insert(paths, self.Folder .. "/settings")

    for i = 1, #paths do
        local str = paths[i]
        if not isfolder(str) then
            makefolder(str)
        end
    end
end

function InterfaceManager:SaveSettings()
    writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
end

function InterfaceManager:LoadSettings()
    local path = self.Folder .. "/options.json"
    if isfile(path) then
        local data = readfile(path)
        local success, decoded = false, nil

        if not RunService:IsStudio() then
            success, decoded = pcall(httpService.JSONDecode, httpService, data)
        end

        if success and type(decoded) == "table" then
            for i, v in next, decoded do
                InterfaceManager.Settings[i] = v
            end
        end
    end

    InterfaceManager.Settings.Theme = InterfaceManager.Settings.Theme or (self.Library and self.Library.Theme) or "Dark"
    InterfaceManager.Settings.WindowTransparency = tonumber(InterfaceManager.Settings.WindowTransparency) or 1
    InterfaceManager.Settings.Locale = self:GetLocaleValue(InterfaceManager.Settings.Locale or "auto")
end

function InterfaceManager:ApplySettings()
    local Library = self.Library
    if not Library then
        return
    end

    local Settings = InterfaceManager.Settings

    if Library.SetLocale then
        pcall(function()
            Library:SetLocale(Settings.Locale or "auto")
        end)
    end

    if Settings.Theme and table.find(Library.Themes or {}, Settings.Theme) then
        pcall(function()
            Library:SetTheme(Settings.Theme)
        end)
    end

    if Library.UseAcrylic and not Mobile and Library.ToggleAcrylic then
        pcall(function()
            Library:ToggleAcrylic(Settings.Acrylic ~= false)
        end)
    end

    if Library.ToggleTransparency then
        pcall(function()
            Library:ToggleTransparency(Settings.Transparency ~= false)
        end)
    end

    if Library.SetWindowTransparency then
        pcall(function()
            Library:SetWindowTransparency(Settings.WindowTransparency or 1)
        end)
    end
end

function InterfaceManager:BuildInterfaceSection(tab)
    assert(self.Library, "Must set InterfaceManager.Library")

    local Library = self.Library
    local Settings = InterfaceManager.Settings

    InterfaceManager:LoadSettings()
    InterfaceManager:ApplySettings()

    local section = tab:AddSection("Interface")

    local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
        Title = "Theme",
        Description = "Changes the interface theme.",
        Values = Library.Themes,
        Default = Settings.Theme,
        Callback = function(Value)
            Library:SetTheme(Value)
            Settings.Theme = Value
            InterfaceManager:SaveSettings()
        end
    })

    InterfaceTheme:SetValue(Settings.Theme)

    local InterfaceLocale = section:AddDropdown("InterfaceLocale", {
        Title = "Language",
        Description = "Changes the interface language.",
        Values = InterfaceManager.LocaleValues,
        Default = InterfaceManager:GetLocaleLabel(Settings.Locale),
        Callback = function(Value)
            Settings.Locale = InterfaceManager:GetLocaleValue(Value)
            InterfaceManager:SaveSettings()
            if Library.SetLocale then
                Library:SetLocale(Settings.Locale)
            end
        end
    })

    InterfaceLocale:SetValue(InterfaceManager:GetLocaleLabel(Settings.Locale))

    if Library.UseAcrylic and not Mobile then
        section:AddToggle("AcrylicToggle", {
            Title = "Acrylic",
            Description = "The blurred background requires graphic quality 8+",
            Default = Settings.Acrylic,
            Callback = function(Value)
                Library:ToggleAcrylic(Value)
                Settings.Acrylic = Value
                InterfaceManager:SaveSettings()
            end
        })
    elseif Mobile then
        Settings.Acrylic = false
    end

    section:AddToggle("TransparentToggle", {
        Title = "Transparency",
        Description = "Makes the interface more transparent.",
        Default = Settings.Transparency,
        Callback = function(Value)
            if Library.ToggleTransparency then
                Library:ToggleTransparency(Value)
            end
            Settings.Transparency = Value
            InterfaceManager:SaveSettings()
        end
    })

    local TransparencySlider = section:AddSlider("WindowTransparency", {
        Title = "Window Transparency",
        Description = "Adjusts the window transparency.",
        Default = Settings.WindowTransparency,
        Min = 0,
        Max = 3,
        Rounding = 1,
        Callback = function(Value)
            if Library.SetWindowTransparency then
                Library:SetWindowTransparency(Value)
            end
            Settings.WindowTransparency = Value
            InterfaceManager:SaveSettings()
        end
    })

    TransparencySlider:SetValue(Settings.WindowTransparency)

    local MenuKeybind = section:AddKeybind("MenuKeybind", {
        Title = "Minimize Bind",
        Default = Library.MinimizeKey.Name or Settings.MenuKeybind
    })

    MenuKeybind:OnChanged(function()
        Settings.MenuKeybind = MenuKeybind.Value
        InterfaceManager:SaveSettings()
    end)

    Library.MinimizeKeybind = MenuKeybind
end

return InterfaceManager
