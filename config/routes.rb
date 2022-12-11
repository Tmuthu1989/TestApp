Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "xml_files#index"
  get "/read_xml" => "application#read_xml"
  match "/settings" => "application#settings", via: [:get, :post]
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
    resources :documents
    get "/parts/view/:type" => "parts#index", as: :parts_by_type
    get "/bom_headers/view/:type" => "bom_headers#index", as: :bom_headers_by_type
    get "/view/:type" => "xml_files#show", as: :xml_contents
  end
end
