#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'watir'
require "#{__dir__}/config.rb"

def safe_click(e)
  retries ||= 0
  e.click
rescue
  clear_view e.browser
  retry if (retries += 1) < 3
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
download_directory_basename = Time.now.getlocal('+00:00').strftime('%Y-%m-%d')
download_directory = "#{__dir__}/downloads/#{download_directory_basename}"
download_directory.tr!('/', '\\') if Selenium::WebDriver::Platform.windows?
Pathname.new(download_directory).rmtree if Dir.exist? download_directory
profile = Selenium::WebDriver::Chrome::Profile.new
profile['download.prompt_for_download'] = false
profile['download.default_directory'] = download_directory

# Open browser
b = Watir::Browser.new :chrome, profile: profile
b.goto 'https://www.packtpub.com/packt/offers/free-learning'

# Set browser width (to force mobile layout, otherwise login does not working)
max_width = 1000
if b.window.size.width > max_width
  b.window.resize_to(max_width, b.window.size.height)
end
if b.window.size.width > max_width
  puts 'Unable to set size automatically.'
  while b.window.size.width > max_width
    puts "Window must not be wider than #{max_width}. Please shrink the" \
      ' browser window by hand.'
    puts 'Press enter to re-check.'
    gets
  end
end

# Login (clicking the claim button, opens the fields, when not logged in)
safe_click b.element(css: 'input[value="Claim Your Free eBook"]')
b.text_field(id: 'email').set EMAIL
b.text_field(id: 'password').set PASSWORD
b.element(id: 'login-form-submit').button.click

# Claim
free_book_title = b.element(css: '.dotd-main-book-summary > .dotd-title > h2').text + ' [eBook]'
safe_click b.element(css: 'input[value="Claim Your Free eBook"]')
captcha_frame = b.element(css: 'iframe[title="recaptcha challenge"]')
if captcha_frame.exist?
  puts 'Captcha detected. Please solve first and then press enter'
  gets
end

# Get title from first product
first_product = b.elements(css: '#product-account-list .product-line').first
first_product_title = first_product.attribute_value 'title'

if free_book_title == first_product_title
  # Download
  first_product.click
  download_links = first_product.elements(css: '.fake-button-icon.download')
  download_links.each(&:click)

  # Wait for downloads to have finished
  sleep 3 until Dir["#{download_directory}/**/*.crdownload"].empty? &&
                Dir["#{download_directory}/**/*"].length == download_links.length
else
  # Find matching product and get data
  matching_product = b.elements(css: '#product-account-list .product-line[title="' + free_book_title + '"]').first
  matching_product.click
  matching_product_date = matching_product.elements(css: '.product-info .product-reference-table > tbody > tr:nth-child(2) > td:nth-child(3)').first.text
  matching_product_date = Date.parse(matching_product_date).strftime('%Y-%m-%d')

  # Create empty text file as reference
  Pathname.new(download_directory).mkdir
  File.write(Pathname.new(download_directory).join(matching_product_date + '.txt'), '')
end

# Close browser
b.close

# Move downloads if TARGET is valid
absolute_target = File.join TARGET, download_directory_basename
FileUtils.mv download_directory, TARGET if Dir.exist?(TARGET) &&
                                           !Dir.exist?(absolute_target)
