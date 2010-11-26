BigTuna::Application.routes.draw do
  resources :projects do
    member { get "build"; get "remove" }
  end
  resources :builds
  match "/hooks/:hook_name", :to => "hooks#post_commit"
  root :to => "projects#index"
end
