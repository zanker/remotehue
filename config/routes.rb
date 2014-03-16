Remotehue::Application.routes.draw do
  resources :sessions, :only => :new

  get "/ping" => "internal#ping"
  get "/internal/state" => "internal#state"

  scope :module => :api, :as => :api, :path => "/api/v1" do
    controller :mailgun, :as => :mailgun, :path => "/mailgun/:secret" do
      post "/" => :trigger
    end

    controller :trigger, :as => :trigger, :path => "/trigger" do
      post "/:user_id/:trigger_id" => :activate, :as => :activate
    end
  end

  controller :sessions, :path => :sessions, :as => :session do
    get "/logout" => :destroy, :as => :logout
    get "/:provider/callback" => :create
    get "/failure" => :failure
  end

  resources :faq, :only => :index
  resource :subscription, :path => "/subscriptions", :only => :show

  resource :fastspring, :path => "/fastspring/:secret" do
    post "/sub/activated" => :sub_activated
    post "/sub/canceled" => :sub_canceled
    post "/sub/changed" => :sub_changed
    post "/sub/failed" => :sub_failed
    post "/sub/refund" => :sub_refund
    post "/order/notification" => :order_notification
  end

  scope :module => :usercp, :as => :usercp, :path => "" do
    controller :help, :path => :help, :as => :help do
      get "/meethue" => :meethue
      get "/ifttt/:trigger_id" => :ifttt, :as => :ifttt
    end

    resources :bridges do
      collection do
        post "/meethue-login" => :meethue_login, :as => :meethue_login
      end

      member do
        put "/resync" => :resync, :as => :resync
        put "/meethue-login" => :meethue_check, :as => :meethue_check
        put "/update-software" => :update_software, :as => :update_software
        get "/confirm-delete" => :confirm_destroy, :as => :confirm_destroy
      end
    end

    resources :triggers do
      member do
        get "/history" => :history, :as => :history
        get "/usage" => :usage, :as => :usage
        post "/regenerate" => :regenerate, :as => :regenerate
      end
    end

    resources :schedules do
      member do
        get "/usage" => :usage, :as => :usage
        get "/history" => :history, :as => :history
      end
    end

    resources :scenes
    resource :setting do
      member do
        put "/inline-location" => :inline_location, :as => :inline_location
        post "/solar" => :solar_events, :as => :solar_events
      end
    end

    resource :billing
  end

  get "/privacy-policy" => "home#privacy_policy", :as => :privacy_policy
  get "/terms-of-service" => "home#terms_conditions", :as => :terms_conditions
  get "/" => "home#show", :as => :root

  unless Rails.env.production?
    match "/404" => "error#routing"
  end
end
