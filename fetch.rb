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
b.element(css: 'input[value="Claim Your Free eBook"]').click
ebook_box = b.element xpath: '//*[@id="product-account-list"]/div[1]'
ebook_box.click
ebook_id = ebook_box.attribute_value 'nid'
ebook_code_id = ebook_box.link(css: '.kindle-link').attribute_value 'nid'

download_links = [
  "/ebook_download/#{ebook_id}/pdf",
  "/ebook_download/#{ebook_id}/epub",
  "/ebook_download/#{ebook_id}/mobi",
  "/code_download/#{ebook_code_id}"
]

download_links = download_links.map { |l| ebook_box.link href: l }

download_links = download_links.select { |l| l.exist? }

download_links.each { |l| l.click }

sleep 3 until Dir["#{download_directory}/**/*.crdownload"].empty? &&
  Dir["#{download_directory}/**/*"].length == download_links.length

b.close

FileUtils.mv download_directory, TARGET if Dir.exist? TARGET
