// Form Field Component
@react.component
let make = (~label, ~value, ~onChange, ~placeholder="") => {
  <div>
    <label className="block text-sm font-medium text-gray-700 mb-2">
      {label->React.string}
    </label>
    <input
      className="w-full border border-gray-300 rounded-md px-3 py-2"
      value
      placeholder
      onChange={e => {
        let value = (e->ReactEvent.Form.target)["value"]
        onChange(value)
      }}
    />
  </div>
}