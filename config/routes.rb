Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount Litestream::Engine, at: "/litestream"

  namespace :api do
    namespace :v1 do
      resources_only = { only: [ :index, :show, :create, :update ] }
      resources :faqs, **resources_only
      resources :pages, **resources_only
      resources :posts, **resources_only
      resources :events, **resources_only
      resources :newsletters, **resources_only
      resources :funding_opportunities, **resources_only
      resources :spaces, **resources_only
      resources :bookings, **resources_only
      resources :memberships, **resources_only
      resources :proposals, **resources_only
      resources :payments, **resources_only
      resources :tickets, **resources_only
      resources :email_groups, **resources_only
      resources :admin_todos, **resources_only
      resources :profiles, **resources_only
      resources :users, **resources_only
    end
  end

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
  resource :registration, only: [ :new, :create ]
  get "membership", to: redirect("/registration/new")
  resources :passwords, param: :token

  resources :events do
    member do
      patch :publish
      patch :unpublish
    end
    resource :tickets, controller: "event_tickets", only: [ :new ] do
      post :create_checkout
      get :complete
      get :receipt
    end
  end

  get "faq", to: "faqs#index", as: :faq
  get "artists", to: "artists#index", as: :artists
  resource :contact, only: [ :show, :create ]

  namespace :admin do
    resources :ticket_sales, only: [ :index, :show ]
    resources :payments, only: [ :index ]
    resources :bookings, only: [ :index ] do
      member do
        patch :toggle_paid
      end
    end
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
      member do
        post :mark_as_paid
      end
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
    resources :funding_opportunities, only: [ :index ] do
      collection do
        post :refresh
      end
      member do
        post :approve
      end
    end
    resources :inbox, only: [ :index, :show ] do
      member do
        post :create_todo
        post :create_newsletter
        post :create_funding
        post :archive
        post :unarchive
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
    resources :calendar_imports, only: [ :new, :create ]
    resources :transactions, only: [ :index ]
  end

  # Redirect old /pages/:slug URLs
  get "pages/:slug", to: redirect("/%{slug}")

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

  # General payments (SumUp)
  resource :payment, controller: "payments", only: [ :new ] do
    post :create_checkout
    get :complete
  end

  # Newsletters (editor-only)
  resources :newsletters do
    member do
      post :compose_with_ai
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
      patch :mark_as_paid
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Dashboard (authenticated users)
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Forum
  mount Thredded::Engine => "/forum"

  # Newsletter (public archive + signup)
  get "newsletter", to: "newsletter_subscriptions#new", as: :newsletter_page
  post "newsletter/subscribe", to: "newsletter_subscriptions#create", as: :newsletter_subscribe
  get "newsletter/qr.svg", to: "newsletter_subscriptions#qr_code", as: :newsletter_qr_code

  # Locale switcher — sets session locale and redirects back
  get "locale/:locale", to: "locales#update", as: :switch_locale,
      constraints: { locale: /en|ga/ }

  # Irish locale pages — kept for direct linking / admin preview
  get "ga/:slug", to: "pages#show", defaults: { locale: "ga" }, as: :ga_page

  # Static pages (catch-all, must be last before root)
  get ":slug", to: "pages#show", as: :page

  # Defines the root path route ("/")
  root "home#index"
end
