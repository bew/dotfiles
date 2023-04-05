local M = {}

function M.normalize_event_spec(event_spec)
  local spec = {tags={}}
  if type(event_spec) == "string" then
    spec.name = event_spec
  elseif type(event_spec) == "table" then
    spec.name = event_spec[1]
    spec.tags = event_spec.tags
  end
  return spec
end

function M.normalize_event_specs(event_specs)
  local normalized_specs = {}
  for _, event_spec in ipairs(event_specs) do
    table.insert(normalized_specs, M.normalize_event_spec(event_spec))
  end
  return normalized_specs
end

return M
