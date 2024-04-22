-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/FlashListProps.ts

local React = require("@pkg/@jsdotlua/react")
local ViewToken = require("./viewability/ViewToken")

type ComponentType<T> = React.ComponentType<T>
type ExtraData<T> = { value: T? }
type PureComponent<P, S> = React.PureComponent<P, S>
type ReactElement = React.ReactElement
type ViewToken = ViewToken.ViewToken

type BlankAreaEventHandler = any
type DataProvider = any
type GridLayoutProviderWithProps<T> = any
type Pick<T, V...> = any
type Record<K, V> = { [K]: V }
type ScrollViewProps = any
type StyleProp<T> = any
type ViewabilityConfig = any
type ViewStyle = any

export type RenderTarget = "Cell" | "Measurement" | "StickyHeader"

export type ListRenderItemInfo<TItem> = {
	extraData: any,
	index: number,
	item: TItem,
	-- FlashList may render you items for multiple reasons.
	-- Cell - This is for your list item
	-- Measurement - Might be invoked for size measurement and won't be visible. You can ignore this in analytics.
	-- StickyHeader - This is for your sticky header. Use this to change your item's appearance while it's being used as a sticky header.
	target: RenderTarget,
}

export type ListRenderItem<TItem> = (info: ListRenderItemInfo<TItem>) -> ReactElement?

export type ContentStyle = Pick<
	ViewStyle,
	"backgroundColor",
	"paddingTop",
	"paddingLeft",
	"paddingRight",
	"paddingBottom",
	"padding",
	"paddingVertical",
	"paddingHorizontal"
>

