// Quick Action Card Component
@react.component
let make = (~title, ~description, ~icon, ~primary=false, ~onClick) => {
  let baseClasses = "p-6 rounded-lg border cursor-pointer transition-all duration-200 hover:shadow-md"
  let cardClasses = primary
    ? baseClasses ++ " bg-blue-50 border-blue-200 hover:bg-blue-100"
    : baseClasses ++ " bg-white border-gray-200 hover:bg-gray-50"

  <div className=cardClasses onClick={_ => onClick()}>
    <div className="text-2xl mb-3">
      {icon->React.string}
    </div>
    <h3 className="text-lg font-medium text-gray-900 mb-2">
      {title->React.string}
    </h3>
    <p className="text-gray-600 text-sm">
      {description->React.string}
    </p>
  </div>
}