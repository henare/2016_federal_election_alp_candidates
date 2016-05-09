require "mechanize"
require "scraperwiki"

agent = Mechanize.new
base_url = "http://www.alp.org.au"
index_page = agent.get("#{base_url}/people/")

people_urls = index_page.search(".member-box").collect do |e|
  base_url + e.at(:a).attr(:href)
end

def extract_url(page, text)
  page.link_with(text: text).uri.to_s if page.link_with(text: text)
end

people_urls.each do |url|
  page = agent.get(url)
  contact_elements = page.at(".contact-box").search("p")
  name = page.at(".page-banner").at("h1").inner_text

  # FIXME: Skipping some pages that are missing info until the parser can handle it
  # FIXME: Richard Marles is also parsing some wrong info
  next if name == "Mark Butler" || name == "Anne McEwen"

  record = {
    name: page.at(".page-banner").at("h1").inner_text,
    position: page.at(".main").at("h2").inner_text,
    # TODO: Tidy up address more
    address: contact_elements.first.inner_html.gsub("<br>", " ").gsub("\n", ""),
    phone: contact_elements[1].inner_text,
    email: contact_elements[2].inner_text,
    website: contact_elements[3].inner_text,
    facebook: extract_url(page, "Facebook"),
    twitter: extract_url(page, "Twitter"),
    instagram: extract_url(page, "Instagram")
  }

  p record
  ScraperWiki.save_sqlite([:name], record)
end
