<h1 align="center">telepath.nvim</h1>

<p align="center"><sup>Motion plugin you don't know you've been missing.</sup></p>

> **telepathy**:
>
>     thought-transference.

> **telepath**:
>
>     a person who uses telepathy.

`telepath.nvim` is a [Leap](https://github.com/ggandor/leap.nvim) extension that allows you to operate on remote textobjects like built-in ones, from treesitter and any others.

## Features

-  Jump: jump directly to a place you plan to operate from
-  Cursor restoration: return to your initial position after performing operations
-  Recursion: support for recursive operations
-  Search everywhere: `telepath.nvim` uses bidirectional search in all windows by default
-  Textobjects: `telepath.nvim` doesn't create any textobjects. Instead, you can use all of yours.

## Why

Why creating a new plugin when we already have [`leap-spooky.nvim`](https://github.com/ggandor/leap-spooky.nvim) or [`flash.nvim`](https://github.com/folke/flash.nvim)?

First of all, for people who use `Leap` as their main jump engine instead of `flash`, but prefer flash's way to operate on remote textobjects. I personally also prefer flash's way
just because you don't need to create custom mappings on every textobject you plan to operate remotely on. Most importantly, using this way of performing remote actions means that all of the textobjects (including ones from plugins or custom) you have are supported. It also feels more natural and intuitive to type `dr` for `delete remote`, so your final combination will look like this: `dr{search}iw` to delete a word and return back to your initial cursor position.

In short, the main idea is to take the best of 2 worlds, for me that's:

1. Leap's jump engine
2. Flash's way of operating on remote textobjects

### Differences from leap-spooky.nvim

- All textobjects are supported since `telepath.nvim` doesn't bring any new ones and only take you to a place in a file
- Recursive operations

### Differences from flash.nvim

There're almost no differences between `flash` and `telepath` except having recursive operations.

## Requirements

[leap.nvim](https://github.com/ggandor/leap.nvim)

## Installation

With lazy.nvim:

To use default mappings:

```lua
{
  'rasulomaroff/telepath.nvim',
  dependencies = 'ggandor/leap.nvim',
  -- there's no sence in using lazy loading since telepath won't load the main module
  -- until you actually use mappings
  lazy = false,
  config = function()
    require('telepath').use_default_mappings()
  end
}
```

To use custom mappings:

```lua
{
  'rasulomaroff/telepath.nvim',
  dependencies = 'ggandor/leap.nvim',
  keys = {
    -- you can use your own keys
    { 'r', function() require('telepath').remote { restore = true } end, mode = 'o' },
    { 'R', function() require('telepath').remote { restore = true, recursive = true } end, mode = 'o' },
    { 'j', function() require('telepath').remote() end, mode = 'o' },
    { 'J', function() require('telepath').remote { recursive = true } end, mode = 'o' }
  }
}
```

## Configuration

### Default mappings

All mappings are operator-pending mode only and listed below:

1. `r` - stands for `restore` or `return`. Operates on remote textobject and return you back to the initial position.
2. `j` - stands for `jump`. The same as `r`, but won't return you back to the initial position.
3. `R` - stands for `restore recursive`. After performing any action, Leap's `search` mode will be triggered again with the same operator. You can exit this state by pressing escape and you'll be returned to your initial cursor position.
4. `J` - the same as `R`, but won't return you to the initial position.

To use default mappings, simply call `use_default_mappings` method:

```lua
require('telepath').use_default_mappings()
```

By default, `telepath` won't overwrite any existing mappings, if you want it to do so, pass `overwrite` boolean field:

```lua
require('telepath').use_default_mappings { overwrite = true }
```

If you only want to use certain default mappings, you can do it by passing `keys` field:

```lua
-- you can pass overwrite property here as well
require('telepath').use_default_mappings { keys = { 'r', 'j' } }
```

### Custom mappings

To create a custom mapping, you need to use `remote` method of the module, where you can pass additional params:

```lua
require('telepath').remote()
```

There are 2 options available:

```lua
require('telepath').remote {
  -- will restore your cursor after an operation, default is false
  restore = false,
  -- will trigger leap mode with the same operator after every operation,
  -- until you press escape, default is false
  recursive = false
}
```
