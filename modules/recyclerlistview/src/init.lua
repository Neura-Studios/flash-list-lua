local React = require("@pkg/@jsdotlua/react")

local ContextProvider = require("./core/dependencies/ContextProvider")
export type ContextProvider = ContextProvider.ContextProvider
export type ContextValue = ContextProvider.ContextValue
local DataProvider = require("./core/dependencies/DataProvider")
export type DataProvider = DataProvider.DataProvider
export type BaseDataProvider = DataProvider.BaseDataProvider
local LayoutProvider = require("./core/dependencies/LayoutProvider")
export type LayoutProvider = LayoutProvider.LayoutProvider
export type Dimension = LayoutProvider.Dimension
export type BaseLayoutProvider = LayoutProvider.BaseLayoutProvider
local RecyclerListView = require("./core/RecyclerListView")
export type RecyclerListView = RecyclerListView.RecyclerListView
export type OnRecreateParams = RecyclerListView.OnRecreateParams
export type RecyclerListViewProps = RecyclerListView.RecyclerListViewProps
export type WindowCorrectionConfig = RecyclerListView.WindowCorrectionConfig
local BaseScrollView = require("./core/scrollcomponent/BaseScrollView")
export type BaseScrollView = BaseScrollView.BaseScrollView
local BaseItemAnimator = require("./core/ItemAnimator")
export type ItemAnimator = BaseItemAnimator.ItemAnimator
local AutoScroll = require("./utils/AutoScroll")
export type ScrollableView = AutoScroll.Scrollable
local LayoutManager = require("./core/layoutmanager/LayoutManager")
export type LayoutManager = LayoutManager.LayoutManager
export type Layout = LayoutManager.Layout
export type Point = LayoutManager.Point
export type WrapGridLayoutManager = LayoutManager.WrapGridLayoutManager
local GridLayoutManager = require("./core/layoutmanager/GridLayoutManager")
export type GridLayoutManager = GridLayoutManager.GridLayoutManager
local ProgressiveListView = require("./core/ProgressiveListView")
export type ProgressiveListView = ProgressiveListView.ProgressiveListView
export type ProgressiveListViewProps = ProgressiveListView.ProgressiveListViewProps
local DebugHandlers = require("./core/devutils/debughandlers/DebugHandlers")
export type DebugHandlers = DebugHandlers.DebugHandlers
local ViewabilityTracker = require("./core/ViewabilityTracker")
export type ViewabilityTracker = ViewabilityTracker.ViewabilityTracker
export type WindowCorrection = ViewabilityTracker.WindowCorrection

return table.freeze({
	ContextProvider = ContextProvider,
	DataProvider = DataProvider.default,
	BaseDataProvider = DataProvider.BaseDataProvider,
	LayoutProvider = LayoutProvider.LayoutProvider,
	BaseLayoutProvider = LayoutProvider.BaseLayoutProvider,
	LayoutManager = LayoutManager.LayoutManager,
	WrapGridLayoutManager = LayoutManager.WrapGridLayoutManager,
	GridLayoutManager = GridLayoutManager,
	RecyclerListView = (RecyclerListView :: any) ::  React.FC<RecyclerListViewProps>,
	-- TODO Luau: We don't use `ProgressiveListViewProps` as the prop type because of a Luau type checker error with
	--  intersection types.
	ProgressiveListView = (ProgressiveListView :: any) ::  React.FC<RecyclerListViewProps>,
	BaseItemAnimator = BaseItemAnimator,
	BaseScrollView = BaseScrollView,
	AutoScroll = AutoScroll,
})
