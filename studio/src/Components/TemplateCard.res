// Template Card Component
@react.component
let make = (~name, ~description, ~icon) => {
  <div className="bg-white rounded-lg shadow p-6 cursor-pointer hover:shadow-md transition-shadow">
    <div className="text-2xl mb-3">
      {icon->React.string}
    </div>
    <h3 className="text-lg font-medium text-gray-900 mb-2">
      {name->React.string}
    </h3>
    <p className="text-gray-600 text-sm">
      {description->React.string}
    </p>
  </div>
}