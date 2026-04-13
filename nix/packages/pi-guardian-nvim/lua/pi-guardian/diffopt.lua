local M = {}

M.DEFAULT_CONTEXT = 6
M.CONTEXT_STEP = 5

---@return string[]
local function items()
  return vim.split(vim.go.diffopt, ",", { plain = true, trimempty = true })
end

---@return integer
function M.get_context()
  for _, item in ipairs(items()) do
    local value = item:match("^context:(%d+)$")
    if value then
      return tonumber(value) or M.DEFAULT_CONTEXT
    end
  end
  return M.DEFAULT_CONTEXT
end

---@param context integer
function M.set_context(context)
  context = math.max(0, context)
  local filtered = {}
  for _, item in ipairs(items()) do
    if not item:match("^context:%d+$") then
      filtered[#filtered + 1] = item
    end
  end
  filtered[#filtered + 1] = "context:" .. context
  vim.go.diffopt = table.concat(filtered, ",")
end

--- Expand diff context by one step.
function M.expand()
  M.set_context(math.max(M.DEFAULT_CONTEXT, M.get_context() + M.CONTEXT_STEP))
end

--- Shrink diff context by one step.
function M.shrink()
  M.set_context(math.max(0, M.get_context() - M.CONTEXT_STEP))
end

return M
