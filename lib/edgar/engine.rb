require 'sidetiq'

module Edgar
  class Engine < ::Rails::Engine
    isolate_namespace Edgar

    initializer Edgar, after: :load_config_initializers do |app|
      Edgar.load_paths.each do |directory|
        Dir["#{Edgar::Engine.root}/#{directory}/*.rb"].each { |file| require file }
      end
    end
  end
end
