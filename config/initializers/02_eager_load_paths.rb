# Extend Rails autoload to include app/services.
# Using eager_load_paths (immutable) instead of autoload_paths avoids the FrozenError.
Rails.application.config.eager_load_paths += %W[
  #{Rails.root.join('app/services')}
]

# Tell Zeitwerk that the 'api' namespace should be `Api::` (not `API::`).
# Without this, Rails' default inflector treats `api` as an acronym.
Rails.autoloaders.each do |loader|
  loader.inflector.inflect('api' => 'Api')
end
