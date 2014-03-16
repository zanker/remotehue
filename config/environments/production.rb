Remotehue::Application.configure do
  Haml::Template.options[:ugly] = true

  config.action_controller.page_cache_directory = "public/cache"

  config.threadsafe!

  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  config.assets.js_compressor = :uglifier

  config.cache_classes = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.serve_static_assets = false

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  DEPLOY_ID = Digest::SHA1.hexdigest("#{Time.now.to_f}")
end