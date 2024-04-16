-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/devutils/debughandlers/DebugHandlers.ts

local ResizeDebugHandler = require("./resize/ResizeDebugHandler")
type ResizeDebugHandler = ResizeDebugHandler.ResizeDebugHandler

export type DebugHandlers = {
    resizeDebugHandler: ResizeDebugHandler?,
}

return nil
