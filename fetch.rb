#!/usr/bin/env ruby

require 'pathname'
require 'watir'
require "#{__dir__}/config.rb"

def safe_click(e)
  begin
    retries ||= 0
    e.click
  rescue
    clear_view e.browser
    retry if (retries += 1) < 3
  end
end

def clear_view(b)
  while b.element(css: 'a.g-close').exist?
    b.element(css: 'a.g-close').click
    sleep 1
  end
  while b.element(css: 'w-div').exist?
    b.elements(css: 'w-div > span').last.click
    sleep 1
  end
end

# Prepare downloads directory
download_directory = "#{__dir__}/downloads/#{Time.now.getlocal('+00:00').strftime('%Y-%m-%d')}"
download_directory.tr!('/', '\\') if Selenium::WebDriver::Platform.windows?
Pathname.new(download_directory).rmtree if Dir.exist? download_directory
profile = Selenium::WebDriver::Chrome::Profile.new
profile['download.prompt_for_download'] = false
profile['download.default_directory'] = download_directory

# Open browser
b = Watir::Browser.new :chrome, profile: profile
b.goto 'https://www.packtpub.com/packt/offers/free-learning'

# Set browser width (to force mobile layout, otherwise login does not working)
max_width = 1040
if b.window.size.width > max_width
  b.window.size.width = max_width
end
if b.window.size.width > max_width
  puts "Unable to set size automatically."
  while b.window.size.width > max_width
    puts "Window must not be wider than #{max_width}. Please shrink the browser window by hand."
    puts "Press enter to re-check."
    gets
  end
end

# Login (clicking the claim button, opens the fields, when not logged in)
safe_click b.element(css: 'input[value="Claim Your Free eBook"]')
b.text_field(id: 'email').set EMAIL
b.text_field(id: 'password').set PASSWORD
b.element(id: 'login-form-submit').button.click

# Claim
safe_click b.element(css: 'input[value="Claim Your Free eBook"]')

# Download
first_product = b.elements(css: '#product-account-list .product-line').first
first_product.click
download_links = first_product.elements(css: '.fake-button-icon.download')
download_links.each { |l| l.click }

# Wait for downloads having finished
sleep 3 until Dir["#{download_directory}/**/*.crdownload"].empty? &&
  Dir["#{download_directory}/**/*"].length == download_links.length

# Close browser
b.close

# Move downloads
FileUtils.mv download_directory, TARGET if Dir.exist? TARGET
