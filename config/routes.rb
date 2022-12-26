Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users' }
  mount LetterOpenerWeb::Engine, at: "/mails" if Rails.env.development?
  get "/read_xml" => "application#read_xml"
  match "/settings" => "application#settings", via: [:get, :post]
  devise_scope :user do
    authenticated :user do
      root to: 'dashboard#index'
    end

    unauthenticated do
      root to: 'devise/sessions#new', as: :unauthenticated_root
    end
  end
  resources :roles
  resources :users
  resources :xml_files do
    get :read_xml_files, on: :collection 
    resources :parts do 
      get :re_process
      get :req_body
    end
    resources :bom_headers do 
      get :re_process
      get :req_body
    end
    resources :bom_components
    resources :documents do 
      get :re_process
      get :req_body
      
    end
    resources :document_uploads do 
      get :re_process
    end
    get "/parts/view/:type" => "parts#index", as: :parts_by_type
    get "/bom_headers/view/:type" => "bom_headers#index", as: :bom_headers_by_type
    get "/documents/view/:type" => "documents#index", as: :documents_by_type
    get "/document_uploads/view/:type" => "document_uploads#index", as: :document_uploads_by_type
    get "/view/:type" => "xml_files#show", as: :xml_contents
  end
end
