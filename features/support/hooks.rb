require 'cucumber'

# quit on first failure
After do |scenario|
  Cucumber.wants_to_quit = true if scenario.failed?
end
