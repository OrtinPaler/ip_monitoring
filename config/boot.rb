# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.new

loader.push_dir(File.expand_path('../app/models', __dir__))
loader.push_dir(File.expand_path('../app/services', __dir__))
loader.push_dir(File.expand_path('../app/contracts', __dir__))
loader.push_dir(File.expand_path('../app/workers', __dir__))

loader.inflector = Zeitwerk::GemInflector.new(__FILE__)

loader.ignore(File.expand_path('../config', __dir__))

loader.setup

require_relative 'database'
require_relative 'environment'