export type FlashListProps<TItem> = ScrollViewProps & {
	--[[
      Takes an item from `data` and renders it into the list. Typical usage:
      ```lua
      renderItem = function(props)
         return createElement("TextLabel", {
            Text = props.item.title
         })
      end

      createElement(FlashList, {
         data = {
            { key = "item1", title = "Title Text" }
         },
         renderItem = renderItem
      })
      ```

      Provides additional metadata like `index`

      - `item` (`Object`): The item from `data` being rendered.
      - `index` (`number`): The index corresponding to this item in the `data` array.
   ]]
	renderItem: ListRenderItem<TItem>?,

	-- For simplicity, data is a plain array of items of a given type.
	data: { TItem }?,

	-- Average or median size for elements in the list. Doesn't have to be very accurate but a good estimate can
	-- improve performance. A quick look at `Element Inspector` can help you determine this. If you're confused
	-- between two values, the smaller value is a better choice. For vertical lists provide average height and for
	-- horizontal average width.
	-- Read more about it here: https://shopify.github.io/flash-list/docs/estimated-item-size
	estimatedItemSize: number?,

	-- Each cell is rendered using this element. Can be a React Component Class or a render function. The root
	-- component should always be a `CellContainer` which is also the default component used. Ensure that the
	-- original `props` are passed to the returned `CellContainer`. The `props` will include the following:
	-- - `onLayout`: Method for updating data about the real `CellContainer` layout
	-- - `index`: Index of the cell in the list, you can use this to query data if needed
	-- - `style`: Style of `CellContainer`, including:
	--    - `flexDirection`: Depends on whether your list is horizontal or vertical
	--    - `position`: Value of this will be `absolute` as that's how `FlashList` positions elements
	--    - `left`: Determines position of the element on x axis
	--    - `top`: Determines position of the element on y axis
	--    - `width`: Determines width of the element (present when list is vertical)
	--    - `height`: Determines height of the element (present when list is horizontal)
	--
	-- Note: Changing layout of the cell can conflict with the native layout operations. You may need to
	-- set `disableAutoLayout` to `true` to prevent this.
	CellRendererComponent: ComponentType<any>?,

	-- Rendered in between each item, but not at the top or bottom. By default `leadingItem` and `trailingItem`
	-- (if available) props are provided.
	ItemSeparatorComponent: ComponentType<any>?,

	-- Rendered when the list is empty. Can be a React component (e.g. `SomeComponent`), or a React element
	-- (e.g. `createElement(SomeComponent)`).
	ListEmptyComponent: ComponentType<any> | ReactElement | nil,

	-- Rendered at the bottom of all the items. Can be a React component (e.g. `SomeComponent`), or a React element
	-- (e.g. `createElement(SomeComponent)`).
	ListFooterComponent: ComponentType<any> | ReactElement | nil,

	-- Styling for internal `View` for `ListFooterComponent`.
	ListFooterComponentStyle: StyleProp<ViewStyle>?,

	-- Rendered at the top of all the items. Can be a React component (e.g. `SomeComponent`), or a React element
	-- (e.g. `createElement(SomeComponent)`).
	ListHeaderComponent: ComponentType<any> | ReactElement | nil,

	-- Styling for internal `View` for `ListHeaderComponent`.
	ListHeaderComponentStyle: StyleProp<ViewStyle>?,

	-- Rendered as the main scrollview.
	renderScrollComponent: ComponentType<ScrollViewProps>
		| React.FC<ScrollViewProps>
		| nil,

	-- You can use `contentContainerStyle` to apply padding that will be applied to the whole content itself.
	-- For example, you can apply this padding, so that all of your items have leading and trailing space.
	contentContainerStyle: ContentStyle?,

	-- Draw distance for advanced rendering (in dp/px)
	drawDistance: number?,

	-- Specifies how far the first item is drawn from start of the list window or, offset of the first item of
	-- the list (not the header). Needed if you're using initialScrollIndex prop. Before the initial draw the
	-- list cannot figure out the size of header or, any special margin/padding that might have been applied
	-- using header styles etc. If this isn't provided initialScrollIndex might not scroll to the provided index.
	estimatedFirstItemOffset: number?,

	-- Visible height and width of the list. This is not the scroll content size.
	estimatedListSize: { height: number, width: number }?,

	-- A marker property for telling the list to re-render (since it implements PureComponent).
	-- If any of your `renderItem`, Header, Footer, etc. functions depend on anything outside of the `data` prop,
	-- stick it here and treat it immutably.
	extraData: any,

	-- If true, renders the items next to each other horizontally instead of stacked vertically.
	horizontal: boolean?,

	-- Instead of starting at the top with the first item, start at `initialScrollIndex`.
	initialScrollIndex: number?,

	-- Reverses the direction of scroll. Uses scale transforms of -1.
	inverted: boolean?,

	-- Used to extract a unique key for a given item at the specified index.
	-- Key is used for optimizing performance. Defining `keyExtractor` is also necessary
	-- when doing [layout animations](https://shopify.github.io/flash-list/docs/guides/layout-animation)
	-- to uniquely identify animated components.
	keyExtractor: ((item: TItem, index: number) -> string)?,

	-- Multiple columns can only be rendered with `horizontal={false}` and will zig-zag like a `flexWrap` layout.
	-- Items should all be the same height - masonry layouts are not supported.
	numColumns: number?,

	-- Computes blank space that is visible to the user during scroll or list load. If list doesn't have enough items to fill the screen even then this will be raised.
	-- Values reported: {
	--    offsetStart -> visible blank space on top of the screen (while going up). If value is greater than 0 then it's visible to user.
	--    offsetEnd -> visible blank space at the end of the screen (while going down). If value is greater than 0 then it's visible to user.
	--    blankArea -> max(offsetStart, offsetEnd) use this directly and look for values > 0
	-- }
	-- Please note that this event isn't synced with onScroll event but works with native onDraw/layoutSubviews. Events with values > 0 are blanks.
	-- This event is raised even when there is no visible blank with negative values for extensibility however, for most use cases check blankArea > 0 and use the value.
	onBlankArea: BlankAreaEventHandler?,

	-- Called once when the scroll position gets within `onEndReachedThreshold` of the rendered content.
	onEndReached: (() -> ())?,

	-- How far from the end (in units of visible length of the list) the bottom edge of the
	-- list must be from the end of the content to trigger the `onEndReached` callback.
	-- Thus a value of 0.5 will trigger `onEndReached` when the end of the content is
	-- within half the visible length of the list.
	onEndReachedThreshold: number?,

	-- This event is raised once the list has drawn items on the screen. It also reports @param elapsedTimeInMs which is the time it took to draw the items.
	-- This is required because FlashList doesn't render items in the first cycle. Items are drawn after it measures itself at the end of first render.
	-- If you're using ListEmptyComponent, this event is raised as soon as ListEmptyComponent is rendered.
	onLoad: ((info: { elapsedTimeInMs: number }) -> ())?,

	-- Called when the viewability of rows changes, as defined by the `viewabilityConfig` prop.
	-- Array of `changed` includes `ViewToken`s that both visible and non-visible items. You can use the `isViewable` flag to filter the items.
	--
	-- If you are tracking the time a view becomes (non-)visible, use the `timestamp` property.
	-- We make no guarantees that in the future viewability callbacks will be invoked as soon as they happen - for example,
	-- they might be deferred until JS thread is less busy.
	onViewableItemsChanged: ((
		info: { viewableItems: { ViewToken }, changed: { ViewToken } }
	) -> ())?,

	-- If provided, a standard RefreshControl will be added for "Pull to Refresh" functionality.
	-- Make sure to also set the refreshing prop correctly.
	onRefresh: (() -> ())?,

	-- Allows developers to override type of items. This will improve recycling if you have different types of items in the list
	-- Right type will be used for the right item. Default type is 0
	-- If you don't want to change for an indexes just return undefined.
	-- Performance: This method is called very frequently. Keep it fast.
	getItemType: ((item: TItem, index: number, extraData: any) -> (string | number)?)?,

	-- This method can be used to provide explicit size estimates or change column span of an item.
	--
	-- Providing specific estimates is a good idea when you can calculate sizes reliably. FlashList will prefer this value over `estimatedItemSize` for that specific item.
	-- Precise estimates will also improve precision of `scrollToIndex` method and `initialScrollIndex` prop. If you have a `separator` below your items you can include its size in the estimate.
	--
	-- Changing item span is useful when you have grid layouts (numColumns > 1) and you want few items to be bigger than the rest.
	--
	-- Modify the given layout. Do not return. FlashList will fallback to default values if this is ignored.
	--
	-- Performance: This method is called very frequently. Keep it fast.
	overrideItemLayout: ((
		layout: { size: number?, span: number? },
		item: TItem,
		index: number,
		maxColumns: number,
		extraData: any
	) -> ())?,

	-- For debugging and exception use cases, internal props will be overridden with these values if used.
	overrideProps: { [any]: any }?,

	-- Set this when offset is needed for the loading indicator to show correctly
	progressViewOffset: number?,

	-- Set this to true while waiting for new data from a refresh.
	refreshing: boolean?,

	-- `viewabilityConfig` is a default configuation for determining whether items are viewable.
	-- Changing `viewabilityConfig` on the fly is not supported.
	viewabilityConfig: ViewabilityConfig?,

	-- FlashList attempts to measure size of horizontal lists by drawing an extra list item in advance. This can sometimes cause issues when used with `initialScrollIndex` in lists
	-- with very little content. You might see some amount of over scroll. When set to true the list's rendered size needs to be deterministic (i.e., height and width greater than 0)
	-- as FlashList will skip rendering the extra item for measurement. Default value is `false`.
	disableHorizontalListHeightMeasurement: boolean?,

	-- FlashList applies some fixes to layouts of its children which can conflict with custom `CellRendererComponent`
	-- implementations. You can disable this behavior by setting this to `true`.
	-- Recommendation: Set this to `true` while you apply special behavior to the `CellRendererComponent`. Once done set this to
	-- `false` again.
	disableAutoLayout: boolean?,
}

export type FlashListState<TItem> = {
	data: { TItem }?,
	dataProvider: DataProvider,
	extraData: ExtraData<unknown>?,
	layoutProvider: GridLayoutProviderWithProps<TItem>,
	numColumns: number,
	renderItem: ListRenderItem<TItem>?,
}

export type FlashListComponent = PureComponent<
	FlashListProps<unknown>,
	FlashListState<unknown>
>

local RenderTargetOptions: Record<string, RenderTarget> = {
	Cell = "Cell",
	Measurement = "Measurement",
	StickyHeader = "StickyHeader",
}

return {
	RenderTargetOptions = RenderTargetOptions,
}
