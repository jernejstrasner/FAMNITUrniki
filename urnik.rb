require 'sinatra'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'ri_cal'
require 'open-uri'
require 'json'
require 'tzinfo'

get '/' do
  # Seznam predmetov po programih
  # Zaenkrat samo za RIN
    ids = {
        3 => 'Ra&#x10D;unalni&scaron;tvo in informatika (dodiplomski)',
        1 => 'Matematika (dodiplomski)',
        2 => 'Matematika v ekonomiji in financah (dodiplomski)',
        10 => 'Ra&#x10D;unalni&scaron;tvo in informatika (magistrski)',
        12 => 'Matemati&#x10D;ne znanosti (magistrski)',
        7 => 'Matematika EN (dodiplomski)',
        12 => 'Matemati&#x10D;ne znanosti (magistrski)',
        4 => 'Biodiverziteta',
        6 => 'Bioinformatika (dodiplomski)',
        9 => 'Biopsihologija (dodiplomski)',
        8 => 'Aplikativna kineziologija (dodiplomski)',
        5 => 'Sredozemsko kmetijstvo (dodiplomski)',
        11 => 'Varstvo narave (magistrski)'
    }
  @programi = Array.new
  ids.each do |id, name|
    url = 'http://www.famnit.upr.si/sl/studenti/urniki_wise/lib/courses_helper.php?type=program&program_id=' + id.to_s
    res = open(url).read
    @programi << {'name' => name, 'data' => JSON.parse(res)['result'][2]}
  end  
  @rel_url = uri('predmet/').to_s.sub('http', 'webcal')
  erb :index
end

get '/predmet/:id' do |id|
  urnikURL = "http://www.famnit.upr.si/sl/studenti/urniki_wise/courses.php"

  parameters = {
    'courses_values' => id,
    'show_week' => 0,
  }
  result = Net::HTTP.post_form(URI.parse(urnikURL), parameters)
  
  doc = Nokogiri::HTML(result.body)
  
  predmet = doc.at_css('span.caption').inner_html.strip
  
  cal = RiCal.Calendar do |cal|
    cal.default_tzid = 'Europe/Ljubljana'
    doc.css('table.data tr.data').each do |el|
      cal.event do |event|
        tds = el.css('td')
        event.summary = predmet + " - " + tds[4].inner_html + " - " + tds[5].inner_html
        event.description = tds[6].inner_html
        time = tds[2].inner_html.split('-')
        event.dtstart = Time.parse(tds[1].inner_html + " " + time[0])
        event.dtend = Time.parse(tds[1].inner_html + " " + time[1])
        event.location = tds[3].inner_html
      end
    end
  end
  cal.to_s
end