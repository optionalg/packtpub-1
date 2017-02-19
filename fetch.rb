require 'watir'
require './config.rb'

download_directory = "#{Dir.pwd}/downloads/#{Time.now.strftime('%Y-%m-%d')}"
download_directory.tr!('/', '\\') if Selenium::WebDriver::Platform.windows?

profile = Selenium::WebDriver::Chrome::Profile.new
profile['download.prompt_for_download'] = false
profile['download.default_directory'] = download_directory

b = Watir::Browser.new :chrome, profile: profile
b.goto 'https://www.packtpub.com/packt/offers/free-learning'

menu_icon = b.element id: 'menuIcon'
if menu_icon.visible?
  menu_icon.click
  b.element(xpath: '//*[@id="ppv4"]/div[6]/div[1]/div[1]/div[1]').click
else
  b.element(xpath: '//*[@id="account-bar-login-register"]/a[1]').click
end

b.text_field(id: 'email').set EMAIL
b.text_field(id: 'password').set PASSWORD
b.element(id: 'login-form-submit').button.click
b.element(css: 'input[value="Claim Your Free eBook"]').click
ebook_box = b.element xpath: '//*[@id="product-account-list"]/div[1]'
ebook_box.click
ebook_id = ebook_box.attribute_value 'nid'
ebook_code_id = ebook_box.link(css: '.kindle-link').attribute_value 'nid'

ebook_box.link(href: "/ebook_download/#{ebook_id}/pdf").click
ebook_box.link(href: "/ebook_download/#{ebook_id}/epub").click
ebook_box.link(href: "/ebook_download/#{ebook_id}/mobi").click
ebook_box.link(href: "/code_download/#{ebook_code_id}").click

sleep 3 until Dir["#{download_directory}/**/*.crdownload"].empty?

b.quit