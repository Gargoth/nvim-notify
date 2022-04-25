local M = {}
local util = require("notify.util")

require("notify.config.highlights")

local BUILTIN_RENDERERS = {
  DEFAULT = "default",
  MINIMAL = "minimal",
}

local BUILTIN_STAGES = {
  FADE = "fade",
  SLIDE = "slide",
  FADE_IN_SLIDE_OUT = "fade_in_slide_out",
  STATIC = "static",
}

local default_config = {
  level = "info",
  timeout = 5000,
  max_width = nil,
  max_height = nil,
  stages = BUILTIN_STAGES.FADE_IN_SLIDE_OUT,
  render = BUILTIN_RENDERERS.DEFAULT,
  background_colour = "Normal",
  on_open = nil,
  on_close = nil,
  minimum_width = 50,
  icons = {
    ERROR = "",
    WARN = "",
    INFO = "",
    DEBUG = "",
    TRACE = "✎",
  },
}

local user_config = default_config

local opacity_warned = false

local function validate_highlight(colour_or_group, needs_opacity)
  if type(colour_or_group) == "function" then
    return colour_or_group
  end
  if colour_or_group:sub(1, 1) == "#" then
    return function()
      return colour_or_group
    end
  end
  return function()
    local group_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(colour_or_group)), "bg#")
    if group_bg == "" or group_bg == "none" then
      if needs_opacity and not opacity_warned then
        opacity_warned = true
        vim.schedule(function()
          vim.notify(
            "Highlight group '"
              .. colour_or_group
              .. "' has no background highlight.\n\n"
              .. "Please provide an RGB hex value or highlight group with a background value for 'background_colour' option\n\n"
              .. "Defaulting to #000000",
            "warn",
            { title = "nvim-notify" }
          )
        end)
      end
      return "#000000"
    end
    return group_bg
  end
end

function M.setup(config)
  local filled = vim.tbl_deep_extend("keep", config or {}, default_config)
  user_config = filled
  local stages = M.stages()

  local needs_opacity = vim.tbl_contains(
    { BUILTIN_STAGES.FADE_IN_SLIDE_OUT, BUILTIN_STAGES.FADE },
    stages
  )

  if needs_opacity and not vim.opt.termguicolors:get() then
    filled.stages = BUILTIN_STAGES.STATIC
    vim.schedule(function()
      vim.notify(
        "Opacity changes require termguicolors to be set.\nChange to different animation stages or set termguicolors to disable this warning",
        "warn",
        { title = "nvim-notify" }
      )
    end)
  end

  user_config.background_colour = validate_highlight(user_config.background_colour, needs_opacity)
end

---@param colour_or_group string

function M.level()
  return vim.lsp.log_levels[user_config.level] or vim.lsp.log_levels.INFO
end

function M.background_colour()
  return tonumber(user_config.background_colour():gsub("#", "0x"), 16)
end

function M.icons()
  return user_config.icons
end

function M.stages()
  return user_config.stages
end

function M.default_timeout()
  return user_config.timeout
end

function M.on_open()
  return user_config.on_open
end

function M.on_close()
  return user_config.on_close
end

function M.render()
  return user_config.render
end

function M.minimum_width()
  return user_config.minimum_width
end

function M.max_width()
  return util.is_callable(user_config.max_width) and user_config.max_width()
    or user_config.max_width
end

function M.max_height()
  return util.is_callable(user_config.max_height) and user_config.max_height()
    or user_config.max_height
end

return M
