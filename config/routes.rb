Rails.application.routes.draw do
  resources :posts, param: :slug do
    member do
      patch :publish
      patch :unpublish
    end
  end

  resources :projects, param: :slug do
    member do
      patch :publish
      patch :unpublish
    end
  end

  resource :session
  resource :registration, only: [:new, :create]
  resources :passwords, param: :token

  resources :events do
    member do
      patch :publish
      patch :unpublish
    end
  end

  get "faq", to: "faqs#index", as: :faq
  get "artists", to: "artists#index", as: :artists

  namespace :admin do
    resources :faqs do
      member do
        patch :move_up
        patch :move_down
      end
    end
    resources :users do
      member do
        post :approve
      end
    end
    resources :memberships do
      resources :payments, only: [ :create, :destroy ]
    end
    resources :pages do
      member do
        patch :publish
        patch :unpublish
      end
    end
    resources :email_groups do
      member do
        post :add_member
        delete :remove_member
      end
    end
    resources :proposals, only: [ :index, :show ] do
      member do
        post :approve
        post :reject
      end
    end
    resources :inbox, only: [ :index, :show ] do
      member do
        post :create_todo
        post :create_newsletter
        post :create_funding
        post :archive
        post :unarchive
        get "attachments/:attachment_id", action: :attachment, as: :attachment
      end
      collection do
        post :batch_archive
      end
    end
    resources :todos do
      member do
        patch :toggle
      end
      collection do
        post :batch_complete
        post :batch_delete
      end
    end
  end

  # Static pages (must be near end to catch /:slug)
  get "pages/:slug", to: "pages#show", as: :page

  # Member directory
  resources :profiles, only: [ :index, :show ]
  get "my_profile", to: "profiles#show_my_profile", as: :my_profile
  post "my_profile", to: "profiles#create"
  patch "my_profile", to: "profiles#update"

  # Membership payments (SumUp)
  resources :memberships, only: [] do
    resource :payment, controller: "membership_payments", only: [ :new ] do
      post :create_checkout
      get :complete
    end
  end

  # Newsletters (editor-only)
  resources :newsletters do
    member do
      post :compose_with_ai
      post :import_email
      post :export_to_brevo
    end
  end

  # Funding opportunities
  resources :funding_opportunities do
    resources :proposals, only: [ :new, :create, :edit, :update ] do
      member do
        post :submit
      end
    end
  end

  # Space bookings
  get "calendar", to: "bookings#calendar", as: :calendar
  resources :bookings, except: [ :index, :show ] do
    member do
      patch :confirm
      patch :cancel
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Forum
  mount Thredded::Engine => "/forum"

  # Defines the root path route ("/")
  root "home#index"
end
