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

def try(n = 5, &f)
  r = nil
  i = 0
  loop do
    sleep 1
    r = f.call
    break r unless r.nil?
  end

  raise "Maximum number of tries (#{n}) exceeded!" unless i < n

  r
end

# Prepare downloads directory
now = Time.now.getlocal('+00:00')
download_directory_basename = now.strftime('%Y-%m-%d')
download_directory = "#{__dir__}/downloads/#{download_directory_basename}"
download_directory.tr!('/', '\\') if Selenium::WebDriver::Platform.windows?
Pathname.new(download_directory).rmtree if Dir.exist? download_directory
profile = Selenium::WebDriver::Firefox::Profile.new
profile['browser.download.folderList'] = 2
profile['browser.download.dir'] = download_directory
profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv,application/pdf,application/epub+zip,application/octet-stream,application/zip'

# Open browser
b = Watir::Browser.new :firefox, profile: profile
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

# Get title from first product
first_product = try do
  b.elements(css: '#product-account-list .product-line:first-child').first
end
first_product_title = first_product.attribute_value 'title'

if free_book_title == first_product_title
  # Download
  first_product.click
  download_links = first_product.elements(css: '.fake-button-icon.download')
  download_links.each(&:click)

  # Wait for downloads to have finished
  sleep 3 until Dir["#{download_directory}/**/*.part"].empty? &&
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

# Possibly create sub target and update target
target = if MONTHLY_SUB_TARGET
  sub_target = Pathname.new(TARGET).join(now.strftime('%Y-%m'))
  sub_target.mkdir if Dir.exist?(TARGET) && !Dir.exist?(sub_target)
  sub_target.to_s
else
  TARGET
end
# Move downloads if TARGET is valid
absolute_target = File.join target, download_directory_basename
FileUtils.mv download_directory, target if Dir.exist?(target) &&
                                           !Dir.exist?(absolute_target)
