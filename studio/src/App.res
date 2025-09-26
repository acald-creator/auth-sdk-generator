// Auth SDK Studio Main Application

// Navigation state
type view = Dashboard | SpecEditor | Templates

@react.component
let make = () => {
  let (currentView, setCurrentView) = React.useState(() => Dashboard)

  // Navigation functions
  let goToDashboard = () => setCurrentView(_ => Dashboard)
  let goToSpecEditor = () => setCurrentView(_ => SpecEditor)
  let goToTemplates = () => setCurrentView(_ => Templates)

  // Render current view
  switch currentView {
  | Dashboard => <StudioDashboard />
  | SpecEditor => <StudioSpecEditor />
  | Templates => <TemplatesView goBack=goToDashboard />
  }
}