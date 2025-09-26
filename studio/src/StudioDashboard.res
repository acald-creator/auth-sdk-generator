// Auth SDK Studio Dashboard
// Main landing page for the studio interface

@react.component
let make = () => {
  <div className="min-h-screen bg-gray-50">
    // Header
    <header className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <div className="flex items-center">
            <h1 className="text-2xl font-bold text-gray-900">
              {"Auth SDK Studio"->React.string}
            </h1>
            <span className="ml-2 px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">
              {"Beta"->React.string}
            </span>
          </div>
          <div className="flex items-center space-x-4">
            <button className="text-gray-500 hover:text-gray-700">
              {"Docs"->React.string}
            </button>
            <button className="text-gray-500 hover:text-gray-700">
              {"GitHub"->React.string}
            </button>
          </div>
        </div>
      </div>
    </header>

    // Main Content
    <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      // Welcome Section
      <div className="text-center mb-12">
        <h2 className="text-3xl font-bold text-gray-900 mb-4">
          {"Generate OAuth SDKs Visually"->React.string}
        </h2>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
          {"Create type-safe authentication SDKs for TypeScript, Python, and more. Design OAuth flows, preview code, and download production-ready packages."->React.string}
        </p>
      </div>

      // Quick Actions Grid
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <QuickActionCard
          title="Create New Spec"
          description="Start from scratch or use a template"
          icon="✨"
          primary=true
          onClick={() => Js.log("Navigate to spec editor")}
        />
        <QuickActionCard
          title="Browse Templates"
          description="Google, GitHub, Auth0, Ory Hydra"
          icon="📚"
          onClick={() => Js.log("Navigate to templates")}
        />
        <QuickActionCard
          title="Import Existing"
          description="Upload existing auth configuration"
          icon="📤"
          onClick={() => Js.log("Show import dialog")}
        />
      </div>

      // Recent Projects (placeholder)
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          {"Recent Projects"->React.string}
        </h3>
        <div className="text-gray-500 text-center py-8">
          {"No recent projects. Create your first OAuth spec to get started!"->React.string}
        </div>
      </div>
    </main>
  </div>
}