$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "edgar/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "edgar"
  s.version     = Edgar::VERSION
  s.authors     = ["adilbenseddik"]
  s.email       = ["adil.benseddik@mabcs.com"]
  s.homepage    = "https://wwww.mabcs.com"
  s.summary     = "Edgar is a Google Adwords/Youtube performence dashboard."
  s.description = "Edgar uses Google SDK and influxDB to publish Adwords KPI in time series format."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0", ">= 5.0.0.1"
  s.add_dependency "sidekiq"
  s.add_dependency "sidetiq"
  s.add_dependency "influxdb"
  s.add_dependency "google-adwords-api"

  s.add_development_dependency "byebug"
end
