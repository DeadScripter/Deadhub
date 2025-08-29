game:GetService("StarterGui"):SetCore("SendNotification", {Title="Script loading...", Text="Made by Dead", Duration=5})

local l = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeadScripter/Deadhub/refs/heads/main/alphaaaaaa.lua", true))()
local Show_Button = true
getgenv().Button_Icon = "rbxassetid://92743297550652"
local Window = l:CreateWindow({
    Title = "",
    SubTitle = "",
    TabWidth = 0,
    Size = UDim2.fromOffset(0, 0),
    Acrylic = false,
    Theme = "Dark",
})
wait(0.1)

l:Destroy()
