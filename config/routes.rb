Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"

  get "legal_basis", to: "legal_basis#index", as: :legal_basis

  namespace :rubric_recovery do
    get "radar", to: "radar#show", as: :radar
    get "adequacy", to: "adequacy#index", as: :adequacy
    get "adequacy/:rubric_event_id", to: "adequacy#show", as: :adequacy_event
    post "adequacy/:rubric_event_id/assignments", to: "adequacy_assignments#create", as: :adequacy_assignments
    get "rubrics_natures", to: "rubrics_natures#index", as: :rubrics_natures
    patch "rubrics_natures/:assignment_id", to: "rubrics_natures#update", as: :rubrics_nature
  end

  namespace :rubricas_cte do
    root "chain_walk#index"
    get "dashboard", to: "dashboard#index", as: :dashboard
    get "chain_walk", to: "chain_walk#index", as: :chain_walk
  end

  namespace :esocial do
    get "certificado", to: "preflight#index", as: :certificado
    get "preflight", to: redirect("/esocial/certificado"), as: :preflight
    resources :certificates, only: [:create, :destroy] do
      post "test_connection", on: :member
    end
    resources :company_authorizations, only: [:create, :destroy]
    get "sync", to: "sync#index", as: :sync
    post "sync/runs", to: "sync_runs#create", as: :sync_runs
    get "tabelas_empresa", to: "company_tables#index", as: :company_tables
    get "tabelas_empresa/s1005.xlsx", to: "company_tables#s1005_xlsx", as: :company_tables_s1005_xlsx
    get "tabelas_empresa/s1005/xml", to: "company_tables#s1005_xml", as: :company_tables_s1005_xml
    get "tabelas_empresa/s1020.xlsx", to: "company_tables#s1020_xlsx", as: :company_tables_s1020_xlsx
    get "tabelas_empresa/s1020/xml", to: "company_tables#s1020_xml", as: :company_tables_s1020_xml
    get "lotacoes", to: "lotacoes#index", as: :lotacoes
    get "estabelecimentos_obras", to: "estabelecimentos_obras#index", as: :estabelecimentos_obras
  end

  resources :case_files, only: [:index, :new, :create, :show]
  resources :simulations, only: [:index, :new, :create, :show]
  resources :tax_parameters, only: [:index]
  resources :assumptions, only: [:index]
end
