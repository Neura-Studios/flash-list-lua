<div align="center">

# `⚡ FlashList Lua`

<a href="https://neura-studios.github.io/flash-list-lua/">Website</a> •
<a href="https://discord.gg/Qm3JNyEc32">Discord</a> •
<a href="https://neura-studios.github.io/flash-list-lua/">Getting started</a> •
<a href="https://neura-studios.github.io/flash-list-lua/usage">Usage</a> •
<a href="https://neura-studios.github.io/flash-list-lua/performance-troubleshooting">Performance</a> •
<a href="https://neura-studios.github.io/flash-list-lua/fundamentals/performant-components">Writing performant components</a> •
<a href="https://neura-studios.github.io/flash-list-lua/known-issues">Known Issues</a>

**Fast & performant React Roblox list. No more blank cells.**

Swap from FlatList in seconds. Get instant performance.

</div>

> ### ⚠️ **Here Be Dragons 🐉**
>
> FlashList-Lua is not yet ready for real-world use, and this repository is only open due to high demand. I will be away until early August and won't be around to work on the project until then.
>
> We are still testing FlashList inside of Clip It. We've deployed simple cases in production, but are still ironining out the bugs.
>
> **Also note** that the GitHub releases are broken. At the time of writing, the latest release on Wally is `rc.7`.

## Installation

FlashList Lua supports installation via NPM or Wally.

### NPM

`npm add @neura-studios/flash-list`

`yarn add @neura-studios/flash-list`

### Wally

```toml
[dependencies]
FlashList = "neura-studios/flash-list@^1.0.0"
```

## Usage

We recommend reading the detailed documentation for using `FlashList` [here](https://neura-studios.github.io/flash-list-lua/usage).

But if you are familiar with [FlatList](https://github.com/jsdotlua/virtualized-list-lua), you already know how to use `FlashList`. You can try out `FlashList` by changing the component name and adding the `estimatedItemSize` prop or refer to the example below:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local FlashList = require(Packages.FlashList)

local e = React.createElement

local DATA = {
    {
        title = "First Item",
    },
    {
        title = "Second Item",
    },
}

local function MyList()
    return e(FlashList.FlashList, {
        data = DATA,
        estimatedItemSize = 200,
        renderItem = function(entry)
            local item = entry.item
            return e("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                Text = item.title,
            })
        end,
    })
end
```

To avoid common pitfalls, you can also follow these steps for migrating from `FlatList`, based on our own experiences:

1. Switch from `FlatList` to `FlashList` and render the list once. You should see a warning about missing `estimatedItemSize` and a suggestion. Set this value as the prop directly.
2. **Important**: Scan your [`renderItem`](https://neura-studios.github.io/flash-list-lua/docs/usage/#renderitem) hierarchy for explicit `key` prop definitions and remove them. If you’re doing a `.map()` use indices as keys.
3. Check your [`renderItem`](https://neura-studios.github.io/flash-list-lua/docs/usage/#renderitem) hierarchy for components that make use of `useState` and verify whether that state would need to be reset if a different item is passed to that component (see [Recycling](https://neura-studios.github.io/flash-list-lua/docs/recycling))
4. If your list has heterogenous views, pass their types to `FlashList` using [`getItemType`](https://neura-studios.github.io/flash-list-lua/docs/usage/#getitemtype) prop to improve performance.
5. Do not test performance with React dev mode on. Make sure you’re in release mode. `FlashList` can appear slower while in dev mode due to a small render buffer.

## Unsupported Features

Not all features from FlashList or `recyclerlistview` are ported in this translation. Some notable exclusions are:

- `RefreshControl` currently has no implementation in Axon. That's currently blocking refresh gesture support in this package.
- Item animators aren't currently supported because there's no clear path for how to animate item layouts and entry/exist animations in Roblox. Could likely be revisited later if we come across a need for this.
- Inverted lists aren't currently supported because Roblox lacks the matrix transforms used in upstream to make it work and I don't have the time to work out an alternative path. We don't have a use case for this.
