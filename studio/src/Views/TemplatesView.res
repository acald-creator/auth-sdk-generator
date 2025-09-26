// Templates View - OAuth Provider Templates
@react.component
let make = (~goBack) => {
  <div className="min-h-screen bg-gray-50">
    <header className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <div className="flex items-center">
            <button className="text-gray-500 hover:text-gray-700 mr-4" onClick={_ => goBack()}>
              {"← Back"->React.string}
            </button>
            <h1 className="text-xl font-semibold text-gray-900">
              {"OAuth Templates"->React.string}
            </h1>
          </div>
        </div>
      </div>
    </header>

    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <TemplateCard
          name="Google OAuth"
          description="Google Cloud OAuth 2.0 configuration"
          icon="🔍"
        />
        <TemplateCard
          name="GitHub OAuth"
          description="GitHub OAuth Apps configuration"
          icon="🐙"
        />
        <TemplateCard
          name="Ory Hydra"
          description="Ory Hydra OAuth 2.0 server"
          icon="🌊"
        />
        <TemplateCard
          name="Auth0"
          description="Auth0 Universal Login"
          icon="🔐"
        />
        <TemplateCard
          name="Microsoft Azure"
          description="Azure Active Directory"
          icon="🏢"
        />
        <TemplateCard
          name="Custom Provider"
          description="Build your own OAuth configuration"
          icon="⚙️"
        />
      </div>
    </div>
  </div>
}