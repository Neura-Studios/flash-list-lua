-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/devutils/debughandlers/resize/ResizeDebugHandler.ts

local LayoutProvider = require("../../../dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension

export type ResizeDebugHandler = {
  resizeDebug: (oldDim: Dimension, newDim: Dimension, index: number) -> (),
}

return nil
