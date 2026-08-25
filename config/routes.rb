Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # O app é exclusivamente o Auditor Fiscal, servido na raiz do domínio.
  # Helpers permanecem `fiscal_auditor_*`; as URLs ficam sem o prefixo /auditor-fiscal.
  namespace :fiscal_auditor, path: "" do
    root "dashboard#show"
    get "contas-a-receber", to: "receivables#show", as: :receivables
    get "cruzamento", to: "reconciliation#show", as: :reconciliation
    get "folha", to: "payroll#show", as: :payroll
    get "folha/descontos-e-encargos", to: "payroll_charges#show", as: :payroll_charges
    get "folha/detalhamento/:client_code/:period", to: "payroll_details#show", as: :payroll_detail
    get "despesas", to: "expenses#show", as: :expenses
    get "explorador-de-despesas", to: "expense_explorer#show", as: :expense_explorer
    get "extrato-conta-vinculada", to: "linked_accounts#show", as: :linked_accounts
    get "cruzamento-efd-razao", to: "efd_razao#show", as: :efd_razao
    get "devolucoes", to: "devolucao#show", as: :devolucoes
    get "comparativo", to: "comparativo#show", as: :comparativo
    get "lotacoes-tributarias", to: "tax_lotations#index", as: :tax_lotations
    get "relatorios", to: "generated_reports#index", as: :generated_reports
    get "memoria-de-calculo/:module_name/:metric", to: "calculation_details#show", as: :calculation_detail
    get "visualizador-de-planilha", to: "spreadsheets#show", as: :spreadsheet
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout
    get "empresas", to: "companies#index", as: :companies
    post "empresas/:company", to: "companies#select", as: :select_company, constraints: { company: /appa|solucoes/ }
    resources :users, path: "usuarios", except: %i[show]
  end

  root "fiscal_auditor/dashboard#show"
end
