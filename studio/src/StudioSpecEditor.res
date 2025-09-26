// OAuth Specification Editor
// Visual editor for creating .auth files

open Types

@react.component
let make = () => {
  let (spec, setSpec) = React.useState(() => emptySpec)
  let (selectedProvider, setSelectedProvider) = React.useState(() => "custom")

  // Provider templates
  let providerTemplates = [
    ("custom", "Custom Provider", emptySpec),
    ("google", "Google OAuth", {
      ...emptySpec,
      name: "Google OAuth",
      authorizeUrl: "https://accounts.google.com/o/oauth2/v2/auth",
      tokenUrl: "https://oauth2.googleapis.com/token",
      scopes: ["openid", "email", "profile"],
    }),
    ("github", "GitHub OAuth", {
      ...emptySpec,
      name: "GitHub OAuth",
      authorizeUrl: "https://github.com/login/oauth/authorize",
      tokenUrl: "https://github.com/login/oauth/access_token",
      scopes: ["read:user", "user:email"],
    }),
    ("ory-hydra", "Ory Hydra", {
      ...emptySpec,
      name: "Ory Hydra OAuth",
      authorizeUrl: "http://127.0.0.1:4444/oauth2/auth",
      tokenUrl: "http://127.0.0.1:4444/oauth2/token",
      scopes: ["openid", "offline_access", "profile", "email"],
    }),
  ]

  // Handle provider selection
  let handleProviderChange = (providerId) => {
    setSelectedProvider(_ => providerId)
    let template = providerTemplates
      ->Array.find(((id, _, _)) => id === providerId)
      ->Option.map(((_, _, template)) => template)
      ->Option.getOr(emptySpec)
    setSpec(_ => template)
  }

  <div className="min-h-screen bg-gray-50">
    // Header
    <header className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <div className="flex items-center">
            <button className="text-gray-500 hover:text-gray-700 mr-4">
              {"← Back"->React.string}
            </button>
            <h1 className="text-xl font-semibold text-gray-900">
              {"OAuth Spec Editor"->React.string}
            </h1>
          </div>
          <div className="flex items-center space-x-3">
            <button className="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50">
              {"Preview"->React.string}
            </button>
            <button className="px-3 py-2 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700">
              {"Generate SDK"->React.string}
            </button>
          </div>
        </div>
      </div>
    </header>

    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        // Left Panel - Form Editor
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-medium text-gray-900 mb-6">
            {"OAuth Configuration"->React.string}
          </h2>

          // Provider Templates
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {"Provider Template"->React.string}
            </label>
            <select
              className="w-full border border-gray-300 rounded-md px-3 py-2"
              value={selectedProvider}
              onChange={e => {
                let value = (e->ReactEvent.Form.target)["value"]
                handleProviderChange(value)
              }}>
              {providerTemplates
                ->Array.map(((id, name, _)) =>
                  <option key={id} value={id}>
                    {name->React.string}
                  </option>
                )
                ->React.array}
            </select>
          </div>

          // Form Fields
          <div className="space-y-4">
            <FormField
              label="Application Name"
              value={spec.name}
              onChange={value => setSpec(s => {...s, name: value})}
              placeholder="My OAuth App"
            />

            <FormField
              label="Client ID"
              value={spec.clientId}
              onChange={value => setSpec(s => {...s, clientId: value})}
              placeholder="your-client-id"
            />

            <FormField
              label="Authorization URL"
              value={spec.authorizeUrl}
              onChange={value => setSpec(s => {...s, authorizeUrl: value})}
              placeholder="https://provider.com/oauth2/authorize"
            />

            <FormField
              label="Token URL"
              value={spec.tokenUrl}
              onChange={value => setSpec(s => {...s, tokenUrl: value})}
              placeholder="https://provider.com/oauth2/token"
            />

            <FormField
              label="Redirect URI"
              value={spec.redirectUri}
              onChange={value => setSpec(s => {...s, redirectUri: value})}
              placeholder="http://localhost:3000/callback"
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {"Scopes"->React.string}
              </label>
              <input
                className="w-full border border-gray-300 rounded-md px-3 py-2"
                placeholder="openid,email,profile (comma-separated)"
                value={spec.scopes->Array.join(",")}
                onChange={e => {
                  let value = (e->ReactEvent.Form.target)["value"]
                  let scopes = value->String.split(",")->Array.map(String.trim)
                  setSpec(s => {...s, scopes})
                }}
              />
            </div>
          </div>
        </div>

        // Right Panel - Preview
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-medium text-gray-900 mb-6">
            {"Generated .auth File"->React.string}
          </h2>
          <div className="bg-gray-50 rounded-md p-4 font-mono text-sm">
            <AuthSpecPreview spec />
          </div>
        </div>
      </div>
    </div>
  </div>
}