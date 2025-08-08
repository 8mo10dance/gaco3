Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app)
end

Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
Capybara.server = :puma, { Silent: true }
Capybara.server_host = "0.0.0.0"
