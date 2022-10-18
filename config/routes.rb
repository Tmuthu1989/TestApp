Rails.application.routes.draw do
  resources :posts
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "posts#index"
  get "/read_xml" => "application#read_xml"
  match "/settings" => "application#settings", via: [:get, :post]
  resources :xml_files do
    get :read_xml_files, on: :collection 
  end
end
