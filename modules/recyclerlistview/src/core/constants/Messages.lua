-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/constants/Messages.ts

local Messages = {
	ERROR_LISTVIEW_VALIDATION = "missing datasource or layout provider, cannot proceed without it",
	WARN_SCROLL_TO_INDEX = "scrollTo was called before RecyclerListView was measured, please wait for the mount to finish",
	VISIBLE_INDEXES_CHANGED_DEPRECATED = "onVisibleIndexesChanged deprecated. Please use onVisibleIndicesChanged instead.",
	ANIMATION_ON_PAGINATION = "Looks like you're trying to use RecyclerListView's layout animation render while doing pagination. "
		.. "This operation will be ignored to avoid creation of too many items due to developer error.",
}

return Messages
