<h1 align="center">telepath.nvim</h1>

<p align="center"><sup>Motion plugin you don't know you've been missing.</sup></p>

> **telepathy**:
>
>     thought-transference.

> **telepath**:
>
>     a person who uses telepathy.

`telepath.nvim` is a [Leap](https://github.com/ggandor/leap.nvim) extension that allows you to operate on remote textobjects like built-in ones, from treesitter and any others.


<h2 align="center">Demo</h2>

https://github.com/rasulomaroff/telepath.nvim/assets/80093436/e25033bb-2ec3-49d1-b879-0d53ff2e7653


## Features

-  Jump: jump directly to a place you plan to operate from
-  Cursor restoration: return to your initial position after performing operations
-  Recursion: support for recursive operations
-  Search everywhere: `telepath.nvim` uses bidirectional search in all windows by default
-  Textobjects: `telepath.nvim` doesn't create any textobjects. Instead, you can use all of yours.
-  Window restoration: you can turn on/off window restoration for a source window, other windows or for all of them.

## Why

Why creating a new plugin when we already have [`leap-spooky.nvim`](https://github.com/ggandor/leap-spooky.nvim) or [`flash.nvim`](https://github.com/folke/flash.nvim)?

First of all, `telepath` is for people who use `Leap` as their main jump engine instead of `flash`, but prefer flash's way to operate on remote textobjects. I personally also prefer flash's way
just because you don't need to create custom mappings on every textobject you plan to operate remotely on. Most importantly, using this way of performing remote actions means that all of the textobjects (including ones from plugins or custom) you have are supported. It also feels more natural and intuitive to type `dr` for `delete remote`, so your final combination will look like this: `dr{search}iw` to delete a word and return back to your initial cursor position.

In short, the main idea is to take the best of 2 worlds, for me that's:

1. Leap's jump engine
2. Flash's way of operating on remote textobjects

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
    { 'm', function() require('telepath').remote() end, mode = 'o' },
    { 'M', function() require('telepath').remote { recursive = true } end, mode = 'o' }
  }
}
```

## Usage

I would recommend reading [Leap's](https://github.com/ggandor/leap.nvim) documentation as well to have a full understanding of it, but together with `telepath` your usage will look like that:

`dr{search}{textobject}`

- `d` - this is an operator. In this case it's `delete`, but you can use any, even custom ones.
- `r` - stands for `remote`. You can configure this key as well as you can configure the way it behaves. It must always go after an operator key.
- `{search}` - this is a 2 or 3 key pattern to jump to the specific location you want to operate on. More about it in [Leap's](https://github.com/ggandor/leap.nvim) documentation.
- `{textobject}` - this is a specific textobject you want to apply your operator on. For example `i(` - inside parentheses. You can use any textobject available in your configuration.

Curly brackets in `search` and `textobject` are meant to emphasize semantic meaning, you don't need to use them.

## Configuration

### Options

There're 4 options you can pass to the `remote` method:

1. `restore` - will restore your cursor to the original position after an operation. `Default: false`
2. `recursive` - will trigger leap mode with the same operator after every operation. `Default: false`
3. `jumplist` - will set jump points on every jump. `Default: true`
4. `window_restore` - will restore windows when leaving them or after a remote action. You can pass either a boolean to enable/disable all windows restorations or a table `{ source = true, rest = true }` where
`source` means "restore a source window" and `rest` - "restore all windows except a source one". `Default: true` - enabled for all windows.

Example:

```lua
require('telepath').remote {
  restore = false,
  recursive = false,
  jumplist = true,
  -- only restore other windows, but not the source one
  window_restore = { source = false, rest = true } -- you can also pass true/false to enable/disable all of the options
}
```

### Default mappings

All mappings are operator-pending mode only and listed below:

1. `r` - stands for `restore` or `return`. Operates on remote textobject and return you back to the initial position.
2. `m` - stands for `magnet`. The same as `r`, but won't return you back to the initial position.
3. `R` - stands for `restore recursive`. After performing any action, Leap's `search` mode will be triggered again with the same operator. You can exit this state by pressing escape and you'll be returned to your initial cursor position.
4. `M` - the same as `R`, but won't return you to the initial position.

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
-- you can pass  the `overwrite` property here as well
require('telepath').use_default_mappings { keys = { 'r', 'm' } }
```

### Custom mappings

To create a custom mapping, you need to use the `remote` method of the module, where you can pass optional [params](#options).
After that, set that function to your preferred key:

```lua
vim.keymap.set('o', 'r', function()
  require('telepath').remote {
    -- options
  }
end, { desc = 'Remote action' })
```
